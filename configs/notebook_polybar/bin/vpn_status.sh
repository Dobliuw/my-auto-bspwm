#!/bin/bash

while true; do

    nordvpn=$(/usr/sbin/ifconfig | /usr/bin/grep -i "nordlynx")

    if [ "$nordvpn" ]; then
        if [ ! "$ip" ]; then
            ip=$(curl -s https://ipinfo.io | grep -i "\"ip\"" | awk '{print $2}' | tr -d "\"" | tr -d ",")
        fi
    else
        ip=$(/usr/sbin/ifconfig | /usr/bin/grep -C 1 -E "tun0|nordlynx" | /usr/bin/tail -n 1 | /usr/bin/awk '{print $2}')
    fi
    echo $ip $nordvpn
    [[ $ip ]] && echo "%{F#09d304}󱛇 $ip%{F#ffffff}" || echo "%{F#d93753}󱛇 Disconnected.%{F#ffffff}"

done
