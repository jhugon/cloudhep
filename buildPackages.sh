#!/bin/bash

if [ -z $NPROC ]; then
  NPROC=1
fi

echo "buildPackages.sh Using NPROC=$NPROC" >> /bootstrap.log

date >> $workdir/versionInfo.txt
lsb_release -a >> $workdir/versionInfo.txt
uname -srmvpio >> $workdir/versionInfo.txt
wget http://s3.amazonaws.com/cloud-hep-testing-1/uploadToS3.py
wget http://s3.amazonaws.com/cloud-hep-testing-1/downloadFromS3.py
chmod +x uploadToS3.py
chmod +x downloadFromS3.py

echo "#!/bin/bash" >> $workdir/setupEnv.sh
echo "" >> $workdir/setupEnv.sh
echo "export NPROC=$NPROC" >> $workdir/setupEnv.sh
echo "export workdir=$workdir" >> $workdir/setupEnv.sh
echo "" >> $workdir/setupEnv.sh

wget ftp://root.cern.ch/root/root_v5.34.21.source.tar.gz
tar xzf root*gz
cd root
./configure --enable-c++11 --enable-roofit --enable-minuit2 >& logConf
make -j$NPROC >& logBuild
export ROOTSYS=`pwd`
echo "export ROOTSYS=\`pwd\`/root" >> $workdir/setupEnv.sh
cd $workdir
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ROOTSYS/lib
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$ROOTSYS/lib" >> $workdir/setupEnv.sh
export PATH=$PATH:$ROOTSYS/bin
echo "export PATH=\$PATH:\$ROOTSYS/bin" >> $workdir/setupEnv.sh
export PYTHONPATH=$ROOTSYS/lib:$PYTHONPATH
echo "export PYTHONPATH=\$ROOTSYS/lib:\$PYTHONPATH" >> $workdir/setupEnv.sh
echo "made ROOT" >> /bootstrap.log

wget http://lcgapp.cern.ch/project/simu/HepMC/download/HepMC-2.06.09.tar.gz
tar xzf HepMC*.tar.gz
cd HepMC*/
./configure --prefix=$workdir/hepmc --with-momentum=GEV --with-length=CM >& logConf
make -j$NPROC >& logBuild
make install >& logInstall
export HEPMCLOCATION=$workdir/hepmc
export HEPMCPATH=$HEPMCLOCATION
echo "export HEPMCLOCATION=\`pwd\`/hepmc" >> $workdir/setupEnv.sh
echo "export HEPMCPATH=$HEPMCLOCATION" >> $workdir/setupEnv.sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HEPMCLOCATION/lib
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$HEPMCLOCATION/lib" >> $workdir/setupEnv.sh
export HEPMCVERSION=2.06.09
echo "export HEPMCVERSION=2.06.09" >> $workdir/setupEnv.sh
echo "made HepMC" >> /bootstrap.log

wget http://fastjet.fr/repo/fastjet-3.0.6.tar.gz
tar xzf fastjet*
cd fastjet*
./configure --prefix=$workdir/fastjet --enable-allcxxplugins >& logConf
make -j$NPROC >& logBuild
make install >& logInstall
cd $workdir
export FASTJETPATH=`pwd`/fastjet
echo "export FASTJETPATH=\`pwd\`/fastjet" >> $workdir/setupEnv.sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$workdir/fastjet/lib
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\`pwd\`/fastjet/lib" >> $workdir/setupEnv.sh
export PATH=$PATH:$workdir/fastjet/bin
echo "export PATH=\$PATH:\`pwd\`/fastjet/bin" >> $workdir/setupEnv.sh
echo "made fastjet" >> /bootstrap.log

# For v6
wget http://www.hepforge.org/archive/lhapdf/LHAPDF-6.1.4.tar.gz 
tar xzf LHAPDF-6*.tar.gz
cd LHAPDF*/
./configure --prefix=$workdir/lhapdf6 >& logConf
make -j$NPROC >& logBuild
make install >& logInstall
cd $workdir
export LHAPDFPATH=`pwd`/lhapdf6
echo "export LHAPDFPATH=\`pwd\`/lhapdf6" >> $workdir/setupEnv.sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$workdir/lhapdf6/lib
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\`pwd\`/lhapdf6/lib" >> $workdir/setupEnv.sh
export PATH=$PATH:$workdir/lhapdf6/bin
echo "export PATH=\$PATH:\`pwd\`/lhapdf6/bin" >> $workdir/setupEnv.sh
export export LIBRARY_PATH=$LIBRARY_PATH:$workdir/lhapdf6/lib
echo "export LIBRARY_PATH=\$LIBRARY_PATH:\`pwd\`/lhapdf6/lib" >> $workdir/setupEnv.sh
echo "made lhapdf6" >> /bootstrap.log
echo "Downloading PDFs..." >> /bootstrap.log
cd $workdir/lhapdf6/share/LHAPDF
#lhapdf install cteq6l1 cteq66 MRST2007lomod MRSTMCal CT10 CT10nlo MSTW2008lo68cl MSTW2008nlo68cl NNPDF30_nlo_as_0118 NNPDF30_nnlo_as_0118 NNPDF23_nlo_as_0118  >& $workdir/logDLPDFs
lhapdf install cteq6l1 cteq66 MRST2007lomod MRSTMCal CT10 CT10nlo >& $workdir/logDLPDFs
echo "Contents of lhapdf/share/lhapdf6/" >> /bootstrap.log
ls -lh >> /bootstrap.log
cd $workdir
echo "done Downloading PDFs." >> /bootstrap.log

export PYTHIA8=$workdir/pythia
wget http://home.thep.lu.se/~torbjorn/pythia8/pythia8201.tgz
tar xzf pythia*gz
cd pythia*
./configure --prefix=$PYTHIA8 --with-hepmc2=$HEPMCLOCATION --with-lhapdf6=$LHAPDFPATH --with-root=$ROOTSYS --with-fastjet3=$FASTJETPATH --with-boost --with-gzip --enable-shared >& logConf
make -j$NPROC >& logBuild
make install >& logInstall
cp $PYTHIA8/include/Pythia8/Pythia.h $PYTHIA8/include/.  # hack for Delphes
export PYTHIA8DATA=$PYTHIA8/share/Pythia8/xmldoc
export LIBRARY_PATH=$LIBRARY_PATH:$PYTHIA8/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PYTHIA8/lib
export PYTHIA8EXAMPLES=$PYTHIA8/share/Pythia8/examples
echo "export PYTHIA8=\$workdir/pythia" >> $workdir/setupEnv.sh
echo "export PYTHIA8DATA=\$PYTHIA8/share/Pythia8/xmldoc" >> $workdir/setupEnv.sh
echo "export LIBRARY_PATH=\$LIBRARY_PATH:\$PYTHIA8/lib" >> $workdir/setupEnv.sh
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$PYTHIA8/lib" >> $workdir/setupEnv.sh
echo "export PYTHIA8EXAMPLES=\$PYTHIA8/share/Pythia8/examples" >> $workdir/setupEnv.sh
cd $PYTHIA8EXAMPLES/
make main42 >& logBuild42
make main89 >& logBuild89
cd $workdir
echo "made PYTHIA8" >> /bootstrap.log

wget http://www.hepforge.org/archive/sherpa/SHERPA-MC-2.1.1.tar.gz
tar xzf SHERPA*gz
cd SHERPA*
./configure --enable-hepmc2=$HEPMCLOCATION --enable-multithread --prefix=$workdir/sherpa --enable-binreloc --enable-fastjet=$FASTJETPATH --enable-lhole --enable-root=$ROOTSYS --enable-lhapdf=$LHAPDFPATH >& logConf
make -j$NPROC >& logBuild
make install >& logInstall
cd $workdir
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$workdir/sherpa/lib/SHERPA-MC
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\`pwd\`/sherpa/lib/SHERPA-MC" >> $workdir/setupEnv.sh
export PATH=$PATH:$workdir/sherpa/bin
echo "export PATH=\$PATH:\`pwd\`/sherpa/bin" >> $workdir/setupEnv.sh
echo "made SHERPA" >> /bootstrap.log

wget https://launchpad.net/mg5amcnlo/2.0/2.2.0/+download/MG5_aMC_v2.2.1.tar.gz
tar xzf MG5*.tar.gz
cd MG5*
export PATH=$PATH:`pwd`/bin
echo "cd MG5*" >> $workdir/setupEnv.sh
echo "export PATH=\$PATH:\`pwd\`/bin" >> $workdir/setupEnv.sh
echo "cd .." >> $workdir/setupEnv.sh
cd $workdir
echo "made MG5_aMC" >> /bootstrap.log

wget http://www.hepforge.org/archive/rivet/Rivet-2.1.2.tar.bz2
tar xjf Rivet*.tar.bz2
cd Rivet*
./configure --prefix=$workdir/rivet >& logConf
make -j$NPROC >& logBuild
make install >& logInstall
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$workdir/rivet/lib
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\`pwd\`/rivet/lib" >> $workdir/setupEnv.sh
export PATH=$PATH:$workdir/rivet/bin
echo "export PATH=\$PATH:\`pwd\`/rivet/bin" >> $workdir/setupEnv.sh
cd $workdir
echo "made rivet" >> /bootstrap.log

wget http://theory.sinp.msu.ru/~pukhov/CALCHEP/calchep_3.6.15.tgz
tar xzf calchep*gz
cd calchep*
make >& logBuild
cd $workdir
echo "made CalcHEP" >> /bootstrap.log

wget http://www.hepforge.org/archive/thepeg/ThePEG-1.9.2.tar.bz2
tar xjf ThePEG-*.tar.bz2
cd ThePEG*
./configure --with-hepmc=$HEPMCPATH --prefix=$workdir/ThePEG >& logConf
make -j$NPROC >& logBuild
make install >& logInstall
export THEPEG=$workdir/ThePEG
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$THEPEG/lib
export PATH=$PATH:$THEPEG/bin
echo "export THEPEG=\`pwd\`/ThePEG" >> $workdir/setupEnv.sh
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$THEPEG/lib/ThePEG" >> $workdir/setupEnv.sh
echo "export PATH=\$PATH:\$THEPEG/bin" >> $workdir/setupEnv.sh
cd $workdir
echo "made ThePEG" >> /bootstrap.log

wget http://www.hepforge.org/archive/herwig/Herwig++-2.7.1.tar.bz2
tar xjf Herwig*.tar.bz2
cd Herwig*
./configure --with-thepeg=$THEPEG --with-fastjet=$FASTJETPATH --prefix=$workdir/Herwig++ >& logConf
#./configure --with-thepeg=$THEPEG --with-fastjet=$FASTJETPATH --prefix=$workdir/Herwig++ --with-LHAPDF=$LHAPDF >& logConf
make -j$NPROC >& logBuild
make install >& logInstall
export HERWIGPP=$workdir/Herwig++
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HERWIGPP/lib
export PATH=$PATH:$HERWIGPP/bin
echo "export HERWIGPP=\`pwd\`/Herwig++" >> $workdir/setupEnv.sh
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$HERWIGPP/lib/Herwig++" >> $workdir/setupEnv.sh
echo "export PATH=\$PATH:\$HERWIGPP/bin" >> $workdir/setupEnv.sh
cd $workdir
echo "made Herwig++" >> /bootstrap.log

wget http://fastjet.hepforge.org/contrib/downloads/fjcontrib-1.014.tar.gz
tar xzf fjcontrib*.tar.gz
cd fjcontrib*/
export FJCONTRIBDIR=$workdir/fjcontrib
echo "export FJCONTRIBDIR=\`pwd\`/fjcontrib" >> $workdir/setupEnv.sh
./configure --fastjet-config=$FASTJETPATH/bin/fastjet-config --prefix=$FJCONTRIBDIR >& logConf
make -j$NPROC >& logBuild
make check >& logCheck
make install >& logInstall
cd $workdir
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$workdir/fjcontrib/lib
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\`pwd\`/fjcontrib/lib" >> $workdir/setupEnv.sh
echo "made fastjet-contrib" >> /bootstrap.log

svn checkout --username anonymous --password anonymous --non-interactive svn://powhegbox.mib.infn.it/trunk/POWHEG-BOX-NoUserProcesses powheg >& logCOPowheg
cd powheg
for i in "gg_H" "VBF_H" "Z" "W"; do 
  svn checkout --username anonymous --password anonymous --non-interactive svn://powhegbox.mib.infn.it/trunk/POWHEG-BOX/$i >& logCO$i
  cd $i
  make >& logBuild 
  cd ..
done
cd $workdir
echo "made powheg gg_H VBF_H Z and W" >> /bootstrap.log

cd $workdir
wget http://cp3.irmp.ucl.ac.be/downloads/Delphes-3.1.2.tar.gz
tar xzf Delphes*.tar.gz
cd Delphes*/
env -u PYTHIA8 env -u PYTHIA8DATA make -j$NPROC >& logBuild  # hack for pythia 8.2
export DELPHESDIR=`pwd`
echo "cd \$workdir/Delphes*/" >> $workdir/setupEnv.sh
echo "export DELPHESDIR=\`pwd\`" >> $workdir/setupEnv.sh
echo "cd \$workdir" >> $workdir/setupEnv.sh
cd $workdir
echo "made Delphes" >> /bootstrap.log

cd $workdir
export GOSAMDIR="$workdir/local"
wget http://gosam.hepforge.org/gosam_installer.py
python gosam_installer.py -b -j $NPROC >& logBuildGosam
source $GOSAMDIR/bin/gosam_setup_env.sh
echo "export GOSAMDIR=\`pwd\`/local" >> $workdir/setupEnv.sh
echo "source \$GOSAMDIR/bin/gosam_setup_env.sh" >> $workdir/setupEnv.sh
echo "made GOSAM" >> /bootstrap.log

chmod +x $workdir/setupEnv.sh

cd $workdir
(tar cJf analysisPkgAuto.tar.xz setupEnv.sh versionInfo.txt pythia*/ MG5*/ root/ sherpa/ hepmc/ fastjet/ rivet/ calchep*/ ThePEG/ Herwig++/ fjcontrib/ lhapdf/ lhapdf6/ Delphes*/ local/ uploadToS3.py downloadFromS3.py; echo "Done compressing analysisPkgAuto.tar.xz" >> /bootstrap.log) &
echo $! > /tmp/pidForXZJob
