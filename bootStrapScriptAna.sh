#!/bin/bash
echo "Starting Bootstrap Script" >> /bootstrap.log
echo `date` >> /bootstrap.log
export workdir={workDir}
export AWS_ACCESS_KEY_ID={aws_access_key_id}
export AWS_SECRET_ACCESS_KEY={aws_secret_key}

hostname {outputName}{instanceNumber}

read -d '' pythonSetupCommand <<"EOF"
####################################
### Python Setup Script Goes Here: #
####################################
print "Starting pythonSetupCommand"
import boto
import urllib

idFile = urllib.urlopen('http://169.254.169.254/latest/meta-data/instance-id')
instanceID = ""
for line in idFile:
  instanceID = line
nameString = "{outputName}{instanceNumber} CloudHEP"

ec2 = boto.connect_ec2()
ec2.create_tags([instanceID],{{"Name": nameString}})

print "Done."
####################################
####################################
####################################
EOF

read -d '' pythonCleanupCommand <<"EOF"
####################################
### Python Cleanup Script Goes Here:
####################################
print "Starting pythonCleanupCommand"
import boto

useReducedRedundancy = {useReducedRedundancy}

s3 = boto.connect_s3()
bucket = s3.get_bucket("{bucketName}")
print("bucketName: {bucketName}")
print("location: {location}")

key = bucket.new_key("{outputName}/bootstrap{instanceNumber}.log")
key.set_contents_from_filename("/bootstrap.log")
key.content_type = "text/plain"
key.set_acl("{acl}")
key.change_storage_class("REDUCED_REDUNDANCY")

if "{emailAddress}" != "":
  sns = boto.connect_sns()
  sns.create_topic("{outputName}")
  sns.subscribe("{outputName}","email","{emailAddress}")
  sns.publish("{outputName}","Job {outputName} instance {instanceNumber} is Done with {processesPerNode} processes.","s3hep: {outputName} {instanceNumber} Done")

print "Done."
####################################
####################################
####################################
EOF

####################################
### BASH Setup/Install/Run Stuff Here:
####################################

NUM_VOLUMES={numVolumes}

if (($NUM_VOLUMES > 0)); then
  mkdir /data1
  mount /dev/xvdb /data1 -o noatime,data=writeback
  echo "Setup /data1" >> /bootstrap.log
fi
if (($NUM_VOLUMES > 1)); then
  mkdir /data2
  mount /dev/xvdc /data2 -o noatime,data=writeback
  echo "Setup /data2" >> /bootstrap.log
fi
if (($NUM_VOLUMES > 2)); then
  mkdir /data3
  mount /dev/xvdd /data3 -o noatime,data=writeback
  echo "Setup /data3" >> /bootstrap.log
fi
if (($NUM_VOLUMES > 3)); then
  mkdir /data4
  mount /dev/xvde /data4 -o noatime,data=writeback
  echo "Setup /data4" >> /bootstrap.log
fi


sudo apt-get update
sudo apt-get install -y python-boto build-essential xorg xorg-dev gfortran subversion bzr cvs htop libboost-dev libgsl0-dev libgsl0-dev python-dev swig zlib1g-dev libboost-iostreams-dev scons automake autoconf libtool clang-3.5 git
echo "apt-get update'd and install'd" >> /bootstrap.log

mkdir $workdir
ln -s -T $workdir /work
ln -s -T $workdir /home/ubuntu/work
cd $workdir
echo "made work dir" >> /bootstrap.log

cd $workdir
python -c "$pythonSetupCommand" >& logPythonSetupCommand 2>&1
echo "Ran python Setup Command" >> /bootstrap.log

cd $workdir
wget {packageURL} #>> /bootstrap.log 2>&1
tar xJf {packageName} >> /bootstrap.log 2>&1
source setupEnv.sh
echo "downloaded and setup analysisPkg" >> /bootstrap.log

#####################################################3

mkdir $workdir/analysis
cd analysis

if [[ "{analyzerURL}" =~ "lp:" ]]; then
  echo "Getting bzr branch {analyzerURL}" >> /bootstrap.log
  bzr branch "{analyzerURL}" >> /bootstrap.log 2>&1
elif [[ "{analyzerURL}" =~ ".tgz" ]]; then
  echo "Downloading .tgz File {analyzerURL}" >> /bootstrap.log
  wget "{analyzerURL}" >> /bootstrap.log 2>&1
  tar xzf * >> /bootstrap.log 2>&1
elif [[ "{analyzerURL}" =~ ".tar.gz" ]]; then
  echo "Downloading .tar.gz File {analyzerURL}" >> /bootstrap.log
  wget "{analyzerURL}" >> /bootstrap.log 2>&1
  tar xzf * >> /bootstrap.log 2>&1
elif [[ "{analyzerURL}" =~ ".tar.bz2" ]]; then
  echo "Downloading .tar.bz2 File {analyzerURL}" >> /bootstrap.log
  wget "{analyzerURL}" 2>&1
  tar xjf * >> /bootstrap.log 2>&1
elif [[ "{analyzerURL}" =~ ".tar.xz" ]]; then
  echo "Downloading .tar.xz File {analyzerURL}" >> /bootstrap.log
  wget "{analyzerURL}" 2>&1
  tar xJf * >> /bootstrap.log 2>&1
elif [[ "{analyzerURL}" =~ ".zip" ]]; then
  echo "Downloading .zip File {analyzerURL}" >> /bootstrap.log
  wget "{analyzerURL}" >> /bootstrap.log 2>&1
  unzip * >> /bootstrap.log 2>&1
else
  echo "Downloading File {analyzerURL}" >> /bootstrap.log
  wget "{analyzerURL}" >> /bootstrap.log 2>&1 2>&1
fi

cd *
analysisDir=`pwd`
if [[ "{analyzerURL}" =~ "lp:" ]]; then
bzr log -r-1 >> /bootstrap.log 2>&1 # print latest version of analyzer
fi
{runcommand} >> /bootstrap.log 2>&1
#####################################################3

cd $workdir
python -c "$pythonCleanupCommand" >> /bootstrap.log 2>&1
echo "Ran python Cleanup Command" >> /bootstrap.log

echo `date` >> /bootstrap.log
echo "Done." >> /bootstrap.log

{terminateOnFinishChar}shutdown -h now
