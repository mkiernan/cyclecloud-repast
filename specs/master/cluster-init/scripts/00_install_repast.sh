#!/bin/bash
################################################################################
#
# Install repast: https://repast.github.io/ with boost & intel mpi
#
# boost, intelmpi repast built from source. 
#
# Tested On: CentOS 7.6
#
################################################################################
set -x
#set -xeuo pipefail #-- strict/exit on fail

if [[ $(id -u) -ne 0 ]] ; then
        echo "Must be run as root"
        exit 1
fi

ABMSHARED=/mnt/exports/shared

NUM_CPUS=$( cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1 )

setup_build_tools()
{
    echo "Installing Development tools"
    #yum update -y
    #yum groupinstall -y 'Development Tools'

    # setup CMAKE
    echo "Installing CMAKE"
    wget -q http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/c/cmake3-3.6.3-1.el7.x86_64.rpm
    wget -q http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
    rpm -Uvh epel-release*rpm
    yum install cmake3 -y
    ln -s /usr/bin/cmake3 /usr/bin/cmake
    yum install htop -y

    # setup GCC 7.2
    echo "Installing GCC 7.2"
    #yum install centos-release-scl-rh -y
    #yum --enablerepo=centos-sclo-rh-testing install devtoolset-7-gcc -y
    #yum --enablerepo=centos-sclo-rh-testing install devtoolset-7-gcc-c++ -y
    #yum --enablerepo=centos-sclo-rh-testing install devtoolset-7-gcc-gfortran -y

} #-- setup_build_tools() --#

#-- Install Boost with Intel MPI 
install_boost_mpi()
{
    yum install -y curl libcurl libcurl-devel
    yum install -y netcdf netcdf-devel gdal
    yum install -y netcdf-cxx.x86_64 netcdf-cxx-devel.x86_64 # boost
    yum install -y python-devel # needed by boost manual install
    yum install -y gtest gtest-devel
    BOOST_VERSION=1_69_0
    BOOST_DOTTED_VERSION=$(echo $BOOST_VERSION | tr _ .)
    wget -q -O - https://sourceforge.net/projects/boost/files/boost/${BOOST_DOTTED_VERSION}/boost_${BOOST_VERSION}.tar.gz | tar -xzf -
    pushd boost_${BOOST_VERSION}
    #./bootstrap.sh --prefix=/usr/local
    ./bootstrap.sh --prefix=$ABMSHARED
    echo "using mpi : /opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin/mpicc ;" >> project-config.jam
    ./b2 -j"${NUM_CPUS}" install
    popd
    #rm -rf ./boost_${BOOST_VERSION}

} #-- end of install_boost_mpi() --#

install_repast() 
{
    # install repast manually from the makefile
    wget https://repast.github.io/hpc_tutorial/SRC.tar.gz
    tar -xvf SRC.tar.gz
    wget https://github.com/Repast/repast.hpc/releases/download/v2.3.0/repast_hpc-2.3.0.tgz
    tar -xvf repast_hpc-2.3.0.tgz
    pushd repast_hpc-2.3.0/MANUAL_INSTALL
    # edit makefile between the two markers
    cp Makefile Makefile.org
    sed -i '/CXX=mpicxx/,/INSTALL_DIR/c\
CXX=mpicxx -fpermissive\
CXXLD=mpicxx -fpermissive\
#BOOST_INCLUDE_DIR=/usr/local/include\
#BOOST_LIB_DIR=/usr/local/lib\
BOOST_INCLUDE_DIR=/mnt/exports/shared/include\
BOOST_LIB_DIR=/mnt/exports/shared/lib\
#BOOST_INFIX=-mt\
BOOST_INFIX=\
NETCDF_INCLUDE_DIR=/usr/include\
NETCDF_LIB_DIR=/usr/lib64\
NETCDF_CXX_INCLUDE_DIR=/usr/include\
NETCDF_CXX_LIB_DIR=/usr/lib64\
CURL_INCLUDE_DIR=/usr/include\
CURL_LIB_DIR=/usr/lib64\
INSTALL_DIR=/mnt/exports/shared/repast_hpc-2.3.0' ./Makefile
#INSTALL_DIR=/opt/repast_hpc-2.3.0' ./Makefile
    # build it
    make -j10 
    popd

} #-- end of install_repast() --#

setup_repast_env()
{
    ENVFILE="/etc/profile.d/repast.sh"
    echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ABMSHARED/lib:$ABMSHARED/repast_hpc-2.3.0/lib" >> $ENVFILE
    source $ENVFILE

} #-- end of setup_repast_env() --#

echo "*********************************************************"
echo "*                                                       *"
echo "*                  Installing Repast                    *"
echo "*                                                       *"
echo "*********************************************************"
setup_build_tools
# flip to gcc7 environment avoiding forkbomb
# scl enable devtoolset-7 bash
#source /opt/rh/devtoolset-7/enable
#source /opt/intel/mkl/bin/mklvars.sh intel64
#source /opt/intel/impi/2018.4.274/intel64/bin/mpivars.sh
setup_repast_env # boost needs mpi in path
source /etc/profile
module load gcc-8.2.0
module load mpi/impi_2018.4.274
install_boost_mpi
install_repast
