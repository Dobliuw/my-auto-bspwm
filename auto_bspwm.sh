#!/bin/bash
# Att. Dobliuw 2024 very near to 2025
function help(){
	echo -e "\n\n\t[!] Usage: sudo $0\n\n"
	exit 0
}

# Verbose Function
function log(){
	local level=$1
	shift
	echo -e "[$level] $@"
}

# Function to emulate a Spinner
function loading(){
	local pid=$!
	local spin='-\|/'
	local i=0

	while kill -0 $pid 2>/dev/null; do
		i=$(( (i + 1) % 4))
		printf "\r[%b] Waiting to end the task \"$@\"..." "${spin:$i:1}"
		sleep 0.1
	done
	echo -e "\n"
}

# Function to set all needed variables
function set_profile(){
	which=$(command -v which)
	if [ ! $which ]; then
		echo -e "\n\n[!] Command WHICH not found, please install it.\n\n"
		exit 1
	else
		export USER=$($($which whoami))
		export DIR="/tmp/auto_bspwm"
		$($which mkdir) $DIR
		if [ $? -eq 0 ]; then
			log "INFO" "Temp folder created on $DIR."
		fi
	fi
}

function main(){

	if [ "$UID" -ne 0 ]; then
		help
	else
		# Seting variables
		set_profile

		# Updating
		log "INFO" "Updating the system before install dependencies."
		(apt update &>/dev/null) &
		loading "SYSTEM UPDATE"

		# Upgrading
		log "INFO" "Upgrading the system before install dependencies."
		(apt upgrade -y &>/dev/null) &
		loading "SYSTEM UPGRADE"

		# Installing dependencies and tools
		log "INFO" "Installing all dependencies."
		(apt install build-essential git vim xcb libxcb-util0-dev libxcb-ewmh-dev libxcb-randr0-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-xinerama0-dev libasound2-dev libxcb-xtest0-dev libxcb-shape0-dev kitty cmake cmake-data pkg-config python3-sphinx libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev libjsoncpp-dev libmpdclient-dev libuv1-dev libnl-genl-3-dev polybar meson libxext-dev libxcb1-dev libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev libxcb-xinerama0-dev libpixman-1-dev libdbus-1-dev libconfig-dev libgl1-mesa-dev libpcre2-dev libevdev-dev uthash-dev libev-dev libx11-xcb-dev libxcb-glx0-dev rofi zsh imagemagick zsh-autosuggestions zsh-syntax-highlighting feh locate flameshot ranger -y &>/dev/null) &
		loading "DEPENDENCIES INSTALLATION"
	fi
}

main
