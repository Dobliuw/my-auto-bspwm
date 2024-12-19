#!/bin/bash

echo -e "%{F#2495e7}󰈀 %{F#ffffff}$(/usr/bin/hostname -I | /usr/bin/awk '{print $1}')"
