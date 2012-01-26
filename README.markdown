# Mongo consistent backup over RAID EBS disks on EC2 instance

Suite of tools to backup and manage snapshots of MongoDB data set to EC2 Snapshots.

## Lock and Snapshot: lock_and_snapshot.rb

### Usage

Snapshot a list of devices on a given instance on ec2. Requires network access in order to lock and unlock Mongo

```shell
./lock_and_snapshot.rb -a ACCESS_KEY_ID -s SECRET_ACCESS_KEY --hostname server01 --devices /dev/sdl,/dev/slm --type daily --limit 4
```

* --port, -p <i>:   Mongo port to connect to (default: 27017)
* --access-key-id, -a <s>:   Access Key Id for AWS
* --secret-access-key, -s <s>:   Secret Access Key for AWS
* --devices, -d <s>:   Devices to snapshot, comma separated
* --hostname, -h <s>:   Hostname to look for. Should resolve to a local EC2 Ip
* --type, -t <s>:   Snapshot type, to choose among snapshot,weekly,monthly,daily,yearly (default: snapshot)
* --limit, -l <i>:   Cleanup old snapshots to keep only limit snapshots. Default values are stored in EC2VolumeSnapshoter::KIND
* --region:   Region hosting the instances
* --help, -e:   Show this message

### Usage in chef environment

In order to run the command from a remote server (the Chef server or any administrative node of your grid), you need to be able to know the lists of the devices you wish to snapshot.

By using the ohai-raid plugin (https://github.com/octplane/ohai-raid), Chef clients can fill part of their Chef registry with information about the software managed RAID arrays running.
This information can be fetched out for use at a later point via the knife script provided in the ohai-raid package:

```
knife exec scripts/show_raid_devices server01.fqdn.com /dev/md0
/dev/sdl,/dev/sdm,/dev/sdn,/dev/sdo
```

You can combine the two tools to automate daily backup of you MongoDB server:

```
./lock_and_snapshot.rb -a ACCESS_KEY_ID -s SECRET_ACCESS_KEY --hostname server01 --devices $(knife exec /path/to/scripts/show_raid_devices server01.fqdn.com /dev/md0) --type daily
```

### Tool Description

* Find instance id by resolving the hostname provided in the CLI and scanning the instances in EC2
* Lock Mongo by connecting via the hostname:port provided in the parameters
* Snapshot the disks, delete old backups
* Unlock Mongo

## MD inspection: ec2-consistent-backup.rb

### Usage

This script demonstrates the way it analyses Mongo DB Data path to extract the MD device and components associated

```shell
./ec2-consistent-backup -p 27017 
```

### Tool description

* connect to mongo at port provided, retrieves dbpath
* find what mount this dbpath corresponds to
* use /proc/mdstat to find out which drive are corresponding to the dbpath mount disk

# API

Internal API documentation is at: http://rubydoc.info/github/octplane/mongo-ec2-consistent-backup/master/frames
