#!/bin/sh
#set -x #echo on

ROOT=/root
SRCBASE=sources
DOWNDIR=downloads
SRCSDIR=$ROOT/$SRCBASE
SRCDOWN=$SRCSDIR/$DOWNDIR
XDIR=/opt/cross/linux
THRDS=$((`nproc`*2))

getSourcesArray() {
    local ret="$(ls -d $1/*)"

    # remove the downloads directory from list
    for d in $ret; do
        if [[ ${ret[d]} == $DOWNDIR ]]; then
            unset 'ret[d]'
        fi
    done

    return ret
}

getDirFromList() {
    for d in $1; do
        if [[ $d == "$2-*" ]]; then
            return $d
        fi
    done
}

echo "Preparing build..."
mkdir -p $XDIR/bin
export PATH=$XDIR/bin:$XDIR:$PATH
mkdir -p $SRCDOWN
cd $SRCDOWN
xargs -a $ROOT/buildenv/default.wget -n 1 -P 4 wget -nv
for f in *.tar*; do tar xf ${f} -C ../; done
SRCS="$(getSourcesArray $SRCSDIR)"

echo "Building binutils"
cd $ROOT
mkdir -p build-binutils
cd build-binutils
$SRCS/$(getDirFromList $SRCS "binutils-")/configure --prefix=$XDIR --target=aarch64-linux --disable-multilib
make -j$THRDS
make install
cd ..

echo "Getting linux headers..."
cd linux-*
make ARCH=arm64 INSTALL_HDR_PATH=$XDIR/aarch64-linux headers_install
cd ..

echo "Building 1st stage gcc..."
mkdir build-gcc
cd build-gcc
$SRCS/gcc-* --prefix=$XDIR --target=aarch64-linux --enable-languages=c,c++ --disable-multilib
make -j$THRDS all-gcc
make install-gcc
cd..


