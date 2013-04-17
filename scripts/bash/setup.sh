#!/bin/bash

# General setup of mor1kx

# First see if we need to install the mor1kx
$PWD/scripts/bash/setup_mor1kx.sh

# Now create the "out" dirs in each of the sim directories

echo "Creating empty directories for simulation results"
run_dirs=`find . -type d -name "run" | grep "sim/run"`
for run_dir in $run_dirs; do
    if [ ! -d $run_dir/../out ]; then
	mkdir $run_dir/../out;
    fi
done

