# Mongo consistent backup over RAID EBS disks on EC2 instance

Suite of tools to backup and manage snapshots of MongoDB data set to EC2 Snapshots.

## Consistent Backup: ec2-consistent-backup.rb

### Usage

This ruby script implements a snapshot of a mongo database runing on an EC2 instance using RAID EBS disks. Run it from the machine on which the mongo you wish
to snapshot the data is running.

```shell
./ec2-consistent-backup -p 27017 -a ZARERTZETZTZ -s zjezropfejf
```

### Tool description

* connect to mongo at port provided, retrieves dbpath
* find what mount this dbpath corresponds to
* use /proc/mdstat to find out which drive are corresponding to the dbpath mount disk
* lock the mongo
* use the EC2 api to snapshot all the disks
* unlock the mongo

## Lock and Snapshot: lock_and_snapshot.rb

### Usage

Snapshot a list of devices on a given instance on ec2. Requires network access in order to lock and unlock Mongo

```shell
./lock_and_snapshot.rb -a DEZFEZRG -s de234F44 --hostname server01 --devices /dev/sdl,/dev/slm --type daily --limit 4
```

* --port, -p <i>:   Mongo port to connect to (default: 27017)
* --access-key-id, -a <s>:   Access Key Id for AWS
* --secret-access-key, -s <s>:   Secret Access Key for AWS
* --devices, -d <s>:   Devices to snapshot, comma separated
* --hostname, -h <s>:   Hostname to look for. Should resolve to a local EC2 Ip
* --type, -t <s>:   Snapshot type, to choose among snapshot,weekly,monthly,daily,yearly (default: snapshot)
* --limit, -l <i>:   Cleanup old snapshots to keep only limit snapshots. Default values are stored in EC2VolumeSnapshoter::KIND
* --help, -e:   Show this message

### Tool Description

* Find instance id by resolving the hostname provided in the CLI and scanning the instances in EC2
* Lock Mongo by connecting via the hostname:port provided in the parameters
* Snapshot the disks, delete old backups
* Unlock Mongo

# API

Internal API documentation is at: http://rubydoc.info/github/octplane/mongo-ec2-consistent-backup/master/frames
