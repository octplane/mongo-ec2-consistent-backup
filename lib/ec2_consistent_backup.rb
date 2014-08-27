require 'rubygems'
require 'mongo'
$: << File.join(File.dirname(__FILE__), "../lib")
require 'ec2_helper'

=begin
- check S3 credentials
- check disk location of data
- check this is on a remotely mounted disk (or md drive)
- http://www.mongodb.org/display/DOCS/getCmdLineOpts+command
=end

=begin
/proc/mdstat content:

Personalities : [raid0] 
md0 : active raid0 sdo[3] sdn[2] sdm[1] sdl[0]
      838859776 blocks 256k chunks
      
unused devices: <none>
=end

class NoSuchSetException < Exception; end

# Parse the existing RAID sets by reading /prod/mdstat
# Cheap alternative to using FFI to interface with libdm
class MDInspector
  MDFILE = "/proc/mdstat"
  PERSONALITIES = "Personalities :"
  attr_reader :has_md, :personalities
  attr_reader :drives

  def initialize(mdfile = MDFILE)
    @has_md = false
    if File.exists?(mdfile)
      stat_data = File.open(mdfile).read.split(/\n/)
      personalities_line = stat_data.grep(/#{PERSONALITIES}/)
      if personalities_line =~ /#{PERSONALITIES}(.+)/
        @personalities =  $1
      else
        @has_md = false
      end
      @set_metadata = {}
      stat_data.grep(/^md[0-9]+ : /).each do |md_info|
        if md_info =~ /^md([0-9]+) : active ([^ ]+) (.*)$/
          set_name = "md#{$1}"
          personality = $2
          drives = $3.split(/ /).map{ |i| "/dev/"+i.gsub(/\[[0-9]+\]/,'') }.to_a
          @set_metadata[set_name] =  { :set_name=> set_name, :personality => personality, 
            :drives => drives}
        end
      end
      @has_md = true if @set_metadata.keys.length > 0
    end
  end

  # Returns the information about the MD set @name
  def set(name)
    # Handle "/dev/foobar" instead of "foobar"
    if name =~ /\/dev\/(.*)$/
      name = $1
    end
    return @set_metadata[name] if @set_metadata.has_key?(name)
    raise NoSuchSetException.new(name)
  end
end

class NotMountedException < Exception; end

class MountInspector
  def initialize(file = '/etc/mtab')
    @dev_to_fs = {}
    @fs_to_dev = {}
    File.open(file).read.split(/\n/).map {|line| line.split(/ /)[0..1]}.each do |m|
      @dev_to_fs[m[0]] = m[1] if m[0] != "none"
      @fs_to_dev[m[1]] = m[0] if m[1] != "none"
    end
  end

  def where_is_mounted(device)
    return @dev_to_fs[device] if @dev_to_fs.has_key?(device) 
    raise NotMountedException.new(device)
  end

  def which_device(folder)
    # Level 0 optimisation+ Handle "/" folder
    return @fs_to_dev[folder] if @fs_to_dev.has_key?(folder)

    components = folder.split(/\//)
    components.size.downto(0).each do |sz|
      current_folder = components[0..sz-1].join("/")
      current_folder = "/" if current_folder == ""
      return @fs_to_dev[current_folder] if @fs_to_dev.has_key?(current_folder)
    end
    raise NotMountedException.new(folder)
  end
end

module MongoHelper
  class DataLocker
    attr_reader :path

    def initialize(port = 27017, host = 'localhost')
      @m = Mongo::Connection.new(host, port)
      args =  @m['admin'].command({'getCmdLineOpts' => 1 })['argv']
      p = args.index('--dbpath')
      @path = args[p+1]
      @path = File.readlink(@path) if File.symlink?(@path)

    end

    def lock
      return if locked?
      @m.lock!
      while !locked? do
        sleep(1)
      end
      raise "Not locked as asked" if !locked?
    end

    def locked?
      @m.locked?
    end

    def unlock
      return if !locked?
      raise "Already unlocked" if !locked?
      @m.unlock!
      while locked? do
        sleep(1)
      end
    end
  end
end

def log s
  $stderr.puts "[#{Time.now}]: #{s}"
end

if __FILE__ == $0
  require 'trollop'
  opts = Trollop::options do
    opt :port, "Mongo port to connect to", :default => 27017
  end

  # First connect to mongo and find the dbpath
  port = opts[:port]
  m = MongoHelper::DataLocker.new(port)
  data_location = m.path
  log "Mongo at #{port} has its data in #{data_location}."
  

  mount_inspector = MountInspector.new
  raid_set = mount_inspector.which_device(data_location)
  log "This path is on the device #{raid_set}."

  begin 
    raid_sets = MDInspector.new
    drives = raid_sets.set(raid_set)[:drives]

    log "This device is the MD device built with #{drives.inspect}."

  rescue NoSuchSetException => e
    log "Device #{raid_set} is not a MD device, bailing out"
    raise e
  end
end
