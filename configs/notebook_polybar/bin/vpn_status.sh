#!/bin/bash

ip=$(/usr/sbin/ifconfig | /usr/bin/grep -C 1 tun0 | /usr/bin/tail -n 1 | /usr/bin/awk '{print $2}')

[[ $ip ]] && echo "%{F#09d304}󱛇 $ip%{F#ffffff}" || echo "%{F#d93753}󱛇 Disconnected.%{F#ffffff}"
