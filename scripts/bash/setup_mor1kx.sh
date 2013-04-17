#!/bin/bash

# This is a script to "install" the mor1kx core for the first time.

# Must run this in the root of mor1kx-dev-env
if [ `basename $PWD` != "mor1kx-dev-env" ] ; then 
    echo "Please run this from the root of mor1kx";
    echo "eg. ./scripts/bash/setup_mor1kx.sh"
    exit 1
fi

which git

if [ $? -ne 0 ]; then
    echo "You need git installed to download the mor1kx from github"
    exit 1
fi

if [ -e rtl/verilog/mor1kx ]; then
    echo "You already have an mor1kx directory - not going to write over it"
    exit 1
fi

git clone http://github.com/openrisc/mor1kx.git rtl/verilog/mor1kx-github
ln -s $PWD/rtl/verilog/mor1kx-github/rtl/verilog rtl/verilog/mor1kx


#Now link in the mor1kx include files
includes=`find . -type d -name "include" | grep "rtl/verilog/include"`

for incdir in $includes; do

    if [ -L $incdir/mor1kx-sprs.v ]; then
	unlink $incdir/mor1kx-sprs.v
    fi
    ln -s $PWD/rtl/verilog/mor1kx/mor1kx-sprs.v $incdir/mor1kx-sprs.v
    if [ -L $incdir/mor1kx-defines.v ]; then
	unlink $incdir/mor1kx-defines.v
    fi
    ln -s $PWD/rtl/verilog/mor1kx/mor1kx-defines.v $incdir/mor1kx-defines.v

done
    
echo "mor1kx core set up"
exit 0
