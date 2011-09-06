# Mongo consistent backup over RAID EBS disks on EC2 instance


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

```shell
./lock_and_snapshot.rb -a DEZFEZRG -s de234F44 --hostname server01--devices /dev/sdl,/dev/slm
```

### Tool Description

* Dind instance id by resolving the hostname provided in the CLI and scanning the instances in EC2
* Lock Mongo by connecting via the hostname:port provided in the parameters
* Snapshot the disks
* Unlock Mongo

# API

Internal API documentation is at: http://rubydoc.info/github/octplane/mongo-ec2-consistent-backup/master/frames
