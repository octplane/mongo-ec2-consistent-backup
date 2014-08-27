# Mongo consistent backup over LVM disks on EC2 instance

Suite of tools to backup and manage snapshots of MongoDB data set to EC2 Snapshots.

## Lock and Snapshot: mongo_lock_and_snapshot.rb

### Usage

#### Snapshot a list of devices on a given instance on ec2.

```shell
mongo_lock_and_snapshot -t daily -p /ebs/lvms/lvol0/ -a $AWS_ACCESS_KEY -s $AWS_SECRET_ACCESS_KEY -d /dev/sdg,/dev/sdh,/dev/sdi,/dev/sdj,/dev/sdk,/dev/sdl,/dev/sdm,/dev/sdn
```

It freeze the path using ```xfs_freeze```and create a snapshot for all the disks passed in the command line. To make this work without too much trouble with a mongo that is in a replica set, you can shut down the replica before running the command. You can also use mongo fsync and lock but this will probably make your cluster a bit nervous about that. Shutting down ensure no mongos will try to use the frozen mongo.

#### Restore snapshots 

```shell
ec2_snapshot_restorer -a ACCESS_KEY  -s SECRET_KEY -h source_server_name -r dest_server_instance_id_or_SELF -d LATEST -f /dev/sdj -t daily
```

* Restores the ```daily``` snapshots from date ```LATEST``` that have been made on ```source_server_name``` on instance ```dest_server_instance_id_or_SELF``` on devices ```/dev/sdj``` and following.

#### Destroy and remove volumes

Ensure the volumes are not busy (for example if this is a LVM LV):

```shell
umount /ebs/lvms/vol0/
lvremove -f /dev/vol0/lvol0
vgremove vol0
pvremove /dev/sd{j,k,l,m,n,o,p,q}
```

Once this is done, you can disconnect and destroy the volumes:

```shell
ec2_snapshot_restorer -a $AWS_ACCESS_KEY -s $AWS_SECRET_ACCESS_KEY -h source_server_name -r dest_server_instance_id_or_SELF -d LATEST -f /dev/sdj -c destroy
```

This will force detach and destroy all the volumes previously connected for the corresponding snapshot.

### Usage with IAM

Note that the -a and -s (access key and secret key) flags are no longer required.
If you have set up an IAM instance role for your instance, the backup and restore commands will retrieve temporary AWS credentials from the Instance Metadata Service.

If you use IAM for your authentication in EC2, here is a probably up to date list of the permissions you need to grant:

```
  "ec2:CreateSnapshot",
  "ec2:DeleteSnapshot",
  "ec2:DescribeSnapshots",
  "ec2:CreateTags",
  "ec2:DescribeTags",
  "ec2:DescribeVolumes",
  "ec2:DescribeInstances",
  "ec2:AttachVolume",
  "ec2:CreateVolume"
```
Internal API documentation is at: http://rubydoc.info/github/octplane/mongo-ec2-consistent-backup/master/frames
