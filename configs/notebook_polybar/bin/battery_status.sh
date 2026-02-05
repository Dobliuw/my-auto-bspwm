#!/usr/bin/bash

BAT=$(upower -e | grep 'BAT') 

ICON_COLOR_GOOD="%{F#32CD32}"
ICON_COLOR_MID="%{F#FFA500}"
ICON_COLOR_BAD="%{F#FF0000}"
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
        ICON_COLOR="$ICON_COLOR_GOOD"
    else
        if [ "$PERCENT" -gt 90 ]; then
            ICON="$ICON_FULL"
            ICON_COLOR="$ICON_COLOR_GOOD"
        elif [ "$PERCENT" -gt 55 ]; then
            ICON="$ICON_SEMFULL"
            ICON_COLOR="$ICON_COLOR_GOOD"
        elif [ "$PERCENT" -gt 25 ]; then
            ICON="$ICON_MED"
            ICON_COLOR="$ICON_COLOR_MID"
        else
            ICON="$ICON_LOW"
            ICON_COLOR="$ICON_COLOR_BAD"
        fi
    fi

    echo -e "${ICON_COLOR}${ICON} ${TEXT_COLOR}${PERCENT}%"
}


while true; do
    print_battery
    sleep 1
done
