#!/bin/bash

# Config file name to use
#cfgname=vbfHmumuJets01MEPS.dat
cfgname=ggHmumuJets23_MEPS.dat

# Job out name base
jobname=ggHmumuJets23MEPSInitJob

# Other arguments to submitGenJob
extraargs="-s noSmearingConfig2MuSkim.yaml -g 1 --spot"

# First Submit Vanilla Job

runString="./submitGenJob.py $extraargs $cfgname $jobname"
echo $runString
$runString

# Now Vary FSF

variationName="FSF"

scaleFactor=2.0
scaleFactorStr=${scaleFactor/./p}
tmpJobName=$jobname"_Vary"$scaleFactorStr"$variationName"
tmpCfgFile=/tmp/$tmpJobName
#sedString="s/^\s\*$variationName.\*/$variationName:=$scaleFactor/"
sedString="s/$variationName:=.*/$variationName:=$scaleFactor/"

cat $cfgname | sed $sedString > $tmpCfgFile
runString="./submitGenJob.py $extraargs $tmpCfgFile $tmpJobName"
echo $runString
$runString

scaleFactor=0.5
scaleFactorStr=${scaleFactor/./p}
tmpJobName=$jobname"_Vary"$scaleFactorStr"$variationName"
tmpCfgFile=/tmp/$tmpJobName
#sedString="s/^\s\*$variationName.\*/$variationName:=$scaleFactor/"
sedString="s/$variationName:=.*/$variationName:=$scaleFactor/"

cat $cfgname | sed $sedString > $tmpCfgFile
runString="./submitGenJob.py $extraargs $tmpCfgFile $tmpJobName"
echo $runString
$runString

# Now Vary RSF

variationName="RSF"

scaleFactor=2.0
scaleFactorStr=${scaleFactor/./p}
tmpJobName=$jobname"_Vary"$scaleFactorStr"$variationName"
tmpCfgFile=/tmp/$tmpJobName
#sedString="s/^\s\*$variationName.\*/$variationName:=$scaleFactor/"
sedString="s/$variationName:=.*/$variationName:=$scaleFactor/"

cat $cfgname | sed $sedString > $tmpCfgFile
runString="./submitGenJob.py $extraargs $tmpCfgFile $tmpJobName"
echo $runString
$runString

scaleFactor=0.5
scaleFactorStr=${scaleFactor/./p}
tmpJobName=$jobname"_Vary"$scaleFactorStr"$variationName"
tmpCfgFile=/tmp/$tmpJobName
#sedString="s/^\s\*$variationName.\*/$variationName:=$scaleFactor/"
sedString="s/$variationName:=.*/$variationName:=$scaleFactor/"

cat $cfgname | sed $sedString > $tmpCfgFile
runString="./submitGenJob.py $extraargs $tmpCfgFile $tmpJobName"
echo $runString
$runString

# Now Vary QCUT

variationName="QCUT"

scaleFactor=15
scaleFactorStr=${scaleFactor/./p}
tmpJobName=$jobname"_Vary"$scaleFactorStr"$variationName"
tmpCfgFile=/tmp/$tmpJobName
#sedString="s/^\s\*$variationName.\*/$variationName:=$scaleFactor/"
sedString="s/$variationName:=.*/$variationName:=$scaleFactor/"

cat $cfgname | sed $sedString > $tmpCfgFile
runString="./submitGenJob.py $extraargs $tmpCfgFile $tmpJobName"
echo $runString
$runString

scaleFactor=60
scaleFactorStr=${scaleFactor/./p}
tmpJobName=$jobname"_Vary"$scaleFactorStr"$variationName"
tmpCfgFile=/tmp/$tmpJobName
#sedString="s/^\s\*$variationName.\*/$variationName:=$scaleFactor/"
sedString="s/$variationName:=.*/$variationName:=$scaleFactor/"

cat $cfgname | sed $sedString > $tmpCfgFile
runString="./submitGenJob.py $extraargs $tmpCfgFile $tmpJobName"
echo $runString
$runString
