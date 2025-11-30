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

# Exponential decay based on actual timestamps
# Half-life of 3 hours: items from 3h ago have 50% weight, 6h ago have 25%, etc.
HALF_LIFE_HOURS=3

# Generate random float 0-1 using /dev/urandom for true randomness
RAND_FLOAT=$(od -An -N4 -tu4 /dev/urandom | tr -d ' ' | awk '{printf "%.10f", $1 / 4294967295}')

# Select headline using timestamp-weighted random selection
selected=$(echo "$response" | jq -r --arg half_life "$HALF_LIFE_HOURS" --arg rand "$RAND_FLOAT" '
  def exp_decay($age_hours; $half_life):
    ((-0.693147 * $age_hours) / $half_life) | exp;

  now as $now |
  [.items[] | select(.title != null and .title != "")] |
  if length == 0 then null
  else
    # Calculate weights based on actual age
    map({
      title: ((.origin.title // "Feed") + " | " + .title),
      url: (if (.origin.title // "") | contains("Hacker News") then
              (.summary.content // "" |
               if test("https://news\\.ycombinator\\.com/item\\?id=[0-9]+") then
                 (match("https://news\\.ycombinator\\.com/item\\?id=[0-9]+") | .string)
               else (.alternate[0].href // "") end)
            else (.alternate[0].href // .canonical[0].href // "") end),
      age_hours: (($now - (.published | tonumber)) / 3600),
      weight: exp_decay((($now - (.published | tonumber)) / 3600); ($half_life | tonumber))
    }) |
    # Calculate cumulative weights for selection
    (map(.weight) | add) as $total |
    if $total == 0 then .[0]
    else
      # Use random selection weighted by decay
      ($rand | tonumber) as $r |
      ($r * $total) as $pick |
      reduce .[] as $item (
        {sum: 0, selected: null};
        if .selected != null then .
        else
          (.sum + $item.weight) as $new_sum |
          if $new_sum >= $pick then {sum: $new_sum, selected: $item}
          else {sum: $new_sum, selected: null} end
        end
      ) | .selected // .[0]
    end
  end |
  if . then "\(.title)\n|||URL|||\(.url)" else null end
' 2>/dev/null)

if [[ -z "$selected" || "$selected" == "null" ]]; then
    echo '{"text": "⟳ No recent headlines", "class": "loading"}'
    exit 0
fi

headline=$(echo "$selected" | head -1)
url=$(echo "$selected" | grep -oP '(?<=\|\|\|URL\|\|\|).*')

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
