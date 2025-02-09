#! /bin/bash

CURRENT_DIR=$(pwd)
source setup_variables.sh

echo "------------------Choose Project-------------------"
echo "1 - ALINX COMPRESSION"
#echo "2 - ???"
#echo "3 - ???"
echo "---------------------------------------------------"
read response
if [ "$response" = "1" ]; then
	export PETALINUX_PROJECT="alinx"
	Projects/alinx.sh
fi
cd "$CURRENT_DIR"
