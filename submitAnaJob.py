#!/usr/bin/python

## Requires boto env var authentication
## Passes same authentication vars on to ec2 nodes

import os
import sys
import boto
import argparse
from boto.s3.connection import Location
from boto.ec2.blockdevicemapping import BlockDeviceType
from boto.ec2.blockdevicemapping import BlockDeviceMapping

parser = argparse.ArgumentParser(description="Submits Analysis Jobs to the Cloud.  Uses an analysis package specified by 'analyzerName'.  This package must contain a run.sh script that will build itself and run the analysis, given an s3 bucket, output folder name, and input folder name(s) as arguments.")
parser.add_argument("jobName", help="The job name; ec2 instances will have this name, and the s3 ouput directory will have this name")
parser.add_argument("analyzerName", help="URL for the analyzer package to be used.  If URL begins with 'lp:' then bzr will fetch it, otherwise it is assumed to be an archive at a web-address, and wget/tar will be used")
parser.add_argument('datasets', nargs="+",help='Dataset Names to analyze, they must be folders in the root of the same bucket that this job is configured for')

parser.add_argument("-t","--test", help="Test mode: print bootstrap script to screen",action='store_true',default=False)
parser.add_argument("-d","--dontTerminate", help="Don't Terminate ec2 instance when generation finishes; useful for testing",action='store_true',default=False)
parser.add_argument("-i","--instanceType", help="EC2 instance type, default: m3.medium",choices=["m3.medium","c3.large","c3.xlarge"],default="m3.medium")
parser.add_argument("-n","--numberInstances", help="int, number of EC2 instances to launch, default: 1",default=1, type=int)
parser.add_argument("--spot",help="Request EC2 Spot instances instead of on-demand ones for reduced cost.  The max price is in the script",action='store_true', default=False)

args = parser.parse_args()

#print "Testing {0}".format(args.test)
TESTING=args.test
outputName = args.jobName

#Job

emailAddress = ""

#ec2
amiString = "ami-7449fc1c" # Ubuntu Trusty 14.04 LTS 64-bit Instance Store us-east-1
placement = "us-east-1a"
terminateOnFinish = not args.dontTerminate

# for Ubuntu ...
packageURL = "null"
packageName = "null"

spotInstanceMaxPrices ={
"m3.medium":0.015,
"c3.large":0.025,
"c3.xlarge":0.050,
}
spotInstanceMaxPrice = spotInstanceMaxPrices[args.instanceType]

#s3
bucketName = "cloud-hep-testing-1"
location=Location.DEFAULT # DEFAULT for usEast, EU for eu
acl = "public-read" #public-read, private, public-read-write, authenticated-read
useReducedRedundancy = True

## Setup appropriate block device map for instance storage

instanceStoreDeviceNums ={
"m3.medium":1,
"c3.large":2,
"c3.xlarge":2,
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
"m3.medium":1,
"c3.large":2,
"c3.xlarge":4,
}
processesPerNode = nProcNums[args.instanceType]
processesToRun = processesPerNode

terminateOnFinishChar = ""
if not terminateOnFinish:
  terminateOnFinishChar = "#"

if args.dontTerminate:
  print("Instance will not terminate on job completion")

####################################
###
###  Main loop over nInstances
###
for iInstance in range(len(args.datasets)):

  inputNamesString=""
  inputNamesString += args.datasets[iInstance] + " "

  bootStrapFile = open("bootStrapScriptAna.sh")
  bootStrapScript = bootStrapFile.read()
  bootStrapScript = bootStrapScript.format(
      aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
      aws_secret_key=os.environ["AWS_SECRET_ACCESS_KEY"],
      bucketName=bucketName,
      location=location,
      processesPerNode=processesPerNode,
      instanceNumber=iInstance,
      numVolumes=instanceStoreDeviceNums[args.instanceType],
      outputName=outputName,
      acl=acl,
      dataDir=dataDir,
      workDir=workDir,
      packageURL=packageURL,
      packageName=packageName,
      emailAddress=emailAddress,
      terminateOnFinishChar=terminateOnFinishChar,
      useReducedRedundancy=useReducedRedundancy,
      stupidLine="for i in {0.."+str(processesToRun-1)+"}; do",
      analyzerURL=args.analyzerName,
      runcommand="./run.sh {bucketName} {outputName} {inputNames}".format(bucketName=bucketName,outputName=outputName,inputNames=inputNamesString)
      )
  bootStrapFile.close()
  
  if TESTING:
    print(bootStrapScript)
  else:
    #####################
    #### EC2 ############
    #####################
    
    ############################
    
    ec2 = boto.connect_ec2()
    
    if args.spot:
      ec2SpotRequest = ec2.request_spot_instances(
          spotInstanceMaxPrice,
          count=1,
          image_id = amiString,
          instance_type=args.instanceType,
          key_name = "key2",
          user_data = bootStrapScript,
          block_device_map = blockDeviceMap
          )
      print "Spot instance requested"
    else:
      ec2Reservation = ec2.run_instances(
          min_count=1,
          max_count=1,
          image_id = amiString,
          instance_type=args.instanceType,
          key_name = "key2",
          user_data = bootStrapScript,
          block_device_map = blockDeviceMap,
          instance_initiated_shutdown_behavior='terminate'
          )
      print "On-demand instance requested"
      
