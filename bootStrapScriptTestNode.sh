#!/bin/bash
echo "Starting Bootstrap Script" >> /bootstrap.log
echo `date` >> /bootstrap.log
export workdir={workDir}
hostname {outputName}

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


sudo apt-get update >> /bootstrap.log 2>&1
sudo apt-get upgrade >> /bootstrap.log 2>&1
sudo apt-get install -y python-boto build-essential xorg xorg-dev gfortran subversion bzr cvs htop libboost-dev libgsl0-dev libgsl0-dev python-dev swig zlib1g-dev libboost-iostreams-dev scons  automake autoconf libtool clang-3.5 git libsqlite3-dev tcl
echo "apt-get update'd and install'd" >> /bootstrap.log

mkdir $workdir
ln -s -T $workdir /work
ln -s -T $workdir /home/ubuntu/work
cd $workdir
echo "made work dir" >> /bootstrap.log


echo `date` >> /bootstrap.log
echo "Done." >> /bootstrap.log
