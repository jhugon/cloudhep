#!/usr/bin/python

## Requires boto env var authentication
## Passes same authentication vars on to ec2 nodes

import os
import boto
import argparse
from boto.s3.connection import Location
from boto.ec2.blockdevicemapping import BlockDeviceType
from boto.ec2.blockdevicemapping import BlockDeviceMapping

parser = argparse.ArgumentParser(description="Creates Test Node")
parser.add_argument("jobName", help="The job name; ec2 instances will have this name")
parser.add_argument("-t","--test", help="Test mode: print bootstrap script to screen",action='store_true',default=False)
parser.add_argument("-i","--instanceType", help="EC2 instance type, default: c1.medium",choices=["t1.micro","m1.small","m1.medium","m1.large","m1.xlarge","c1.medium","c1.xlarge"],default="c1.medium")

args = parser.parse_args()

#print "Testing {0}".format(args.test)
TESTING=args.test
outputName = args.jobName

#Job

emailAddress = ""

#ec2
amiString = "ami-a29943cb" # Ubuntu Precise amd64 ebs us-east-1
placement = "us-east-1a"
terminateOnFinish = False

## Setup appropriate block device map for instance storage

instanceStoreDeviceNums ={
"t1.micro":0,
"m1.small":1,
"m1.medium":1,
"m1.large":2,
"m1.xlarge":2,
"c1.medium":2,
"c1.xlarge":8
}

blockDeviceMap = BlockDeviceMapping()
letters = "bcdefghijklmnopqrstuvwxyz"
for i in range(instanceStoreDeviceNums[args.instanceType]):
  devName = "/dev/sd{}".format(letters[i])
  tmp = BlockDeviceType()
  tmp.ephemeral_name = 'ephemeral{}'.format(i)
  blockDeviceMap[devName] = tmp

workDir = "/data1/work"

dataDir = "/data1"
if instanceStoreDeviceNums[args.instanceType] > 1:
  dataDir = "/data2"

nProcNums ={
"t1.micro":1,
"m1.small":1,
"m1.medium":1,
"m1.large":2,
"m1.xlarge":4,
"c1.medium":1,
"c1.xlarge":8
}
processesPerNode = nProcNums[args.instanceType]
processesToRun = processesPerNode

####################################

###
###  Main loop over nInstances
###

bootStrapFile = open("bootStrapScriptTestNode.sh")
bootStrapScript = bootStrapFile.read()
bootStrapScript = bootStrapScript.format(
    numVolumes=instanceStoreDeviceNums[args.instanceType],
    workDir=workDir,
    outputName=outputName
    )
bootStrapFile.close()

if TESTING:
  print(bootStrapScript)
  print(makeHtmlString(processesPerNode))
else:
  #####################
  #### EC2 ############
  #####################
  
  ############################
  
  ec2 = boto.connect_ec2()
  
  ec2Reservation = ec2.run_instances(
      min_count=1,
      max_count=1,
      image_id = amiString,
      instance_type=args.instanceType,
      key_name = "key2",
      user_data = bootStrapScript,
      block_device_map = blockDeviceMap,
      instance_initiated_shutdown_behavior='stop'
      )
  
  ec2InstanceIdList = []
  for i in ec2Reservation.instances:
    print "Instance ID: {0}, type: {1}".format(i.id,args.instanceType)
    ec2InstanceIdList.append(i.id)
  ec2.create_tags(ec2InstanceIdList,{"Name":outputName})
