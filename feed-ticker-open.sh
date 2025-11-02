#!/bin/bash

# Click handler for feed ticker - opens the current article URL

URL_FILE="$HOME/.cache/waybar-feed-current-url"

# Read the stored URL
if [[ -f "$URL_FILE" ]]; then
    url=$(cat "$URL_FILE")
    if [[ -n "$url" ]]; then
        xdg-open "$url"
    else
        # Fallback to main feed page
        xdg-open "https://feed.internetuniverse.org"
    fi
else
    # Fallback to main feed page
    xdg-open "https://feed.internetuniverse.org"
fi
