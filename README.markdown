# Mongo consistent backup over RAID EBS disks on EC2 instance

Suite of tools to backup and manage snapshots of MongoDB data set to EC2 Snapshots.

## Lock and Snapshot: mongo_lock_and_snapshot.rb

### Usage

Snapshot a list of devices on a given instance on ec2.

```shell
/mnt/lib/mongo-ec2-consistent-backup/bin# infra-ruby lock_and_snapshot -p /ebs/lvms/lvol0/ -a ACCESS_KEY -s SECRET_KEY -d /dev/sdg,/dev/sdh,/dev/sdi,/dev/sdj,/dev/sdk,/dev/sdl,/dev/sdm,/dev/sdn
```

* --path, -p :   Data path to freeze
* --access-key-id, -a :   Access Key Id for AWS
* --secret-access-key, -s :   Secret Access Key for AWS
* --devices, -d :   Devices to snapshot, comma separated
* --type, -t :   Snapshot type, to choose among test,snapshot,daily,weekly,monthly,yearly (default: snapshot)
* --help, -h:   Show this message

It freeze the path using ```xfs_freeze```and create a snapshot for all the disks passed in the command line. To make this work without too much trouble with a mongo that is in a replica set, you can shut down the replica before running the command. You can also use mongo fsync and lock but this will probably make your cluster a bit nervous about that. Shutting down ensure no mongos will try to use the frozen mongo.

### Usage with IAM

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
