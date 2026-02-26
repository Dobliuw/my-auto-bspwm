#!/bin/bash

last_state=""
ip=1
vpn_country=""

while true; do

    /usr/sbin/ifconfig | /usr/bin/grep -qi "nordlynx"
    nordvpn=$?

    /usr/sbin/ifconfig | /usr/bin/grep -qi "tun0"
    other_vpn=$?

    if [ "$nordvpn" -eq 0 ] || [ "$other_vpn" -eq 0 ]; then
        current_state="connected"
	vpn_country2=$(/usr/bin/nordvpn status | /usr/bin/grep -i country | /usr/bin/sed 's/Country://')
	if [ "$nordvpn" ] && [ "$vpn_country" != "$vpn_country2" ]; then
            ip=$(curl -s https://api.ipify.org)
	fi
    else
        current_state="disconnected"
    fi

    if [ "$current_state" != "$last_state" ]; then

        if [ "$nordvpn" -eq 0 ]; then

            if [ "$current_state" = "connected" ]; then
                ip=$(curl -s https://api.ipify.org)
            else
                ip=1
            fi

        elif [ "$other_vpn" -eq 0 ]; then

            if [ "$current_state" = "connected" ]; then
                ip=$(/usr/sbin/ifconfig | /usr/bin/grep -A1 "tun0" | /usr/bin/tail -n1 | /usr/bin/awk '{print $2}')
            else
                ip=1
            fi

        else
            ip=1
        fi

        last_state="$current_state"
	vpn_country=$(/usr/bin/nordvpn status | /usr/bin/grep -i country | /usr/bin/sed 's/Country://')
    fi

    if [ "$ip" != "1" ]; then
        echo "%{F#09d304}󱛇 $ip%{F#ffffff}"
    else
        echo "%{F#d93753}󱛇 Disconnected.%{F#ffffff}"
    fi

    sleep 10
done
