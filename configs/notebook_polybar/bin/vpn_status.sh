#!/bin/bash

last_state=""
ip=1

while true; do

    # En vez de guardar texto, guardamos el exit status (0 o 1)
    /usr/sbin/ifconfig | /usr/bin/grep -qi "nordlynx"
    nordvpn=$?

    /usr/sbin/ifconfig | /usr/bin/grep -qi "tun0"
    other_vpn=$?

    if [ "$nordvpn" -eq 0 ] || [ "$other_vpn" -eq 0 ]; then
        current_state="connected"
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
    fi

    if [ "$ip" != "1" ]; then
        echo "%{F#09d304}󱛇 $ip%{F#ffffff}"
    else
        echo "%{F#d93753}󱛇 Disconnected.%{F#ffffff}"
    fi

    sleep 10
done
