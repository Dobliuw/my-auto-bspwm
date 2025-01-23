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
		export INSTALLATION_DIR=$($($which pwd))
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
		(apt install build-essential git vim xcb libxcb-util0-dev libxcb-ewmh-dev libxcb-randr0-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-xinerama0-dev libasound2-dev libxcb-xtest0-dev libxcb-shape0-dev kitty cmake cmake-data pkg-config python3-sphinx libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev libjsoncpp-dev libmpdclient-dev libuv1-dev libnl-genl-3-dev polybar meson libxext-dev libxcb1-dev libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev libxcb-xinerama0-dev libpixman-1-dev libdbus-1-dev libconfig-dev libgl1-mesa-dev libpcre2-dev libevdev-dev uthash-dev libev-dev libx11-xcb-dev libxcb-glx0-dev rofi zsh imagemagick zsh-autosuggestions zsh-syntax-highlighting feh locate flameshot ranger bspwm sponge -y &>/dev/null) &
		loading "DEPENDENCIES INSTALLATION"

		/usr/bin/mkdir /home/$USER/.config/{bspwm,shxkd}
		log "INFO" "Creating bspwm and shxkd files configuration"
		cd $DIR

		# BSPWM Configuration
		git clone https://github.com/baskerville/bspwm &>/dev/null
		cd bspwm
		sudo -u $USER make
		/usr/bin/make install 1>/dev/null
		loading "BSPWM Installation"
		/usr/bin/cp -r $INSTALLATION_DIR/configs/bspwm/* /home/$USER/.config/bspwm/
		/usr/bin/cat /home/$USER/.config/bspwm/bspwmrc | sed "s/REPLACEME/$USER/"
		cd ..
		log "INFO" "Initial bspwm configuration did it"

		# SXHKD Configuration
		git clone https://github.com/baskerville/sxhkd
		cd sxhkd
		sudo -u $USER make
		(make install) &
		loading "SHXKD Installation"
		/usr/bin/copy -r $INSTALLATION_DIR/configs/sxhkd/* /home/$USER/.config/sxhkd/
		/usr/bin/cat /home/$USER/.config/sxhkd/sxhkdrc | sed "s/REPLACEME/$USER/"
		cd ..
		log "INFO" "Initial shxkd configuration did it"

		# Polybar Configuration
		git clone --recursive https://github.com/polybar/polybar
		cd polybar
		mkdir build
		cd build
		sudo -u $USER cmake .. 
		sudo -u $USER make -j$(nproc)
		(make install) & 
		loading "Polybar Installation"
		if [ $? -ne 0 ]; then
			apt install polybar -y &>/dev/null
			log "INFO" "The manual polybar installation filed, so we install it from the public repo."
		fi
		cd $DIR
		log "INFO"

		# Picom Configuration
		git clone https://github.com/ibhagwan/picom.git
		cd picom
		git submodule update --init --recursive
		sudo -u $USER meson --buildtype=release . build
		sudo -u $USER ninja -c build
		(ninja -c build install) &
		loading "Picom installation"
		cd ..

		# Rofi configuration
#		git clone https://github.com/VaughnValle/blue-sky.git
#		cd blue-sky
#		/usr/bin/mkdir -p /home/$USER/.config/rofi/themes
#		/usr/bin/cp nord.rasi

		# Font Download and configuration
		wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip
		mv Hack.zip /usr/local/share/fonts
		cd !$
		/usr/bin/unzip Hack.zip
		rm Hack.zip
		log "INFO" "Hack Nerd Font downloaded and installed"


		# Kitty Configuration
		/usr/bin/mkdir /home/$USER/.config/kitty
		/usr/bin/cp -r $INSTALLATION_DIR/configs/kitty/* /home/$USER/.config/kitty
		cd $DIR
		wget https://github.com/kovidgoyal/kitty/releases/download/v0.28.1/kitty-0.28.1-x86_64.txz
		/usr/bin/mkdir /opt/kitty
		tar -xf kitty-0.28.1-x86_64.txz
		mv kitty /opt/kitty/
		cp /home/$USER/.config/kitty/* /root/.config/kitty/
		log "INFO" "Kitty updated and configurated"

		# Polybar configuration
		cd $DIR
		sudo -u $USER mkdir /home/$USER/.config/polybar
		cp -r  $INSTALLATION_DIR/configs/polybar/* /home/$USER/.config/polybar
		cp $INSTALLATION_DIR/configs/polybar/fonts/* /usr/share/fonts/truetype
		fc-cache -v


		# Wallpaper configuration
		sudo -u $USER mkdir /home/$USER/Fondos
		random_number=$(/usr/bin/shuf -i0-9 -n1)
		cp $INSTALLATION_DIR/wallpapers/$(echo kali-linux-wallpaper-v$(/usr/bin/shuf -i1-8 -n1).png) /home/$USER/Fondos/

		# Powerlevel10k Installation
		cd $DIR
		sudo -u $USER git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
		echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
		# Root config
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
		echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
		chown root:root /usr/local/share/zsh/site-functions/_bspc
		usermod --shell /usr/bin/zsh root
		usermod --shell /usr/bin/zsh $USER
		/usr/bin/ln -s -f /home/$USER/.zshrc /root/.zshrc
		/usr/bin/cat $INSTALLATION_DIR/configs/modern_completion_system >> /home/$USER/.zshrc
		log "Powerlevel10k Installation and Configuration"

		# Plugins downloading and installation
		cd /usr/share
		mkdir zsh-sudo
		chown $USER:$USER zsh-sudo
		cd zsh-sudo
		(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh) &
		loading "Downloading sudo plugin"
		chmod +x sudo.plugin.zsh
		echo "if [ -f /usr/share/zsh-sudo/sudo.plugin.zsh ]; then
			source /usr/share/zsh-sudo/sudo.plugin.zsh
		fi" >> ~/.zshrc
		log "Sudo plugin installed"
		cd $DIR
		(wget https://github.com/sharkdp/bat/releases/download/v0.25.0/bat_0.25.0_amd64.deb)&
		loading "Downloading batcat plugin"
		(dpkg -i bat_0.25.0_amd64.deb) &
		loading "Installing batcat plugin"
		(wget https://github.com/lsd-rs/lsd/releases/download/v1.1.5/lsd_1.1.5_amd64.deb) &
		loading "Downloading lsd plugin"
		(dpkg -i lsd_1.1.5_amd64.deb) &
		loading "Installing lsd plugin"
		(apt install locate) &
		updatedb
		# Custom aliases configuration in .zshrc
		echo -e "=== CUSTOM ALIASES ===\n\n# bat\nalias cat='bat'\nalias catn='bat --style=plain'\nalias catnp='bat --style=plain --paging=never'" >> /home/$USER/.zshrc
		echo -e "\n# ls\nalias ll='lsd -lh --group-dirs=first'\nalias la='lsd -a --group-dirs=first'\nalias l='lsd --group-dirs=first'\nalias lla='lsd -lha --group-dirs=first'\nalias ls='lsd --group-dirs=first'" >> /home/$USER/.zshrc


	fi
}

main
