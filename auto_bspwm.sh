#!/bin/bash
# Att. Dobliuw 2025

# ANSI Colors
RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
BLUE="\e[34m"
RESET="\e[0m"

# Banner of the script
script_title=(
"   _____            __                    ___."
"  /  _  \   __ __ _/  |_   ____           \_ |__    ____________  __  _  __  _____"
" /  /_\  \ |  |  \\    __\ /  _ \   ______  | __ \  /  ___/\____ \ \ \/ \/ / /     \\\\"
"/    |    \|  |  / |  |  (  <_> ) /_____/  | \_\ \ \___ \ |  |_> > \     / |  Y Y  \\\\"
"\____|__  /|____/  |__|   \____/           |___  //____  >|   __/   \/\_/  |__|_|  /"
"        \/                                     \/      \/ |__|                   \/"
)
# Banner function
function banner(){
    echo -e "\n"
    for line in "${script_title[@]}"; do
        echo -e "${YELLOW}$line${RESET}"
        sleep 0.3
    done
    echo -e "\t\t\tBy ${GREEN}Dobliuw${RESET} in ${RED}2025${RESET} ヅ"
    sleep 2
    /usr/bin/clear
}

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
libxcb-glx0-dev rofi zsh imagemagick zsh-autosuggestions zsh-syntax-highlighting libpcre3-dev \
feh locate flameshot ranger bspwm moreutils sxhkd lemonbar xdo jq net-tools curl)

############################################################################################

# Verbose Function
function log() {
    local level=$1
    shift

    case "$level" in
        INFO)
            echo -e "[${BLUE}${level}${RESET}] $@"
            ;;
        WARNING)
            echo -e "[${YELLOW}${level}${RESET}] $@"
            ;;
        IMPORTANT)
            echo -e "[${GREEN}${level}${RESET}] $@"
            ;;
        ERROR)
            echo -e "[${RED}${level}${RESET}] $@" >&2
            ;;
    esac
}

# Function to emulate a Spinner
function loading() {
    local process_name=$1
    local pid=${2:-$!} # If don't recieve a PID will use $! PID
    local spin='-\|/'
    local i=0

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i + 1) % 4))
        printf "\r[${GREEN}%b${RESET}] %s..." "${spin:$i:1}" "$process_name"
        sleep 0.1
    done
    echo -e '\n'
}


# Function to run task like initial user.
function run_as_user() {
    if [[ -n "$stdout_redirection" ]]; then
        sudo -u "$ORIGINAL_USER" /bin/bash -c "$* $stdout_redirection"
    else
        sudo -u "$ORIGINAL_USER" /bin/bash -c "$*"
    fi
}


# Function to set all needed variables
function set_profile() {
    run_as_user "/usr/bin/mkdir -p $DIR"

    if [ $? -eq 0 ]; then
        log "INFO" "Temp folder created on ${YELLOW}$DIR${RESET}."
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
    log "INFO" "Dependencies successfully installed"; sleep 1
}


# Function to fix dependencies.
function fix_dependencies(){
    log "INFO" "Fixing broken dependencies."
    /bin/bash -c "apt --fix-broken install -y $stdout_redirection" &
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
   /bin/bash -c "/usr/bin/make install $stdout_redirection" &
   loading "BSPWM Final installation"
   run_as_user "/usr/bin/mkdir -p /home/$ORIGINAL_USER/.config/bspwm"
   run_as_user "/usr/bin/cp -r $INSTALLATION_DIR/configs/bspwm/* /home/$ORIGINAL_USER/.config/bspwm/"
   run_as_user "/usr/bin/cat /home/$ORIGINAL_USER/.config/bspwm/bspwmrc | /usr/bin/sed \"s/REPLACEME/$ORIGINAL_USER/\" | /usr/bin/sponge /home/$ORIGINAL_USER/.config/bspwm/bspwmrc"
   /usr/bin/chmod +x /home/$ORIGINAL_USER/.config/bspwm/bspwmrc
   log "INFO" "BSPWM configuration completed."
}

# Function to donwload, install and configure SXHKD
function configure_sxhkd(){
    cd $DIR
    run_as_user "/usr/bin/git clone https://github.com/baskerville/sxhkd" &
    loading "Cloning SXHKD repository"
    log "INFO" "SXHKD Repository successfully cloned"
    cd sxhkd
    run_as_user "/usr/bin/make" &
    loading "SXHKD Initial installation"
    /bin/bash -c "/usr/bin/make install $stdout_redirection" &
    loading "SXHKD Final installation"
    run_as_user "/usr/bin/mkdir -p /home/$ORIGINAL_USER/.config/sxhkd"
    run_as_user "/usr/bin/cp -r $INSTALLATION_DIR/configs/sxhkd/* /home/$ORIGINAL_USER/.config/sxhkd/"
    run_as_user "/usr/bin/cat /home/$ORIGINAL_USER/.config/sxhkd/sxhkdrc | /usr/bin/sed "s/REPLACEME/$ORIGINAL_USER/" | /usr/bin/sponge /home/dobliuw/.config/sxhkd/sxhkdrc"
    cd ..
    log "INFO" "SXHKD configuration completed."
}

# Function to download, install and configure POLYBAR
function configure_polybar(){
    cd $DIR
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
    /bin/bash -c "/usr/bin/make install $stdout_redirection" &
    loading "POLYBAR Final installation"
    run_as_user "/usr/bin/cp -r $INSTALLATION_DIR/configs/polybar/* /home/$ORIGINAL_USER/.config/polybar/"
    /usr/bin/cp -r /home/$ORIGINAL_USER/.config/polybar/fonts/* /usr/share/fonts/truetype
    /usr/bin/chmod +x /home/$ORIGINAL_USER/.config/polybar/launch.sh
    /usr/bin/chmod +x /home/$ORIGINAL_USER/.config/polybar/bin/*
    /bin/bash -c "/usr/bin/fc-cache -v $stdout_redirection"
    cd ..
    log "INFO" "Polybar configuration completed."

    # Adding function SETTARGET to modify the target to audit
    target_marker="########## FUNCTION TO SET TARGET TO AUDIT #############"
    if ! /usr/bin/grep -q "$target_marker" /home/$ORIGINAL_USER/.zshrc; then
        echo -e "\n\n$target_marker\nfunction settarget(){\n    ip_address=\$1\n    machine_name=\$2\n    echo $ip_address $machine_name > /home/$ORIGINAL_USER/.config/polybar/bin/target\n}\n" >> /home/$ORIGINAL_USER/.zshrc
    fi
}

# Function to create and set a random kali linux wallpaper.
function configure_wallpaper() {
    log "INFO" "Setting up random wallpaper with feh."
    run_as_user "/usr/bin/mkdir -p /home/$ORIGINAL_USER/Fondos"

    local random_wallpaper=$(echo kali-linux-wallpaper-v$(/usr/bin/shuf -i1-8 -n1).png)
    local wallpaper="$INSTALLATION_DIR/wallpapers/$random_wallpaper"
    local feh=$(/usr/bin/which feh)

    run_as_user "/usr/bin/cp $wallpaper /home/$ORIGINAL_USER/Fondos/FondoDobliuw.png"

    if [[ $? -ne 0 ]]; then
        echo $? && log "ERROR" "Failed to copy wallpaper."
    fi

    run_as_user "$feh --bg-scale /home/$ORIGINAL_USER/Fondos/FondoDobliuw.png"
    log "INFO" "Wallpaper configured successfully."
}

function configure_kitty() {
    log "INFO" "Setting up Kitty terminal emulator."
    run_as_user "/usr/bin/mkdir -p /home/$ORIGINAL_USER/.config/kitty"
    run_as_user "/usr/bin/cp -r $INSTALLATION_DIR/configs/kitty/* /home/$ORIGINAL_USER/.config/kitty"
    log "INFO" "Kitty configuration completed."
    cd /opt && mkdir -p kitty
    cd kitty
    # Install in /opt the latest version.
    # Get the last version
    if [[ ! -d "./bin" ]]; then
        latest_version=$(/usr/bin/curl -s "https://api.github.com/repos/kovidgoyal/kitty/releases/latest" $stdout_redirection | /usr/bin/jq -r .tag_name | /usr/bin/tr -d v)
        log "INFO" "Latest kitty version found: $latest_version"
        sleep 1
        /usr/bin/wget "https://github.com/kovidgoyal/kitty/releases/download/v$latest_version/kitty-$latest_version-x86_64.txz" &>/dev/null # Fixed Ctrl + Z kitty funcionality
        if [[ $? -eq 0 ]]; then
            log "INFO" "Latest kitty version successfully downloaded."
            /usr/bin/tar -xvf kitty-$latest_version-x86_64.txz
            /usr/bin/rm kitty-$latest_version-x86_64.txz
            /usr/bin/chown :$ORIGINAL_USER ./bin/kitty && /usr/bin/chmod 751 ./bin/kitty
            log "INFO" "Kitty version ${YELLOW}$latest_version${RESET} with funcionality fixed installed on /opt/kitty"
            sleep 2
        fi
    else
        log "IMPORTANT" "Folder '${YELLOW}bin${RESET}' was found in ${YELLOW}/opt/kitty${RESET} path, that could be a previous installation, skiping kitty latest version update."
        sleep 2
    fi
}

function configure_powerlevel10k() {
    log "INFO" "Installing and setting up Powerlevel10k."
    sleep 0.5

    if [[ ! -d "/home/$ORIGINAL_USER/powerlevel10k" ]]; then
        run_as_user "/usr/bin/git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$ORIGINAL_USER/powerlevel10k"
    else
        log "IMPORTANT" "Powerlevel10k already installed for ${YELLOW}$ORIGINAL_USER${RESET} user, skiping the installation."
        sleep 2
    fi

    line="source /home/$ORIGINAL_USER/powerlevel10k/powerlevel10k.zsh-theme"
    /usr/bin/cat /home/$ORIGINAL_USER/.zshrc | /usr/bin/grep -q $line || echo "$line" >> /home/$ORIGINAL_USER/.zshrc

    if [[ ! -d "/root/powerlevel10k" ]]; then
        /bin/bash -c "/usr/bin/git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/powerlevel10k $stdout_redirection" &
        loading "Cloning POWERLEVEL10k repository for user ROOT"
        log "INFO" "POWERLEVEL10k Repository successfully cloned"
        sleep 0.5
    else
        log "IMPORTANT" "Powerlevel10k already installed for ${YELLOW}root${RESET} user, skiping the installation"
        sleep 2
    fi

    #run_as_user "/usr/bin/zsh &>/dev/null &"
    #ZSH_PID=$!
    #/usr/bin/zsh &>/dev/null &
    #ZSH_PRIVILEGED_PID=$!
    #/usr/bin/kill $ZSH_PID 2>/dev/null
    #/usr/bin/kill $ZSH_PRIVILEGED_PID 2>/dev/null
    #compaudit

    /usr/bin/cat /root/.zshrc | /usr/bin/grep -q $line || echo "$line" >> /root/.zshrc

    run_as_user "/usr/bin/chown $ORIGINAL_USER:$ORIGINAL_USER -R /home/$ORIGINAL_USER/powerlevel10k"
    log "INFO" "Powerlevel10k installation completed."

    # Complete the installation and fix some issues and error messages.
    /usr/bin/chown root:root /usr/local/share/zsh/site-functions/_bspc

    # Configure zsh shell by default for both users
    /usr/sbin/usermod --shell /usr/bin/zsh root &>/dev/null
    /usr/sbin/usermod --shell /usr/bin/zsh $ORIGINAL_USER &>/dev/null

    # Symbolik link to zshrc between root and the original user that runs the script
    /usr/bin/ln -s -f /home/$ORIGINAL_USER/.zshrc /root/.zshrc

    log "IMPORTANT" "The next time you open de terminal, you will be able to configure your Powerlevel10k"
    sleep 2
}

# Function to install picom
function  configure_picom(){
    cd $DIR
    run_as_user "/usr/bin/git clone --depth=1 https://github.com/ibhagwan/picom.git &>/dev/null" &
    loading "Cloning PICOM repository"
    cd picom
    run_as_user "/usr/bin/git submodule update --init --recursive &>/dev/null" &
    loading "Updating PICOM git submodule"
    run_as_user "/usr/bin/meson --buildtype=release . build &>/dev/null" &
    loading "Doing some makes"
    run_as_user "/usr/bin/ninja -C build &>/dev/null" &
    loading "Doing some ninja stuff xd"
    /usr/bin/ninja -C build install &>/dev/null &
    last_ninja_PID=$!
    loading "This is the last ninja stuff, I swear :D"
    wait $last_ninja_PID

    if [[ "$?" -eq 0 ]]; then
        log "INFO" "PICOM successfully installed"
        sleep 0.5
    else
        log "ERROR" "An error ocurred installing PICOM, try use ${YELLOW}-v${RESET} option"
        sleep 0.5
    fi

    run_as_user "/usr/bin/mkdir -p /home/$ORIGINAL_USER/.config/picom/"
    run_as_user "/usr/bin/cp $INSTALLATION_DIR/configs/picom/picom.conf /home/$ORIGINAL_USER/.config/picom/picom.conf"

    log "INFO" "Setting up Nord theme for ROFI"
    run_as_user "/usr/bin/mkdir -p /home/$ORIGINAL_USER/.config/rofi/"
    cd $DIR
    run_as_user "git clone https://github.com/VaughnValle/blue-sky.git &>/dev/null" & 
    loading "Cloning BLUE-SKY repository to get NORD theme for ROFI."
    run_as_user "/usr/bin/cp ./blue-sky/nord.rasi /home/$ORIGINAL_USER/.config/rofi/config.rasi"

    # Delete another "rofi.theme" entries sin .Xresources
    run_as_user "/usr/bin/sed -i '/rofi.theme/d' /home/$ORIGINAL_USER/.Xresources"

    # Add the correct configuration
    run_as_user "echo 'rofi.theme: /home/$ORIGINAL_USER/.config/rofi/config.rasi' >> /home/$ORIGINAL_USER/.Xresources"

    # Apply the configuration
    run_as_user "/usr/bin/xrdb -merge /home/$ORIGINAL_USER/.Xresources &>/dev/null"
    log "INFO" "Nord theme for ROFI has been successfully installed and set as default."
    sleep 0.5
    log "IMPORTANT" "If you want another theme, you can run the command ${YELLOW}rofi-theme-selector${RESET}, choose your theme and then apply it with ${YELLOW}ALT${RESET} + ${YELLOW}A${RESET}"
    sleep 5
}


# Function to handle the plugin instalation and renaming
function configure_plugins(){

    local marker="############# MODERN COMPLETION SYSTEM #################"

    if /usr/bin/grep -q "$marker" /home/$ORIGINAL_USER/.zshrc; then
        log "INFO" "Modern completion system already in use (Found in ${YELLOW}~/.zshrc${RESET})"
        sleep 1
    else
        cat <<EOF >> /home/$ORIGINAL_USER/.zshrc

$marker
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "\$(dircolors -b)"
zstyle ':completion:*:default' list-colors \${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u \$USER -o pid,%cpu,tty,cputime,cmd'

EOF
        log "INFO" "Modern completion system configured successfully"
        sleep 1
    fi

    # Downloading latest BAT plugin version
    log "INFO" "Checking the latest version of bat plugin..."
    latest_bat_version=$(/usr/bin/curl -s "https://api.github.com/repos/sharkdp/bat/releases/latest" $stdout_redirection | /usr/bin/jq -r .tag_name | /usr/bin/tr -d v)
    sleep 1
    log "INFO" "Latest bat version found: ${YELLOW}$latest_bat_version${RESET}"
    sleep 1
    cd $DIR
    /usr/bin/wget "https://github.com/sharkdp/bat/releases/download/v$latest_bat_version/bat_${latest_bat_version}_amd64.deb" &>/dev/null &
    loading "Downloading latest bat version"
    # Intalling latest BAT plugin version
    /bin/bash -c "/usr/bin/dpkg -i ./bat_$(echo $latest_bat_version)_amd64.deb $stdout_redirection" &
    loading "INFO" "BAT installation with DPKG"

    # Downloading latest LSD plugin version
    log "INFO" "Checking the latest version of lsd plugin..."
    latest_lsd_version=$(/usr/bin/curl -s "https://api.github.com/repos/lsd-rs/lsd/releases/latest" $stdout_redirection | /usr/bin/jq -r .tag_name | /usr/bin/tr -d v)
    sleep 1
    log "INFO" "Latest lsd version found: ${YELLOW}$latest_lsd_version${RESET}"
    sleep 1
    cd $DIR
    /usr/bin/wget "https://github.com/lsd-rs/lsd/releases/download/v$latest_lsd_version/lsd_${latest_lsd_version}_amd64.deb" &>/dev/null &
    loading "Downloading latest lsd version"
    # Installing latest LSD plugin version
    /bin/bash -c "/usr/bin/dpkg -i ./lsd_$(echo $latest_lsd_version)_amd64.deb $stdout_redirection" &
    loading "INFO" "LSD installation with DPKG"

    # Downloading and configuration ZSH-SUDO (ESC + ESC = sudo at the beginning) plugin
    cd /usr/share && /usr/bin/mkdir -p zsh-sudo
    /usr/bin/chown $ORIGINAL_USER:$ORIGINAL_USER zsh-sudo && cd zsh-sudo
    /usr/bin/wget "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh" &>/dev/null &
    loading "Downloading latest zsh-sudo version"
    /usr/bin/chmod +x ./sudo.plugin.zsh

    zsh_sudo_marker="##### ZSH SUDO (ESC + ESC = sudo at the begining) PLUGIN ######"
    if ! /usr/bin/grep -q "$zsh_sudo_marker" /home/$ORIGINAL_USER/.zshrc; then
        echo -e "\n\n$zsh_sudo_marker\nif [ -f /usr/share/zsh-sudo/sudo.plugin.zsh ]; then\n    source /usr/share/zsh-sudo/sudo.plugin.zsh\nfi\n" >> /home/$ORIGINAL_USER/.zshrc
    fi

    # Synchronize system files
    /bin/bash -c "updatedb $stdout_redirection" &
    loading "Synchronizing system files"

    # Configuration of the aliases in the ~/.zshrc
    local aliases_marker="################ CUSTOM ALIASES ####################"

    if ! /usr/bin/grep -q "$aliases_marker" /home/$ORIGINAL_USER/.zshrc; then
        echo -e "\n\n$aliases_marker\n# BAT PLUGIN\nalias cat='bat'\nalias catn='bat --style=plain'\nalias catnp='bat --style=plain --pagin=never'\n\n# LSD PLUGIN\nalias ll='lsd -lh --group-dirs=first'\nalias la='lsd -a --group-dirs=first'\nalias l='lsd --group-dirs=first'\nalias lla='lsd -lha --group-dirs=first'\nalias ls='lsd --group-dirs=first'" >> /home/$ORIGINAL_USER/.zshrc
        log "INFO" "Custom aliases configured successfully"
        sleep 1
    else
        log "INFO" "Custom aliases already added in ${YELLOW}~/.zshrc${RESET}"
        sleep 1
    fi
}


# Function to download Hack Nerd Fonts
function configure_fonts(){

    if [[ ! -f "/usr/local/share/fonts/HackNerdFont-Bold.ttf" ]]; then
        cd $DIR
        latest_font_version=$(/usr/bin/curl -s "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" $stdout_redirection | /usr/bin/jq -r .tag_name | /usr/bin/tr -d v)
        log "INFO" "Latest version of Hack Nerd Fonts found: ${YELLOW}$latest_font_version${RESET}"
        # Download fonts
        /usr/bin/wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v$latest_font_version/Hack.zip" &>/dev/null &
        FONTS_DOWNLOAD_PID=$!
        loading "Downloading Hack nerd fonts"

        wait $FONTS_DOWNLOAD_PID
        if [[ "$?" -eq 0 ]]; then
            /usr/bin/mv Hack.zip /usr/local/share/fonts
            cd /usr/local/share/fonts
            /bin/bash -c "/usr/bin/unzip Hack.zip $stdout_redirection"
            /usr/bin/rm Hack.zip
            log "INFO" "Hack nerd fonts successfully intalled."
            # Update cache
            /bin/bash -c "/usr/bin/fc-cache -v $stdout_redirection"
            log "INFO" "Fonts cache already updated."
        else
            log "WARNING" "Hack nerd fonts can not be installed"
            sleep 1
        fi
    else
        log "WARNING" "Hack nerd fonts already installed, skipping the installation."
        sleep 0.5
    fi
}


function main() {

    if [ "$UID" -ne 0 ]; then
        help
    else

        # Show the banner
        banner

        [[ "$verbose" == "true" ]] && log "IMPORTANT" "VERBOSE MODE: ${GREEN}$verbose${RESET}" || log "IMPORTANT" "VERBOSE MODE: ${RED}$verbose${RESET}"
        sleep 2
        [[ "$verbose" == "true" ]] && export stdout_redirection="" || export stdout_redirection="&>/dev/null"

	# Create work directory
        set_profile

	log "INFO" "Starting with bspwm hacking enviroment configuration for user $ORIGINAL_USER and root."
	sleep 0.5

        # Updating
        log "INFO" "Updating the system before installing dependencies."
        /bin/bash -c "/usr/bin/apt update -y $stdout_redirection" &
        UPDATE_PID=$! # Capture the PID of update
        loading "SYSTEM UPDATE"
	wait $UPDATE_PID # Wait the endo fo background process
	[[ $? -eq 0 ]] && log "INFO" "System successfully updated"; sleep 1


        # Upgrading
        log "INFO" "Upgrading the system before installing dependencies."
        /bin/bash -c "/usr/bin/apt upgrade -y $stdout_redirection" &
	UPGRADE_PID=$! # Capture the PID of upgrade
        loading "SYSTEM UPGRADE"
        wait $UPGRADE_PID # Wait the end of background process
        [[ $? -eq 0 ]] && log "INFO" "System successfully upgraded"; sleep 1

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

        # Plugins Configuration
        configure_plugins

        # Fonts Donwload and Installation
        configure_fonts

        # Picom and Rofi configuration
        configure_picom

        # Aplicate kitty changes for root
        /usr/bin/mkdir -p /root/.config/kitty
        log "INFO" "Root kitty directory created"

        /usr/bin/cp -r /home/$ORIGINAL_USER/.config/kitty/* /root/.config/kitty/
        log "INFO" "Kitty changes applicated for root."

        /usr/bin/rm -rf $DIR
        log "INFO" "${YELLOW}$DIR${RESET} directory already deleted."

	log "INFO" "Happy Hacking ヅ"; sleep 2
	echo -e "\n\n\t${GREEN}[+]${RESET} Enviroment ${GREEN}successfully${RESET} configurated.\n\n\n"
	exit 0
    fi
}

main

#888b.       8     8
#8   8 .d8b. 88b.  8  w  8   8 Yb  db  dP
#8   8 8' .8 8  8  8  8  8b d8  YbdPYbdP
#888P' `Y8P' 88P'  8  8  `Y8P8   YP  YP
