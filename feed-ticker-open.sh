#!/bin/bash

# Click handler for feed ticker - opens the current article URL
# Reads from cache file format: headline|||url

URL_FILE="$HOME/.cache/waybar-feed-current-url"

# Add small delay to ensure we get the stable URL
sleep 0.2

# Temporarily disable cursor warping to prevent cursor jump
hyprctl keyword cursor:no_warps true >/dev/null 2>&1

# Read the stored data
if [[ -f "$URL_FILE" ]]; then
    data=$(cat "$URL_FILE")
    if [[ -n "$data" && "$data" == *"|||"* ]]; then
        # Extract URL (everything after |||)
        url="${data#*|||}"
        if [[ -n "$url" ]]; then
            nohup xdg-open "$url" >/dev/null 2>&1 &
        else
            nohup xdg-open "https://feed.internetuniverse.org" >/dev/null 2>&1 &
        fi
    else
        # Fallback to main feed page
        nohup xdg-open "https://feed.internetuniverse.org" >/dev/null 2>&1 &
    fi
else
    # Fallback to main feed page
    nohup xdg-open "https://feed.internetuniverse.org" >/dev/null 2>&1 &
fi

# Wait for browser to open, then re-enable cursor warping
sleep 0.3
hyprctl keyword cursor:no_warps false >/dev/null 2>&1
