#!/usr/bin/env bash

# Get current layout
current_layout=$(hyprctl getoption general:layout -j | jq -r '.str')

# Toggle between hy3 (tiling) and dwindle (Windows-like)
if [ "$current_layout" = "hy3" ]; then
    # Switch to dwindle layout (more Windows-like)
    hyprctl keyword general:layout dwindle

    # Make all current windows floating (like Windows OS)
    hyprctl clients -j | jq -r '.[].address' | while read -r addr; do
        hyprctl dispatch togglefloating address:$addr
    done
else
    # Switch back to hy3 tiling layout
    hyprctl keyword general:layout hy3

    # Make all windows tiling again
    hyprctl clients -j | jq -r '.[] | select(.floating == true) | .address' | while read -r addr; do
        hyprctl dispatch togglefloating address:$addr
    done
fi
