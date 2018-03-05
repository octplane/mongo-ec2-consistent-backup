require 'fog'
require 'pp'
$: << File.join(File.dirname(__FILE__), "../lib")
require 'ec2_helper'

# This class is responsible of the snapshotting of given disks to EC2
# EC2 related permissions in IAM
# Sid": "Stmt1344254048404",
#      "Action": [
#        "ec2:CreateSnapshot",
#        "ec2:DeleteSnapshot",
#        "ec2:DescribeSnapshots",
#        "ec2:CreateTags",
#        "ec2:DescribeTags",
#        "ec2:DescribeVolumes"
#      ],
#      "Effect": "Allow",
#      "Resource": [
#        "*"
#      ]
#

class NoSuchVolumeException < Exception
  def initialize(instance, volume, details)
    @instance, @volume, @details = instance, volume, details
  end

  def to_s
    "Unable to locate volume \"#{@volume}\" on #{@instance}\nKnow volumes for this instance are:\n#{@details.inspect}"
  end
end

def log s
 $stderr.puts "[#{Time.now}]: #{s}"
end

class EC2VolumeSnapshotter
  NAME_PREFIX='Volume Snapshot' # TODO: make this not a constant

  # Kind of snapshot and their expiration in days
  KINDS = { 'test' => 1,
    'snapshot' => 0,
    'hourly' => 4,
    'daily' => 3,
    'weekly' => 1,
    'monthly' => 300,
    'yearly' => 0}

  attr_reader :instance_id

  # If not provided, attempt to fetch current instance_id
  def initialize(aki, sak, instance_id = nil)
    @ec2 = EC2Helper.new(aki, sak)
    @compute = Fog::Compute.new(@ec2.connection)
    @instance_id = instance_id.nil? ? @ec2.instance_id : instance_id
  end

  # Snapshots the list of devices 
  # devices is an array of device attached to the instance (/dev/foo)
  # name if the name of the snapshot
  def snapshot_devices(devices, name = "#{@instance_id}", kind = "test", limit = KINDS[kind], comments = {}, addusers = [])

    log "Snapshot of kind #{kind}, limit set to #{limit} (0 means never purge)"
    ts = DateTime.now.to_s
    t = Time.new
    backup_id = sprintf("%4d%02d%02d.%02d", t.year, t.month, t.day, t.hour)
    name = "#{NAME_PREFIX}:" + name
    volumes = {}
    devices.each do |device|
      volumes[device] = find_volume_for_device(device)
    end
    sn = []
    volumes.each do |device, volume|
      log "Creating volume snapshot for #{device} on instance #{@instance_id}"
      snapshot = volume.snapshots.new
      snapshot.description = name+" #{device}"
      snapshot.save
      sn << snapshot
      snapshot.reload

      @compute.tags.create(:resource_id => snapshot.id, :key =>"application", :value => NAME_PREFIX)
      @compute.tags.create(:resource_id => snapshot.id, :key =>"device", :value => device)
      @compute.tags.create(:resource_id => snapshot.id, :key =>"instance_id", :value =>@instance_id)
      @compute.tags.create(:resource_id => snapshot.id, :key =>"date", :value => ts)
      @compute.tags.create(:resource_id => snapshot.id, :key =>"kind", :value => kind)
      @compute.tags.create(:resource_id => snapshot.id, :key =>"backup_id", :value => backup_id)
      if comments.is_a? Hash
        comments.each do |k, v = nil|
          @compute.tags.create(:resource_id => snapshot.id, :key => k, :value => v)
        end
      else
        @compute.tags.create(:resource_id => snapshot.id, :key =>'comments', value => comments)
      end
    end
    log "Waiting for snapshots to complete."
    sn.each do |s|
      begin
        sleep(3)
        s.reload
      end while s.state == 'nil' || s.state == 'pending'
      unless addusers.empty?
        @compute.modify_snapshot_attribute(s.id, { 'Add.UserId' => addusers })
      end
    end

    if limit != 0
      # populate data structure with updated information
      snapshots = list_snapshots(devices, kind)
      nsnaps = snapshots.keys.length
      if nsnaps-limit > 0
        dates = snapshots.keys.sort
        puts dates.inspect
        extra_snapshots = dates[0..-limit]
        extra_snapshots.each do |date|
          snapshots[date].each do |snap|
            log "Destroying #{snap.description} #{snap.id}"
            snap.destroy
         end
        end
      end
    end
  end

  # List snapshots for a set of device and a given kind
  def list_snapshots(devices, kind)
    snapshots = {}

    tags = @compute.tags.all(:key => 'instance_id', :value => @instance_id)
    tags.each do |tag|
      snap = @compute.snapshots.get(tag.resource_id)
      t =  snap.tags

      if devices.include?(t['device']) && 
        instance_id == t['instance_id'] &&
        NAME_PREFIX == t['application'] &&
        kind == t['kind']
        snapshots[t['date']] ||= []
        snapshots[t['date']] << snap
      end
    end

    # take out incomplete backups
    snapshots.delete_if{ |date, snaps| snaps.length != devices.length }
    snapshots
  end

  def find_volume_for_device(device)
    my = []
    @compute.volumes.all().each do |volume|
      if volume.server_id == @instance_id
        my << volume
        if volume.device == device
          return volume
        end
      end
    end
    raise NoSuchVolumeException.new(@instance_id, device, my)
  end
end

if __FILE__ == $0
  require 'trollop'
  require 'pp'

  opts = Trollop::options do
    opt :access_key_id, "Access Key Id for AWS", :type => :string
    opt :secret_access_key, "Secret Access Key for AWS", :type => :string
    opt :instance_id, "Instance identifier", :type => :string
    opt :find_volume_for, "Show information for device path (mount point)", :type => :string
    opt :snapshot, "Snapshot device path (mount point)", :type => :string
    opt :snapshot_type, "Kind of snapshot (any of #{EC2VolumeSnapshotter::KINDS.keys.join(", ")})", :default => 'test'
    opt :comment, "Comment to add to tags", :type => :string
    opt :addusers, "Share with account ID", :type => :string
  end

  evs = EC2VolumeSnapshotter.new(opts[:access_key_id], opts[:secret_access_key], opts[:instance_id])
  if opts[:find_volume_for]
    pp evs.find_volume_for_device(opts[:find_volume_for])
  end
  if opts[:snapshot]
    evs.snapshot_devices([opts[:snapshot]])
  end
end
