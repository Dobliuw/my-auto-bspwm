#!/bin/bash
# Att. Dobliuw 2025

# Stop execution if critical errors occur.
set -e

# Function to advise user that will be run the script like sudo
function help() {
    echo -e "\n\n\t[!] Usage: sudo $0\n\t -v\t Verbose mode ON.\n\t -h\t Show this help panel.\n\n"
    exit 1
}

# Detect flags introduced by the user.
verbose=false

while getopts "vh" opt; do
    case ${opt} in
        v) verbose=true;; # If option -v is added, verbose = true
        h) help;;
        \?) help;;
    esac
done

################################## GLOBAL VARS ##########################################

# Multiple vars
ORIGINAL_USER=${SUDO_USER}
DIR="/tmp/auto_bspwm"
INSTALLATION_DIR=$(/usr/bin/pwd)
LOGFILE="/var/log/aut_bspwm.log"

# Packages to install
PACKAGES=(build-essential git vim libxcb-util0-dev libxcb-ewmh-dev libxcb-randr0-dev \
libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-xinerama0-dev libasound2-dev \
libxcb-xtest0-dev libxcb-shape0-dev kitty cmake cmake-data pkg-config \
python3-sphinx libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev \
libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev \
libxcb-ewmh-dev libxcb-icccm4-dev libxcb-xkb-dev libxcb-xrm-dev \
libxcb-cursor-dev libasound2-dev libpulse-dev libjsoncpp-dev libmpdclient-dev \
libuv1-dev libnl-genl-3-dev polybar meson libxext-dev libxcb1-dev \
libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-render-util0-dev \
libxcb-render0-dev libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev \
libxcb-xinerama0-dev libpixman-1-dev libdbus-1-dev libconfig-dev \
libgl1-mesa-dev libpcre2-dev libevdev-dev uthash-dev libev-dev libx11-xcb-dev \
libxcb-glx0-dev rofi zsh imagemagick zsh-autosuggestions zsh-syntax-highlighting \
feh locate flameshot ranger bspwm moreutils sxhkd lemonbar xdo jq net-tools curl)

############################################################################################

# Verbose Function
function log() {
    local level=$1
    shift
    echo -e "[$level] $@"
}

# Function to emulate a Spinner
function loading() {
    local process_name=$1
    local pid=${2:-$!} # If don't recieve a PID will use $! PID
    local spin='-\|/'
    local i=0

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i + 1) % 4))
        printf "\r[%b] Waiting to end the task \"%s\"..." "${spin:$i:1}" "$process_name"
        sleep 0.1
    done
    echo -e "\n"
}


# Function to run task like initial user.
function run_as_user() {
    if [[ -n "$stdout_redirection" ]]; then
        sudo -u "$ORIGINAL_USER" bash -c "$* $stdout_redirection"
    else
        sudo -u "$ORIGINAL_USER" bash -c "$*"
    fi
}


# Function to set all needed variables
function set_profile() {
    run_as_user "/usr/bin/mkdir -p $DIR"

    if [ $? -eq 0 ]; then
        log "INFO" "Temp folder created on $DIR."
        sleep 1
    else
        log "ERROR" "Failed to create temp folder."
        exit 1
    fi
}

function install_dependencies(){
    log "INFO" "Installing all dependencies."
    sleep 1
    if [[ "$verbose" == "true" ]]; then 
        apt install -y ${PACKAGES[@]} &
    else
        apt install -y ${PACKAGES[@]} &>/dev/null &
    fi
    INSTALL_PID=$!
    loading "DEPENDENCIES INSTALLATION" "INSTALL_PID"

    wait $INSTALL_PID
    if [ $? -ne 0 ]; then
        log "WARNING" "Unfulfilled dependencies were detected."
        sleep 0.5
        fix_dependencies
        log "INFO" "Retrying dependencies installation."
        sleep 1
	if [[ "$verbose" == "true" ]]; then 
            apt install -y ${PACKAGES[@]} &
        else
            apt install -y ${PACKAGES[@]} &>/dev/null &
        fi
        RETRY_PID=$!
        loading "RETRYING DEPENDENCIES INSTALLATION" "$RETRY_PID"

        wait $RETRY_PID
        [[ $? -ne 0 ]] && log "ERROR" "The installation of some packages failed."; exit 1
    fi
    log "INFO" "Dependencies successfully installed"; echo -e "\n"; sleep 2
}


# Function to fix dependencies.
function fix_dependencies(){
    log "INFO" "Fixing broken dependencies."
    bash -c "apt --fix-broken install -y $stdout_redirection" &
    FIX_PID=$!
    loading "FIXING BROKEN PACKAGES" "$FIX_PID"

    wait $FIX_PID
    if [ "$?" -ne 0 ]; then
        log "ERROR" "Dependencies could not be fixed"
        exit 1
    fi
    log "INFO" "Dependencies succesfully fixed"; sleep 2
}

# Function to download, install and configure BSPWM
function configure_bspwm(){
   cd $DIR
   run_as_user "/usr/bin/git clone --depth=1 https://github.com/baskerville/bspwm" &
   loading "Cloning BSPWM repository"
   log "INFO" "BSPWM Repository successfully cloned"
   cd bspwm
   run_as_user "/usr/bin/make" &
   loading "BSPWM Initial installation"
   bash -c "/usr/bin/make install $stdout_redirection" &
   loading "BSPWM Final installation"
   run_as_user "/usr/bin/mkdir -p /home/$ORIGINAL_USER/.config/bspwm"
   run_as_user "/usr/bin/cp -r $INSTALLATION_DIR/configs/bspwm/* /home/$ORIGINAL_USER/.config/bspwm/"
   run_as_user "/usr/bin/sed -i \"s/REPLACEME/$ORIGINAL_USER/\" /home/$ORIGINAL_USER/.config/bspwm/bspwmrc | /usr/bin/sponge /home/$ORIGINAL_USER/.config/bspwm/bspwmrc"
   log "INFO" "BSPWM configuration completed."
}

# Function to donwload, install and configure SXHKD
function configure_sxhkd(){
    cd "$DIR"
    run_as_user "/usr/bin/git clone https://github.com/baskerville/sxhkd" &
    loading "Cloning SXHKD repository"
    log "INFO" "SXHKD Repository successfully cloned"
    cd sxhkd
    run_as_user "/usr/bin/make" &
    loading "SXHKD Initial installation"
    bash -c "/usr/bin/make install $stdout_redirection" &
    loading "SXHKD Final installation"
    run_as_user "/usr/bin/mkdir -p /home/$ORIGINAL_USER/.config/sxhkd"
    run_as_user "/usr/bin/cp -r $INSTALLATION_DIR/configs/sxhkd/* /home/$ORIGINAL_USER/.config/sxhkd/"
    run_as_user "/usr/bin/sed -i \"s/REPLACEME/$ORIGINAL_USER/\" /home/$ORIGINAL_USER/.config/sxhkd/sxhkdrc | /usr/bin/sponge /home/$ORIGINAL_USER/.config/sxhkd/sxhkdrc"
    cd ..
    log "INFO" "SXHKD configuration completed."
}

# Function to download, install and configure POLYBAR
function configure_polybar(){
    run_as_user "/usr/bin/git clone --recursive https://github.com/polybar/polybar" &
    loading "Cloning POLYBAR repository"
    log "INFO" "POLYBAR Repository successfully cloned"
    cd polybar
    run_as_user "/usr/bin/mkdir build" &
    loading "POLYBAR Initial installation"
    cd build
    run_as_user "/usr/bin/cmake .."
    run_as_user "/usr/bin/make -j$(/usr/bin/nproc)" &
    loading "Runing some makes"
    run_as_user "/usr/bin/mkdir -p /home/$ORIGINAL_USER/.config/polybar"
    bash -c "/usr/bin/make install $stdout_redirection" &
    loading "POLYBAR Final installation"
    run_as_user "/usr/bin/cp -r $INSTALLATION_DIR/configs/polybar/* /home/$ORIGINAL_USER/.config/polybar/"
    /usr/bin/cp -r /home/$ORIGINAL_USER/.config/polybar/fonts/* /usr/share/fonts/truetype
    bash -c "/usr/bin/fc-cache -v $stdout_redirection"
    cd ..
     log "INFO" "Polybar configuration completed."
}

# Function to create and set a random kali linux wallpaper.
function configure_wallpaper() {
    log "INFO" "Configuring random wallpaper with feh."
    run_as_user "/usr/bin/mkdir -p /home/$ORIGINAL_USER/Fondos"

    local random_wallpaper=$(echo kali-linux-wallpaper-v$(/usr/bin/shuf -i1-8 -n1).png)
    local wallpaper="$INSTALLATION_DIR/wallpapers/$random_wallpaper"
    local feh=$(/usr/bin/which feh)

    echo $wallpaper
    run_as_user "/usr/bin/cp $wallpaper /home/$ORIGINAL_USER/Fondos/FondoDobliuw.png"

    if [[ $? -ne 0 ]]; then
        echo $? && log "ERROR" "Failed to copy wallpaper."
    fi

    run_as_user "$feh --bg-scale /home/$ORIGINAL_USER/Fondos/FondoDobliuw.png"
    log "INFO" "Wallpaper configured successfully."
}

function configure_kitty() {
    log "INFO" "Configuring Kitty terminal emulator."
    run_as_user "/usr/bin/mkdir -p /home/$ORIGINAL_USER/.config/kitty"
    run_as_user "/usr/bin/cp -r $INSTALLATION_DIR/configs/kitty/* /home/$ORIGINAL_USER/.config/kitty"
    log "INFO" "Kitty configuration completed."
    cd /opt && mkdir -p kitty
    cd kitty
    # Install in /opt the latest version.
    # Get the last version
    if [[ ! -d "./bin" ]]; then
        latest_version=$(/usr/bin/curl -s https://api.github.com/repos/kovidgoyal/kitty/releases/latest $stdout_redirection | /usr/bin/jq -r .tag_name | /usr/bin/tr -d v)
        log "INFO" "Latest kitty version found: $latest_version"
        sleep 1
        /usr/bin/wget https://github.com/kovidgoyal/kitty/releases/download/v$latest_version/kitty-$latest_version-x86_64.txz $stdout_redirection # Fixed Ctrl + Z kitty funcionality
        [[ $? -eq 0 ]] && log "INFO" "Latest kitty version successfully downloaded."
        /usr/bin/tar -xvf kitty-$latest_version-x86_64.txz
        /usr/bin/rm kitty-$latest_version-x86_64.txz
        chown :$ORIGINAL_USER ./bin/kitty && chmod 751 ./bin/kitty
        log "INFO" "Kitty version $latest_version with funcionality fixed installed on /opt/kitty"
        sleep 2
    else
        log "IMPORTANT" "Folder 'bin' was found in /opt/kitty path, that could be a previous installation, skiping kitty latest version update."
        sleep 2
    fi
}

function configure_powerlevel10k() {
    log "INFO" "Installing and configuring Powerlevel10k."
    sleep 0.5
    if [[ ! -d "/home/$ORIGINAL_USER/powerlevel10k" ]]; then
        run_as_user "/usr/bin/git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$ORIGINAL_USER/powerlevel10k"
    else
        log "IMPORTANT" "Powerlevel10k already installed for $ORIGINAL_USER user, skiping the installation."
        sleep 2
    fi
    line="source ~/powerlevel10k/powerlevel10k.zsh-theme"
    /usr/bin/cat /home/$ORIGINAL_USER/.zshrc | /usr/bin/grep $line || echo "$line" >> /home/$ORIGINAL_USER/.zshrc

    if [[ ! -d "/root/powerlevel10k" ]]; then
        bash -c "/usr/bin/git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/powerlevel10k $stdout_redirection" &
        loading "Cloning POWERLEVEL10k repository for user ROOT"
        log "INFO" "POWERLEVEL10k Repository successfully cloned"
        sleep 0.5
    else
        log "IMPORTANT" "Powerlevel10k already installed for root user, skiping the installation"
        sleep 2
    fi
    /usr/bin/cat /root/.zshrc | /usr/bin/grep $line || echo "$line" >> /root/.zshrc
    
    run_as_user "chown $ORIGINAL_USER:$ORIGINAL_USER -R /home/$ORIGINAL_USER/powerlevel10k"
    log "INFO" "Powerlevel10k installation completed."
    log "IMPORTANT" "The next time you open de terminal, you will be able to configure your Powerlevel10k"
    sleep 2
}

function main() {

    if [ "$UID" -ne 0 ]; then
        help
    else

        log "IMPORTANT" "VERBOSE MODE: $verbose"
        sleep 2
        [[ "$verbose" == "true" ]] && export stdout_redirection="" || export stdout_redirection="&>/dev/null"

	# Create work directory
        set_profile

	log "INFO" "We\'ll configurate the bspwm hacking enviroment for user $ORIGINAL_USER."
	sleep 0.5

        # Updating
        log "INFO" "Updating the system before installing dependencies."
        bash -c "/usr/bin/apt update -y $stdout_redirection" &
        UPDATE_PID=$! # Capture the PID of update
        loading "SYSTEM UPDATE"
	wait $UPDATE_PID # Wait the endo fo background process
	[[ $? -eq 0 ]] && log "INFO" "System successfully updated"; echo -e "\n"; sleep 2


        # Upgrading
        log "INFO" "Upgrading the system before installing dependencies."
        bash -c "/usr/bin/apt upgrade -y $stdout_redirection" &
	UPGRADE_PID=$! # Capture the PID of upgrade
        loading "SYSTEM UPGRADE"
        wait $UPGRADE_PID # Wait the end of background process
        [[ $? -eq 0 ]] && log "INFO" "System successfully upgraded"; echo -e "\n"; sleep 2

        # Installing dependencies and tools
        install_dependencies

        # BSPWM Configuration
        configure_bspwm

        # SXHKD Configuration
        configure_sxhkd

        # Polybar Configuration
        configure_polybar

        # Wallpaper Configuration
        configure_wallpaper

        # Kitty Configuration
        configure_kitty

        # Powerlevel10k Configuration
        configure_powerlevel10k

	log "INFO" "Happy Hacking ヅ"; sleep 2
	echo -e "\n\n\t[+] Enviroment successfully configurated.\n\n\n"
	exit 0
    fi
}

main

