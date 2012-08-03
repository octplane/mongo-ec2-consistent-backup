require 'fog'
require 'open-uri'


# 
class SnapshotRestorer
  def initialize(aki, sak, snap_ids)
    @compute = Fog::Compute.new({:provider => 'AWS', :aws_access_key_id => aki, :aws_secret_access_key => sak})
    @snaps = snap_ids
    @volumes = []
  end
  def restore()
    @snaps.each do | resource_id |
      snap = @compute.snapshots.get(resource_id)
      # Snap have the following tags
      # application
      # device
      # instance_id
      # date
      # kind

      t =  snap.tags
      volume = @compute.volumes.new :snapshot_id => snap.id, :size => snap.volume_size, :availability_zone => 'us-east-1c'
      @compute.tags.create(:resource_id => volume.id, :key =>"application", :value => NAME_PREFIX)
      @compute.tags.create(:resource_id => volume.id, :key =>"device", :value => device)
      @compute.tags.create(:resource_id => volume.id, :key =>"date", :value => ts)
      @compute.tags.create(:resource_id => volume.id, :key =>"kind", :value => kind)
      volume.save
      @volumes << volume
    end
  end
  def connect(instance_id = open("http://169.254.169.254/latest/meta-data/instance-id").read)
  end
end