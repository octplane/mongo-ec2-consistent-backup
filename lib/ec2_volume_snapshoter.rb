require 'fog'
require 'open-uri'

# This class is responsible of the snapshoting of given disks to EC2
# EC2 related permissions in IAM
# * ec2:CreateSnapshot
# * ec2:DescribeVolumes
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

class EC2VolumeSnapshoter
  NAME_PREFIX='Volume Snapshot'

  # Kind of snapshot and their expiration in days
  KINDS = { 'test' => 1,
    'snapshot' => 0,
    'daily' => 7,
    'weekly' => 31,
    'monthly' => 300,
    'yearly' => 0}

  attr_reader :instance_id
  # Need access_key_id, secret_access_key and instance_id
  # If not provided, attempt to fetch current instance_id
  def initialize(aki, sak, instance_id = open("http://169.254.169.254/latest/meta-data/instance-id").read)

    @instance_id = instance_id

    @compute = Fog::Compute.new({:provider => 'AWS', :aws_access_key_id => aki, :aws_secret_access_key => sak})
  end
  # Snapshots the list of devices 
  # devices is an array of device attached to the instance (/dev/foo)
  # name if the name of the snapshot
  def snapshot_devices(devices, name = "#{instance_id}", kind = "test", limit = KINDS[kind])
    log "Snapshot of kind #{kind}, limit set to #{limit} (0 means never purge)"
    ts = DateTime.now.to_s
    name = "#{NAME_PREFIX}:" + name
    volumes = {}
    devices.each do |device|
      volumes[device] = find_volume_for_device(device)
    end
    volumes.each do |device, volume|
      log "Creating volume snapshot for #{device} on instance #{instance_id}"
      snapshot = volume.snapshots.new
      snapshot.description = name+" #{device}"
      snapshot.save
      snapshot.reload

      @compute.tags.create(:resource_id => snapshot.id, :key =>"application", :value => NAME_PREFIX)
      @compute.tags.create(:resource_id => snapshot.id, :key =>"device", :value => device)
      @compute.tags.create(:resource_id => snapshot.id, :key =>"instance_id", :value =>instance_id)
      @compute.tags.create(:resource_id => snapshot.id, :key =>"date", :value => ts)
      @compute.tags.create(:resource_id => snapshot.id, :key =>"kind", :value => kind)

    end

    if limit != 0
      # populate data structure with updated information
      snapshots = list_snapshots(devices, kind)
      nsnaps = snapshots.keys.length
      if nsnaps-limit > 0
        dates = snapshots.keys.sort
        puts dates.inspect
        extra_snapshots = dates[0..-limit]
        remaining_snapshots = dates[-limit..-1]
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
  require 'pp'
  def list_snapshots(devices, kind)
    volume_map = []
    snapshots = {}

    tags = @compute.tags.all(:key => 'instance_id', :value => instance_id)
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
    opt :access_key_id, "Access Key Id for AWS", :type => :string, :required => true
    opt :secret_access_key, "Secret Access Key for AWS", :type => :string, :required => true
    opt :instance_id, "Instance identifier", :type => :string, :required => true
    opt :find_volume_for, "Show information for device path (mount point)", :type => :string
    opt :snapshot, "Snapshot device path (mount point)", :type => :string
    opt :snapshot_type, "Kind of snapshot (any of #{EC2VolumeSnapshoter::KINDS.keys.join(", ")})", :default => 'test'

  end

  evs = EC2VolumeSnapshoter.new(opts[:access_key_id], opts[:secret_access_key], opts[:instance_id])
  if opts[:find_volume_for]
    pp evs.find_volume_for_device(opts[:find_volume_for])
  end
  if opts[:snapshot]
    evs.snapshot_devices([opts[:snapshot]])
  end
end