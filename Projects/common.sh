#! /bin/bash

function peta_printPrompt()
{
	echo "------------------$1---------------------"
	echo "1 - synthesize projects"
	echo "2 - Create Petalinux project"
	echo "0 - Exit"
	echo "---------------------------------------------------"
}

function peta_createPetalinux()
{
	printf "Enter Petalinux project name?[$PETALINUX_PROJECT]: "
	read response

	if [ -n "$response" ]; then
		PETALINUX_PROJECT="$response"
	fi
	
	printf "Add support for offline build?[y/N]: "
	read response_offline

	printf "Need any modification in petalinux-config?(if no, continues with silent config)[y/N]: "
	read response_silentconfig

	printf "Config Dynamic ip for PetaLinux?[y/N]: "
	read response_dynamic_ip
	
	cd "$PETALINUX_DIR/Projects"
	petalinux-create --type project --template zynqMP --name $PETALINUX_PROJECT
	
	cd "$PETALINUX_PROJECT"
	if [ "$response_silentconfig" = "y" ]; then
		petalinux-config --get-hw-description="$HDL_PROJECT/vivado"
	else
		petalinux-config --selentconfig --get-hw-description="$HDL_PROJECT/vivado"
	fi
	
	# Add support for offline build
	CONFIG_FILE="$PETALINUX_DIR/Projects/$PETALINUX_PROJECT/project-spec/configs/config"
	if [ "$response_offline" = "y" ]; then
		WRITE_LN=$(grep -i -n 'CONFIG_PRE_MIRROR_URL=' "$CONFIG_FILE" | awk -F : '{printf $1}')
		sed -i "$WRITE_LN"'c\CONFIG_PRE_MIRROR_URL="file://'"$PETALINUX_DIR"'/Mirror/downloads"' "$CONFIG_FILE"
		WRITE_LN=$(grep -i -n 'CONFIG_YOCTO_LOCAL_SSTATE_FEEDS_URL=' "$CONFIG_FILE" | awk -F : '{printf $1}')
		sed -i "$WRITE_LN"'c\CONFIG_YOCTO_LOCAL_SSTATE_FEEDS_URL="file://'"$PETALINUX_DIR"'/Mirror/aarch64"' "$CONFIG_FILE"
		WRITE_LN=$(grep -i -n 'CONFIG_YOCTO_NETWORK_SSTATE_FEEDS=y' "$CONFIG_FILE" | awk -F : '{printf $1}')
		WRITE_LN=$(($WRITE_LN+1))
		END_LN=$(($WRITE_LN+4))
		sed -i "$WRITE_LN,$END_LN"'d' "$CONFIG_FILE"
		sed -i 's/CONFIG_YOCTO_NETWORK_SSTATE_FEEDS=y/# CONFIG_YOCTO_NETWORK_SSTATE_FEEDS is not set/' "$CONFIG_FILE"
		sed -i 's/# CONFIG_YOCTO_BB_NO_NETWORK is not set/CONFIG_YOCTO_BB_NO_NETWORK=y/' "$CONFIG_FILE"
	fi
	
	# Boot args
	WRITE_LN=$(grep -i -n 'CONFIG_SUBSYSTEM_BOOTARGS_GENERATED=" earlycon console=ttyPS0,115200 clk_ignore_unused root=/dev/ram0 rw"' "$CONFIG_FILE" | awk -F : '{printf $1}')
	sed -i "$WRITE_LN"'d' "$CONFIG_FILE"
	WRITE_LN=$(grep -i -n 'CONFIG_SUBSYSTEM_EXTRA_BOOTARGS=""' "$CONFIG_FILE" | awk -F : '{printf $1}')
	sed -i "$WRITE_LN"'iCONFIG_SUBSYSTEM_BOOTARGS_GENERATED=" earlycon console=ttyPS0,115200 clk_ignore_unused root=/dev/ram0 rw"' "$CONFIG_FILE"

	# SD and USB configs
	DEVICE_TREE="$PETALINUX_DIR/Projects/$PETALINUX_PROJECT/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi"
	CHECK_PRE=$(grep 'sdhci1' "$DEVICE_TREE")
	if [ -z "$CHECK_PRE" ]; then
		echo >> "$DEVICE_TREE"
		echo "/* SD */" >> "$DEVICE_TREE"
		echo >> "$DEVICE_TREE"
		echo "&sdhci1 {" >> "$DEVICE_TREE"
		echo -e "\tdisable-wp;" >> "$DEVICE_TREE"
		echo -e "\tno-1-8-v;" >> "$DEVICE_TREE"
		echo >> "$DEVICE_TREE"
		echo "};" >> "$DEVICE_TREE"
		echo >> "$DEVICE_TREE"
		echo "/* USB  */" >> "$DEVICE_TREE"
		echo >> "$DEVICE_TREE"
		echo "&dwc3_0 {" >> "$DEVICE_TREE"
		echo -e '\tstatus = "okay";'>> "$DEVICE_TREE"
		echo -e '\tdr_mode = "host";' >> "$DEVICE_TREE"
		echo "};" >> "$DEVICE_TREE"
	fi

	# Auto login config
	ROOTFS="$PETALINUX_DIR/Projects/$PETALINUX_PROJECT/project-spec/configs/rootfs_config"
	CHECK_PRE=$(grep 'CONFIG_auto-login=y' "$ROOTFS")
	if [ -z "$CHECK_PRE" ]; then
		sed -i 's/# CONFIG_auto-login is not set/CONFIG_auto-login=y/' "$ROOTFS"
		sed -i 's/# CONFIG_imagefeature-debug-tweaks is not set/CONFIG_imagefeature-debug-tweaks=y/' "$ROOTFS"
	fi

	# Static IP and MAC address
	sed -i 's/CONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_MAC="ff:ff:ff:ff:ff:ff"/CONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_MAC="'"$3"'"/' "$CONFIG_FILE"
	if [ "$response_dynamic_ip" = "y" ]; then
		sed -i 's/# CONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_USE_DHCP is not set/CONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_USE_DHCP=y/' "$CONFIG_FILE"
	else
		WRITE_LN=$(grep -i -n 'CONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_USE_DHCP=y' "$CONFIG_FILE" | awk -F : '{printf $1}')
		WRITE_LN=$(($WRITE_LN+1))
		sed -i "$WRITE_LN"'iCONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_IP_ADDRESS="'"$2"'"' "$CONFIG_FILE"
		WRITE_LN=$(($WRITE_LN+1))
		sed -i "$WRITE_LN"'iCONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_IP_NETMASK="255.255.255.0"' "$CONFIG_FILE"
		WRITE_LN=$(($WRITE_LN+1))
		sed -i "$WRITE_LN"'iCONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_IP_GATEWAY="'"$4"'"' "$CONFIG_FILE"
		sed -i 's/CONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_USE_DHCP=y/# CONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_USE_DHCP is not set/' "$CONFIG_FILE"
	fi

	cd "$PETALINUX_DIR/Projects/$PETALINUX_PROJECT"
	
	# petalinux-config --silentconfig
	petalinux-build
}

