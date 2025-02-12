#! /bin/bash

source "Projects/common.sh"

while true; do
	peta_printPrompt "-ALINX COMPRESSION-"
	read response_main

	if [[ "$response_main" == *"1"* ]]; then
		echo "---------------Synthesize projects-----------------"
		ALINX_HW=$(dirname "$HDL_PROJECT")
		cd "$ALINX_HW"
		HDL_PROJECT_NAME=$(basename "$HDL_PROJECT")
		# cp "$ALINX_PROJECTS/course_s2/15_pl_net/vivado/pl_net.xpr" "./$HDL_PROJECT_NAME.xpr"
		# cp -r "$ALINX_PROJECTS/course_s2/15_pl_net/vivado/pl_net.srcs" "./$HDL_PROJECT_NAME.srcs"
		# rsync -av --exclude='sim_scripts' "$ALINX_PROJECTS/course_s2/15_pl_net/vivado/pl_net.ip_user_files" .
		# find . -type f -exec sed -i "s/pl_net/compressor/g" {} +

		# Set Vivado environment (assuming it's installed)
		source "$XILINX_INSTALL_DIR/settings64.sh"

		# Run the TCL script in Vivado batch mode
		vivado -mode batch -source "$PETALINUX_DIR/Scripts/Projects/compressor.tcl" -log "/home/esi/Projects/alinx_hw/log/vivado.log" -journal "/home/esi/Projects/alinx_hw/log/vivado.jou"

		# export PATH="$PATH:$XILINX_INSTALL_DIR/bin"
		# make
	fi
	
	if [[ "$response_main" == *"2"* ]]; then
		echo "------------Create Petalinux project---------------"
		cd "$PETALINUX_INSTALL_DIR"
		source settings.sh
		peta_createPetalinux "ALINX COMPRESSION" "192.168.75.194" "00:0A:35:00:00:00" "192.168.75.1"
	fi
	
	if [[ "$response_main" == *"0"* ]]; then
		break
	fi
done
