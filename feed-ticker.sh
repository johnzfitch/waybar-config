#!/bin/bash

# Simplified feed ticker for waybar
# Fetches recent headlines directly from FreshRSS API

URL_FILE="$HOME/.cache/waybar-feed-current-url"
BAR_HEIGHT=50

# Get auth token
AUTH_TOKEN="${FRESHRSS_AUTH_TOKEN:-}"
if [[ -z "$AUTH_TOKEN" ]]; then
    echo '{"text": "⚠ FRESHRSS_AUTH_TOKEN not set", "class": "error"}'
    exit 1
fi

# Check if cursor is hovering over waybar
is_cursor_over_bar() {
    local pos=$(hyprctl cursorpos 2>/dev/null)
    if [[ -n "$pos" ]]; then
        local y=$(echo "$pos" | cut -d',' -f2 | tr -d ' ')
        [[ "$y" -lt "$BAR_HEIGHT" ]]
    else
        return 1
    fi
}

# If hovering, just output cached headline and pause (don't fetch new data)
if is_cursor_over_bar; then
    if [[ -f "$URL_FILE" ]]; then
        cached_data=$(cat "$URL_FILE")
        if [[ -n "$cached_data" && "$cached_data" == *"|||"* ]]; then
            # Extract headline (everything before |||)
            cached_headline="${cached_data%|||*}"
            jq -nc --arg text "$cached_headline" --arg class "ticker" '{text: $text, class: $class}'
        else
            echo '{"text": "⟳ Loading...", "class": "loading"}'
        fi
    else
        echo '{"text": "⟳ Loading...", "class": "loading"}'
    fi

    # Stay paused while hovering
    while is_cursor_over_bar; do
        sleep 1
    done
    exit 0
fi

# Build API URL - get recent headlines from last 12 hours
HOURS_AGO_12=$(( $(date +%s) - (12 * 60 * 60) ))
FEED_URL="https://feed.internetuniverse.org/p/api/greader.php/reader/api/0/stream/contents/reading-list?n=100&ot=${HOURS_AGO_12}&output=json"

# Fetch and parse feed
response=$(curl -s -f "$FEED_URL" -H "Authorization: GoogleLogin auth=$AUTH_TOKEN" 2>/dev/null)

if [[ -z "$response" ]]; then
    echo '{"text": "⟳ Connecting to feed...", "class": "loading"}'
    exit 0
fi

# Count available headlines (FreshRSS returns newest first)
count=$(echo "$response" | jq '[.items[] | select(.title != null and .title != "")] | length' 2>/dev/null)
count=${count:-0}

if [[ "$count" -eq 0 ]]; then
    echo '{"text": "⟳ No recent headlines", "class": "loading"}'
    exit 0
fi

# Decay-weighted random selection: newer headlines (lower index) are more likely
# Using rand^1.5 for gentler decay - still favors newest but older items appear more often
# ~61% chance from first half, ~35% from first quarter
rand_float=$(awk 'BEGIN {srand(); r=rand(); print r^1.5}')
index=$(awk -v r="$rand_float" -v c="$count" 'BEGIN {idx=int(r * c); if(idx>=c) idx=c-1; print idx}')

# Get headline at decay-weighted index
headline=$(echo "$response" | jq -r --arg idx "$index" '
    [.items[] | select(.title != null and .title != "")]
    | .[$idx | tonumber]
    | (.origin.title // "Feed") + " | " + .title
' 2>/dev/null)

# Extract URL: HN -> comments, others -> article
url=$(echo "$response" | jq -r --arg idx "$index" '
    [.items[] | select(.title != null and .title != "")]
    | .[$idx | tonumber]
    | if (.origin.title // "") | contains("Hacker News") then
        (.summary.content // "" |
         if test("https://news\\.ycombinator\\.com/item\\?id=[0-9]+") then
             (match("https://news\\.ycombinator\\.com/item\\?id=[0-9]+") | .string)
         else
             (.alternate[0].href // "")
         end)
      else
        (.alternate[0].href // .canonical[0].href // "")
      end
' 2>/dev/null)

# Store URL with headline for click verification
# Format: headline|||url
if [[ -n "$url" && -n "$headline" ]]; then
    printf '%s|||%s\n' "$headline" "$url" > "$URL_FILE"
fi

# Output for waybar (properly escape the headline)
if [[ -n "$headline" ]]; then
    # Build JSON using jq with proper escaping
    jq -nc --arg text "$headline" --arg class "ticker" '{text: $text, class: $class}'

    # Hover pause loop
    if is_cursor_over_bar; then
        while is_cursor_over_bar; do
            sleep 1
        done
    fi
else
    echo '{"text": "⟳ Feed temporarily offline", "class": "error"}'
fi
