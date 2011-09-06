# Mongo consistent backup over RAID EBS disks on and EC2 instance

This ruby script implements a snapshot of a mongo database runing on an EC2 instance using RAID EBS disks.

```shell
./ec2-consistent-backup -p 27017 -a ZARERTZETZTZ -s zjezropfejf
```

# Tool description

* connect to mongo at port provided, retrieves dbpath
* find what mount this dbpath corresponds to
* use /proc/mdstat to find out which drive are corresponding to the dbpath mount disk
* lock the mongo
* use the EC2 api to snapshot all the disks
* unlock the mongo

# API

Internal API documentation is at: http://rubydoc.info/github/octplane/mongo-ec2-consistent-backup/master/frames
