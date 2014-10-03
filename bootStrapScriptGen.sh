#!/bin/bash
echo "Starting Bootstrap Script" >> /bootstrap.log
echo `date` >> /bootstrap.log

hostname {outputName}{instanceNumber}

export workdir={workDir}
export AWS_ACCESS_KEY_ID={aws_access_key_id}
export AWS_SECRET_ACCESS_KEY={aws_secret_key}
export NPROC={processesPerNode}
NUM_VOLUMES={numVolumes}
DOPILEUP={doPileup}
GENTOUSE={genToUse}
SHERPAPACKAGE={sherpaPackage}
genpids=""
export HOME="/root"  #Hack to try to make Gosam work

read -d '' pythonSetupCommand <<"EOF"
####################################
### Python Setup Script Goes Here: #
####################################
print "Starting pythonSetupCommand"
import boto
import urllib

print("bucketName: {bucketName}")
print("location: {location}")

s3 = boto.connect_s3()
bucket = s3.get_bucket("{bucketName}")
key = bucket.new_key("{outputName}/{configKeyName}")
key.get_contents_to_filename("temp.cmnd")
print("key: {outputName}/{configKeyName}")

if "{delphesKeyName}" != "":
  key = bucket.new_key("{outputName}/{delphesKeyName}")
  key.get_contents_to_filename("{delphesKeyName}")
  print("key: {outputName}/{delphesKeyName}")

if {genToUse} == 2:
  key = bucket.new_key("{outputName}/{calchepKeyName}")
  key.get_contents_to_filename("{calchepKeyName}")
  print("key: {outputName}/{calchepKeyName}")

if {reBuild}==1:
  key = bucket.new_key("{outputName}/buildPackages.sh")
  key.get_contents_to_filename("buildPackages.sh")
  print("key: {outputName}/buildPackages.sh")

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
if useReducedRedundancy:
      key.change_storage_class("REDUCED_REDUNDANCY")

for i in range({processesPerNode}):
  key = bucket.new_key("{outputName}/outfile{instanceNumber}_"+str(i)+".root")
  key.set_metadata("xsec","999.0 pb")
  key.set_metadata("nEvents","12345")
  key.set_contents_from_filename("{dataDir}/temp"+str(i)+".root")
  key.set_acl("{acl}")
  if useReducedRedundancy:
      key.change_storage_class("REDUCED_REDUNDANCY")
  print("writing root file from {dataDir}/temp"+str(i)+".root to {outputName}/outfile"+str(i)+".root")
  print("permissions: {acl}")
  
  key = bucket.new_key("{outputName}/generator{instanceNumber}_"+str(i)+".log")
  key.set_contents_from_filename("logGen"+str(i)+"")
  key.content_type = "text/plain"
  key.set_acl("{acl}")
  if useReducedRedundancy:
      key.change_storage_class("REDUCED_REDUNDANCY")
  
  key = bucket.new_key("{outputName}/analyzer{instanceNumber}_"+str(i)+".log")
  key.set_contents_from_filename("logAna"+str(i)+"")
  key.content_type = "text/plain"
  key.set_acl("{acl}")
  if useReducedRedundancy:
      key.change_storage_class("REDUCED_REDUNDANCY")

if {genToUse}==1 and "{sherpaPackage}"=="":
  key = bucket.new_key("{outputName}/generatorSetup{instanceNumber}.log")
  key.set_contents_from_filename("logGenSetup")
  key.content_type = "text/plain"
  key.set_acl("{acl}")
  if useReducedRedundancy:
      key.change_storage_class("REDUCED_REDUNDANCY")

  key = bucket.new_key("{outputName}/SherpaSetupResults{instanceNumber}.tar.xz")
  key.set_contents_from_filename("Results.tar.xz")
  key.content_type = "text/plain"
  key.set_acl("{acl}")
  if useReducedRedundancy:
      key.change_storage_class("REDUCED_REDUNDANCY")

if {reBuild}==1:
  key = bucket.new_key("{outputName}/analysisPkgAuto{instanceNumber}.tar.xz")
  key.set_contents_from_filename("analysisPkgAuto.tar.xz")
  key.content_type = "text/plain"
  key.set_acl("{acl}")
  if useReducedRedundancy:
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

# Sets up nice less colors for all users
echo "export LESS='-R'" >> /etc/profile

sudo apt-get update
sudo apt-get install -y python-boto build-essential xorg xorg-dev gfortran subversion bzr cvs htop libboost-dev libgsl0-dev libgsl0-dev python-dev swig zlib1g-dev libboost-iostreams-dev scons  automake autoconf libtool clang-3.5 git libsqlite3-dev tcl
echo "apt-get update'd and install'd" >> /bootstrap.log

mkdir $workdir
ln -s -T $workdir /work
ln -s -T $workdir /home/ubuntu/work
cd $workdir
echo "made work dir" >> /bootstrap.log

cd $workdir
python -c "$pythonSetupCommand" >& logPythonSetupCommand 2>&1
echo "Ran python Setup Command" >> /bootstrap.log
echo `date` >> /bootstrap.log

cd $workdir
if (({reBuild})); then
  echo "Starting build script" >> /bootstrap.log
  bash buildPackages.sh >> /bootstrap.log
  genpids=$(cat /tmp/pidForXZJob)" "
  echo "built and setup analysisPkg" >> /bootstrap.log
else
  wget {packageURL}
  tar xJf {packageName}
  echo "downloaded and setup analysisPkg" >> /bootstrap.log
fi

source setupEnv.sh

echo "###########################################" >> /bootstrap.log
echo "############## ENV ########################" >> /bootstrap.log
echo "###########################################" >> /bootstrap.log
env >> /bootstrap.log
echo "###########################################" >> /bootstrap.log
echo "###########################################" >> /bootstrap.log
echo "###########################################" >> /bootstrap.log

if (($DOPILEUP == 1)); then
  wget {minbiasFileURL} -O minbias.root
fi

#Pre-calculate ME/xsec In Sherpa
if (($GENTOUSE == 1)); then
  cd $workdir
  if [ -z $SHERPAPACKAGE ]; then
    echo "Starting Sherpa Initialization Job" >> /bootstrap.log
    echo `date` >> /bootstrap.log
    cp temp.cmnd tempSetup.cmnd
    sed -i "s/^.*EVENTS.*$/  EVENTS = 100/" tempSetup.cmnd
    Sherpa -f tempSetup.cmnd -j $NPROC >& logGenSetup
    echo `date` >> /bootstrap.log
    if [ -a "makelibs" ]; then
      echo "File 'makelibs' exists, must build libraries..." >> /bootstrap.log
      bash makelibs >> /bootstrap.log
      echo "done building." >> /bootstrap.log
      echo "Re-running Sherpa Initialization Job" >> /bootstrap.log
      Sherpa -f tempSetup.cmnd -j $NPROC 2>&1 >> logGenSetup
    fi
    echo "Creating Sherpa Result archive Results.tar.xz" >> /bootstrap.log
    tar cJf Results.tar.xz temp.cmnd Results/ Process/
    echo `date` >> /bootstrap.log
    echo "Done with all Sherpa Initialization" >> /bootstrap.log
  else
    echo "Downloading Sherpa Package $SHERPAPACKAGE to sherpaPkg.tar.xz" >> /bootstrap.log
    wget $SHERPAPACKAGE -O sherpaPkg.tar.xz >> /bootstrap.log
    tar xJvf sherpaPkg.tar.xz >> /bootstrap.log
    echo "Done with all Sherpa Initialization" >> /bootstrap.log
  fi
fi

#CalcHEP
if (($GENTOUSE == 2)); then
  echo "Starting CalcHEP Job" >> /bootstrap.log
  echo `date` >> /bootstrap.log
  cd $workdir/calchep*/
  ./mkUsrDir usrDir
  cd usrDir
  cp $workdir/{calchepKeyName} batch.txt
  sed -i "s/^Filename.*/Filename   :   output.slha/" batch.txt
  ./calchep_batch batch.txt
  cd Events
  gunzip output.slha-single.lhe.gz
  cp output.slha-single.lhe $workdir/input0.lhe
  echo `date` >> /bootstrap.log
fi

echo "###########################################" >> /bootstrap.log
echo "About to run jobs.  Work directory contents:" >> /bootstrap.log
ls $workdir >> /bootstrap.log
echo "###########################################" >> /bootstrap.log

## Running Jobs
ANALYZERTOUSE={analyzerToUse}
{stupidLine}
cd $workdir
ANALYZERCOMMAND=""
if (($ANALYZERTOUSE == 0)); then
  DELPHESCONFIGNAME={delphesKeyName}
  if [ "$DELPHESCONFIGNAME" = "" ]; then
    DELPHESCONFIGNAME="$DELPHESDIR/examples/delphes_card_CMS.tcl"
  fi
  ANALYZERCOMMAND="$DELPHESDIR/DelphesHepMC $DELPHESCONFIGNAME {dataDir}/temp$i.root"
  if (($DOPILEUP == 1)); then
    echo "Using Pileup" >> /bootstrap.log
    ANALYZERCOMMAND=$ANALYZERCOMMAND" -p minbias.root"
  else
    echo "Not using Pileup" >> /bootstrap.log
  fi
fi
if (($ANALYZERTOUSE == 1)); then
  ANALYZERCOMMAND="rivet -a {rivetAnalysis} temp$i.hepmc2g"
fi

cd $workdir
mkfifo temp$i.hepmc2g
#cat > temp$i.hepmc2g &
#exec 3<temp$i.hepmc2g &
GENERATORCOMMAND="null"
if (($GENTOUSE == 0)); then
  # Pythia
  cp temp.cmnd temp$i.cmnd
  echo "Random:setSeed = on" >> temp$i.cmnd
  echo "Random:seed = $((1000+{instanceNumber}*30+$i))" >> temp$i.cmnd
  GENERATORCOMMAND="./pythia*/examples/main42.exe temp$i.cmnd temp$i.hepmc2g"
fi
if (($GENTOUSE == 1)); then
  # Sherpa
  GENERATORCOMMAND="Sherpa -f temp.cmnd -R $((1000+{instanceNumber}*30+$i)) EVENT_OUTPUT=HepMC_GenEvent[temp$i]"
fi
echo "ANALYZERCOMMAND is: $ANALYZERCOMMAND" >> /bootstrap.log
echo "GENERATORCOMMAND is: $GENERATORCOMMAND" >> /bootstrap.log
if (($ANALYZERTOUSE == 0)); then
  cat temp$i.hepmc2g | $ANALYZERCOMMAND >& logAna$i &
else
  $ANALYZERCOMMAND >& logAna$i &
fi
genpids=$genpids$!" "
$GENERATORCOMMAND >& logGen$i &
genpids=$genpids$!" "
done
echo "Started Pythia & Spods Jobs" >> /bootstrap.log
echo "pids: "$genpids >> /bootstrap.log
wait $genpids
echo "Finished Pythia & Spods Jobs" >> /bootstrap.log
echo `date` >> /bootstrap.log

python -c "$pythonCleanupCommand" >& logPythonCleanupCommand
echo "Ran python Cleanup Command" >> /bootstrap.log 2>&1

echo `date` >> /bootstrap.log
echo "Done." >> /bootstrap.log

{terminateOnFinishChar}shutdown -h now
