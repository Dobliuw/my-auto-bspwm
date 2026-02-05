#!/usr/bin/bash

BAT=$(upower -e | grep 'BAT') 

ICON_COLOR="%{F#32CD32}"
TEXT_COLOR="%{F#FFFFFF}"

ICON_FULL="" #"<U+F0240>"
ICON_SEMFULL="" #"<U+F0241>"
ICON_MED="" #"<U+F0242>"
ICON_LOW="" #"<U+F0243>"
ICON_EMPTY="" #"<U+F0244>"

ICONS=("$ICON_EMPTY" "$ICON_LOW" "$ICON_MED" "$ICON_SEMFULL" "$ICON_FULL")


print_battery(){

    PERCENT=$(upower -i "$BAT" | awk '/percentage/ {gsub("%",""); print $2}')
    STATE=$(upower -i "$BAT" | awk '/state/ {print $2}')

    if [ "$STATE" = "charging" ]; then
        INDEX=$(( $(date +%s) % ${#ICONS[@]} ))
        ICON="${ICONS[$INDEX]}"
    else
        if [ "$PERCENT" -gt 90 ]; then
            ICON="$ICON_FULL"
        elif [ "$PERCENT" -gt 55 ]; then
            ICON="$ICON_SEMFULL"
        elif [ "$PERCENT" -gt 25 ]; then
            ICON="$ICON_MED"
        else
            ICON="$ICON_LOW"
        fi
    fi

    echo -e "${ICON_COLOR}${ICON} ${TEXT_COLOR}${PERCENT}%"
}


while true; do
    print_battery
    sleep 1
done
