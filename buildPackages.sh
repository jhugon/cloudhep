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

echo "#!/bin/bash\n" >> $workdir/setupEnv.sh

wget ftp://root.cern.ch/root/root_v5.34.01.source.tar.gz
tar xzf root*gz
cd root
./configure >& logConf
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

bzr branch lp:spods spods
#bzr branch lp:~reg-hugonweb/+junk/spodsNJ spods
cd spods*
./build.sh -j$NPROC >& logBuild
export HEPMCLOCATION=`pwd`/external/HepMC
export HEPMCPATH=`pwd`/external/HepMC
export FASTJETPATH=`pwd`/external/fastjet
echo "cd spods*" >> $workdir/setupEnv.sh
echo "export HEPMCLOCATION=\`pwd\`/external/HepMC" >> $workdir/setupEnv.sh
echo "export HEPMCPATH=\`pwd\`/external/HepMC" >> $workdir/setupEnv.sh
echo "export FASTJETPATH=\`pwd\`/external/fastjet" >> $workdir/setupEnv.sh
cd $workdir
export HEPMCVERSION=2.06.05
echo "export HEPMCVERSION=2.06.05" >> $workdir/setupEnv.sh
echo "cd .." >> $workdir/setupEnv.sh
echo "made SPODS" >> /bootstrap.log

wget http://fastjet.fr/repo/fastjet-3.0.3.tar.gz
tar xzf fastjet*
cd fastjet*
./configure --prefix=$workdir/fastjet --enable-allcxxplugins
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

wget http://www.hepforge.org/archive/lhapdf/lhapdf-5.8.9.tar.gz
tar xzf lhapdf*.tar.gz
cd lhapdf*
./configure --prefix=$workdir/lhapdf >& logConf
make -j$NPROC >& logBuild
make install >& logInstall
cd $workdir
export LHAPDFPATH=`pwd`/lhapdf
echo "export LHAPDFPATH=\`pwd\`/lhapdf" >> $workdir/setupEnv.sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$workdir/lhapdf/lib
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\`pwd\`/lhapdf/lib" >> $workdir/setupEnv.sh
export PATH=$PATH:$workdir/lhapdf/bin
echo "export PATH=\$PATH:\`pwd\`/lhapdf/bin" >> $workdir/setupEnv.sh
echo "made lhapdf" >> /bootstrap.log
echo "Downloading PDFs..." >> /bootstrap.log
cd $workdir/lhapdf/share/lhapdf
#lhapdf-getdata CTEQ6ll CTEQ66 CTEQ6m lomod MCal CT10NLO NNPDF23_nlo_as MSTW2008nlo68cl MSTW2008lo68cl 2>&1 >> /bootstrap.log
lhapdf-getdata CTEQ6ll CTEQ66 CTEQ6m lomod MCal CT10NLO 2>&1 >> /bootstrap.log
echo "Contents of lhapdf/share/lhapdf/" >> /bootstrap.log
ls -lh >> /bootstrap.log
cd $workdir
echo "done Downloading PDFs." >> /bootstrap.log

wget http://home.thep.lu.se/~torbjorn/pythia8/pythia8176.tgz
tar xzf pythia*gz
cd pythia*
./configure --with-hepmc=$HEPMCLOCATION --with-hepmcversion=$HEPMCVERSION --enable-shared --enable-gzip --with-zlib=/usr/lib/x86_64-linux-gnu >& logConf
make -j$NPROC >& logBuild
export PYTHIA8=`pwd`
export PYTHIA8DATA=`pwd`/xmldoc
echo "cd pythia*" >> $workdir/setupEnv.sh
echo "export PYTHIA8=\`pwd\`" >> $workdir/setupEnv.sh
echo "export PYTHIA8DATA=\`pwd\`/xmldoc" >> $workdir/setupEnv.sh
cd examples
make -j$NPROC main42
cd $workdir
echo "cd .." >> $workdir/setupEnv.sh
echo "made PYTHIA8" >> /bootstrap.log

wget http://www.hepforge.org/archive/sherpa/SHERPA-MC-1.4.3.tar.gz
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

bzr branch lp:madgraph5 madgraph5
cd madgraph5
export PATH=$PATH:`pwd`/bin
echo "cd madgraph5" >> $workdir/setupEnv.sh
echo "export PATH=\$PATH:\`pwd\`/bin" >> $workdir/setupEnv.sh
echo "cd .." >> $workdir/setupEnv.sh
echo "linking lhapdf with madgraph5..." >> /bootstrap.log
cd $workdir/madgraph5/lib
ln -s -T $workdir/lhapdf/lib/libLHAPDF.a libLHAPDF.a
ln -s -T $workdir/lhapdf/lib/libLHAPDF.so libLHAPDF.so
ln -s -T $workdir/lhapdf/lib/libLHAPDF.so.0 libLHAPDF.so.0
for i in `ls $workdir/lhapdf/share/lhapdf/*`; do
  ln -s -T $i `basename $i` 
done
echo "contents of madgraph5/lib" >> /bootstrap.log
ls >> /bootstrap.log
echo "done linking lhapdf with madgraph5." >> /bootstrap.log
cd $workdir
echo "made madgraph5" >> /bootstrap.log

wget http://www.hepforge.org/archive/rivet/Rivet-1.8.1.tar.bz2
tar xjf Rivet*bz2
cd Rivet*
./configure --prefix=$workdir/rivet
make -j$NPROC >& logBuild
make install >& logInstall
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$workdir/rivet/lib
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\`pwd\`/rivet/lib" >> $workdir/setupEnv.sh
export PATH=$PATH:$workdir/rivet/bin
echo "export PATH=\$PATH:\`pwd\`/rivet/bin" >> $workdir/setupEnv.sh
cd $workdir
echo "made rivet" >> /bootstrap.log

wget http://theory.sinp.msu.ru/~pukhov/CALCHEP/calchep_3.4.0.tgz
tar xzf calchep*gz
cd calchep*
make >& logBuild
cd $workdir
echo "made CalcHEP" >> /bootstrap.log

wget http://www.hepforge.org/archive/thepeg/ThePEG-1.8.0.tar.bz2
tar xjf ThePEG-*.tar.bz2
cd ThePEG*
./configure --with-hepmc=$HEPMCPATH --prefix=$workdir/ThePEG >& logConf
make -j$NPROC >& logBuild
make install
export THEPEG=$workdir/ThePEG
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$THEPEG/lib
export PATH=$PATH:$THEPEG/bin
echo "export THEPEG=\`pwd\`/ThePEG" >> $workdir/setupEnv.sh
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$THEPEG/lib/ThePEG" >> $workdir/setupEnv.sh
echo "export PATH=\$PATH:\$THEPEG/bin" >> $workdir/setupEnv.sh
cd $workdir
echo "made ThePEG" >> /bootstrap.log

wget http://www.hepforge.org/archive/herwig/Herwig++-2.6.0.tar.bz2
tar xjf Herwig*.tar.bz2
cd Herwig*
./configure --with-thepeg=$THEPEG --with-fastjet=$FASTJETPATH --prefix=$workdir/Herwig++ >& logConf
#./configure --with-thepeg=$THEPEG --with-fastjet=$FASTJETPATH --prefix=$workdir/Herwig++ --with-LHAPDF=$LHAPDF >& logConf
make -j$NPROC >& logBuild
make install
export HERWIGPP=$workdir/Herwig++
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HERWIGPP/lib
export PATH=$PATH:$HERWIGPP/bin
echo "export HERWIGPP=\`pwd\`/Herwig++" >> $workdir/setupEnv.sh
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$HERWIGPP/lib/Herwig++" >> $workdir/setupEnv.sh
echo "export PATH=\$PATH:\$HERWIGPP/bin" >> $workdir/setupEnv.sh
cd $workdir
echo "made Herwig++" >> /bootstrap.log

svn checkout http://pilemc.hepforge.org/svn/trunk pilemcRepo
cd pilemcRepo
export PILEMCDIR=$workdir/pilemc
./reconf
./configure --prefix=$PILEMCDIR --with-hepmc=$HEPMCPATH
make -j$NPROC >& logBuild
make install >& logInstall
export PATH=$PATH:$workdir/pilemc/bin
echo "export PATH=\$PATH:\`pwd\`/pilemc/bin" >> $workdir/setupEnv.sh
cd $workdir
echo "made pilemc" >> /bootstrap.log

wget http://fastjet.hepforge.org/contrib/downloads/fjcontrib-1.003.tar.gz
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

svn checkout --username anonymous --password anonymous --non-interactive svn://powhegbox.mib.infn.it/trunk/POWHEG-BOX powheg

bzr branch lp:/~reg-hugonweb/+junk/myPythiAnalyzers pythiaAnalyzers
cd pythiaAnalyzers/
scons -j$NPROC >& logBuild
export PYTHIAANALYZERSDIR=$workdir/pythiaAnalyzers
echo "export PYTHIAANALYZERSDIR=\`pwd\`/pythiaAnalyzers" >> $workdir/setupEnv.sh
cd $workdir

chmod +x $workdir/setupEnv.sh

(tar cJf analysisPkgAuto.tar.xz setupEnv.sh versionInfo.txt pythia*/ madgraph*/ root/ sherpa/ spods/ fastjet/ rivet/ calchep*/ ThePEG/ Herwig++/ pilemc/ fjcontrib/ lhapdf/ pythiaAnalyzers/ uploadToS3.py downloadFromS3.py; echo "Done compressing analysisPkgAuto.tar.xz" >> /bootstrap.log) &
