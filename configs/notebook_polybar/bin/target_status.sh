#!/bin/bash

ip=$(/usr/bin/cat ~/.config/polybar/bin/target | /usr/bin/awk '{print $1}')
name=$(/usr/bin/cat ~/.config/polybar/bin/target | /usr/bin/awk '{print $2}')

[[ $ip ]] && echo "%{F#d93753}󰓾%{F#ffffff} $ip - $name" || echo "%{F#d93753}󰓾 NO TARGET%{F#ffffff}"
