#!/usr/bin/python

## Requires boto env var authentication
## Passes same authentication vars on to ec2 nodes

import os
import sys
import re
import argparse
import boto
from boto.s3.connection import Location
from boto.ec2.blockdevicemapping import BlockDeviceType
from boto.ec2.blockdevicemapping import BlockDeviceMapping

parser = argparse.ArgumentParser(description="Submits Generator Jobs to the Cloud")
parser.add_argument("configFile", help="The input generator config file")
parser.add_argument("jobName", help="The job name; ec2 instances will have this name, and the s3 ouput directory will have this name")
parser.add_argument("-t","--test", help="Test mode: print bootstrap script to screen",action='store_true',default=False)

parser.add_argument("-g","--generator", help="int, Generator to use: 0=Pythia8 (default), 1=Sherpa, 2=CalcHEP+Pythia8, 3=Herwig++",choices=[0,1,2,3],default=0, type=int)
parser.add_argument("-a","--analyzer",help="int, Analyzer of Generated Data to use: 0=Delphes (default), 1=RIVET",choices=[0,1],default=0, type=int)
parser.add_argument("-s","--delphesConfig", help="Delphes configuration file to use, defaults to examples/delphes_card_CMS.tcl",default="")
parser.add_argument("-r","--rivetAnalysis", help="RIVET analysis to run, default: 'MC_ZJETS'",default="MC_ZJETS")
parser.add_argument("--calchepBatchFile", help="CalcHEP batch file to run")

parser.add_argument("-d","--dontTerminate", help="Don't Terminate ec2 instance when generation finishes; useful for testing",action='store_true',default=False)
parser.add_argument("-b","--build", help="re-build all packages from source",action='store_true',default=False)
parser.add_argument("-i","--instanceType", help="EC2 instance type, default: m3.medium",choices=["m3.medium","c3.large","c3.xlarge","c3.2xlarge","c3.4xlarge","c3.8large"],default="m3.medium")
parser.add_argument("-n","--numberInstances", help="int, number of EC2 instances to launch, default: 1",default=1, type=int)
parser.add_argument("--spot",help="Request EC2 Spot instances instead of on-demand ones for reduced cost.  The max price is in the script",action='store_true', default=False)
parser.add_argument("--pileup",help="int, the poisson mean pileup to generate, default: -",action='store_true', default=False)

parser.add_argument("--sherpaPackage",help="URI to the Sherpa Initialization Results for a Process. The config file will be replaced by the one in here",default="")

args = parser.parse_args()

#print "Testing {0}".format(args.test)
TESTING=args.test
outputName = args.jobName

reBuild = 0 #0 for False 1 for True
buildScriptStr = ""
if args.build:
  reBuild = 1
  tmpBS = open("buildPackages.sh")
  buildScriptStr = tmpBS.read()
  tmpBS.close()

#Job

emailAddress = ""

#ec2
amiString = "ami-7449fc1c" # Ubuntu Trusty 14.04 LTS 64-bit Instance Store us-east-1
placement = "us-east-1a"
terminateOnFinish = not args.dontTerminate

spotInstanceMaxPrices ={
"m3.medium":0.015,
"c3.large":0.025,
"c3.xlarge":0.050,
"c3.2xlarge":0.10,
"c3.4xlarge":0.20,
"c3.8xlarge":0.40,
}
spotInstanceMaxPrice = spotInstanceMaxPrices[args.instanceType]

# For Ubuntu Trusty 14.04 LTS 64-bit
packageURL = "http://s3.amazonaws.com/cloud-hep-testing-1/analysisPkg2.tar.xz"
packageName = "analysisPkg2.tar.xz"

minbiasFileURL = "null"
doPileup = 0
if args.pileup:
  doPileup = 1
  print("Running with Pileup")
else:
  doPileup = 0
  print("Running without Pileup")

#s3
bucketName = "cloud-hep-testing-1"
location=Location.DEFAULT # DEFAULT for usEast, EU for eu
acl = "public-read" #public-read, private, public-read-write, authenticated-read
configKeyName="config.txt"
delphesKeyName="delphesConfig.txt"
calchepKeyName="calchepConfig.txt"
if args.delphesConfig == "":
  delphesKeyName=""
useReducedRedundancy = True

## Setup appropriate block device map for instance storage

instanceStoreDeviceNums ={
"m3.medium":1,
"c3.large":2,
"c3.xlarge":2,
"c3.2xlarge":2,
"c3.4xlarge":2,
"c3.8xlarge":2,
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
"c3.2xlarge":8,
"c3.4xlarge":16,
"c3.8xlarge":32,
}
for key in nProcNums:
  nProcNums[key] *= 2
processesPerNode = nProcNums[args.instanceType]
processesToRun = processesPerNode

terminateOnFinishChar = ""
if not terminateOnFinish:
  terminateOnFinishChar = "#"

if args.generator == 0:
  print("Generating with Pythia8")
elif args.generator == 1:
  print("Generating with Sherpa")
if args.generator == 2:
  print("Generating with Calchep+Pythia8")
  print("***Make sure there is no process active in Pythia8 config file!!!!***")
  print("Only Single Process Per Node supported for CalcHEP")
  processesToRun = 1
if args.generator == 3:
  print("Generating with Herwig++")

if args.sherpaPackage != "":
  print("Using Sherpa Package at: "+args.sherpaPackage)
  if args.generator != 1:
    print("Error: You must use the Sherpa generator to run with a Sherpa gen package\nUse the -g 1 option\nExiting")
    sys.exit(1)
  if not re.match(r".*\.tar\.xz",args.sherpaPackage):
    print("Error: Sherpa gen package must be .tar.xz file. Exiting.")
    sys.exit(1)

if args.dontTerminate:
  print("Instance will not terminate on job completion")
if args.build:
  print("Will build analysis tools from source")

####################################

if not TESTING:
  ##################################
  ## S3
  
  s3 = boto.connect_s3()

  try:
    bucket = s3.get_bucket(bucketName)
  except:
    print "Creating new bucket: "+bucketName
    bucket = s3.create_bucket(bucketName,location=location)
    bucket.set_acl(acl) 
  key = bucket.new_key(outputName+"/"+configKeyName)
  key.set_contents_from_filename(args.configFile)
  key.content_type = "text/plain"
  key.set_acl(acl) 
  if useReducedRedundancy:
    key.change_storage_class("REDUCED_REDUNDANCY")

  if args.delphesConfig != "":
    key = bucket.new_key(outputName+"/"+delphesKeyName)
    key.set_contents_from_filename(args.delphesConfig)
    key.content_type = "text/plain"
    key.set_acl(acl) 
    if useReducedRedundancy:
      key.change_storage_class("REDUCED_REDUNDANCY")
  if args.generator == 2:  #Calchep+Pythia8
    try:
        tmpF = open(args.calchepBatchFile)
        tmpF.close()
    except:
        print("CalcHEP+Pythia8 Mode requires a valid CalcHEP Batch file!!!")
        print("Exiting")
        sys.exit(1)
    key = bucket.new_key(outputName+"/"+calchepKeyName)
    key.set_contents_from_filename(args.calchepBatchFile)
    key.content_type = "text/plain"
    key.set_acl(acl) 
    if useReducedRedundancy:
      key.change_storage_class("REDUCED_REDUNDANCY")
  
  if args.build:
    key = bucket.new_key(outputName+"/buildPackages.sh")
    key.set_contents_from_filename("buildPackages.sh")
    key.set_acl(acl) 
    if useReducedRedundancy:
      key.change_storage_class("REDUCED_REDUNDANCY")
  
###
###  Main loop over nInstances
###

for iInstance in range(args.numberInstances):
  bootStrapFile = open("bootStrapScriptGen.sh")
  bootStrapScript = bootStrapFile.read()
  bootStrapScript = bootStrapScript.format(
      aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
      aws_secret_key=os.environ["AWS_SECRET_ACCESS_KEY"],
      configKeyName=configKeyName,
      bucketName=bucketName,
      location=location,
      processesPerNode=processesPerNode,
      instanceNumber=iInstance,
      numVolumes=instanceStoreDeviceNums[args.instanceType],
      outputName=outputName,
      acl=acl,
      dataDir=dataDir,
      workDir=workDir,
      reBuild=reBuild,
      buildScriptStr=buildScriptStr,
      packageURL=packageURL,
      packageName=packageName,
      emailAddress=emailAddress,
      terminateOnFinishChar=terminateOnFinishChar,
      useReducedRedundancy=useReducedRedundancy,
      genToUse=args.generator,
      analyzerToUse=args.analyzer,
      delphesKeyName=delphesKeyName,
      calchepKeyName=calchepKeyName,
      rivetAnalysis=args.rivetAnalysis,
      minbiasFileURL = minbiasFileURL,
      doPileup = doPileup,
      sherpaPackage=args.sherpaPackage,
      stupidLine="for i in {0.."+str(processesToRun-1)+"}; do"
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
