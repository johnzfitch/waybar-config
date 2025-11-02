#!/bin/bash

# Feed ticker for waybar - rotates through Internet Universe headlines
# Fetches from Google Reader API and displays one headline at a time

CACHE_FILE="$HOME/.cache/waybar-feed-cache.json"
STATE_FILE="$HOME/.cache/waybar-feed-state"
URL_FILE="$HOME/.cache/waybar-feed-current-url"
CACHE_DURATION=300  # 5 minutes
BAR_HEIGHT=50  # Height of waybar in pixels

# Get auth token from environment variable or use default
AUTH_TOKEN="${FRESHRSS_AUTH_TOKEN:-}"
if [[ -z "$AUTH_TOKEN" ]]; then
    echo '{"text": "⚠ FRESHRSS_AUTH_TOKEN not set", "class": "error"}'
    exit 1
fi

HOURS_AGO_48=$(( $(date +%s) - (48 * 60 * 60) ))
FEED_URL="https://feed.internetuniverse.org/p/api/greader.php/reader/api/0/stream/contents/reading-list?n=200&ot=${HOURS_AGO_48}&output=json"

# Check if cache exists and is fresh
fetch_feed() {
    if [[ -f "$CACHE_FILE" ]]; then
        local age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
        if [[ $age -lt $CACHE_DURATION ]]; then
            return 0
        fi
    fi

    # Fetch new data with authentication
    if curl -s -f "$FEED_URL" \
        -H "Authorization: GoogleLogin auth=$AUTH_TOKEN" \
        -o "$CACHE_FILE.tmp" 2>/dev/null; then
        mv "$CACHE_FILE.tmp" "$CACHE_FILE"
        return 0
    else
        rm -f "$CACHE_FILE.tmp"
        return 1
    fi
}

# Get current headline index
get_current_index() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "0"
    fi
}

# Update headline index
update_index() {
    local total=$1
    local current=$(get_current_index)
    local next=$(( (current + 1) % total ))
    echo "$next" > "$STATE_FILE"
}

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

# Main logic
main() {
    # Ensure cache directory exists
    mkdir -p "$(dirname "$CACHE_FILE")"

    # Fetch feed if needed
    if ! fetch_feed; then
        echo '{"text": "⟳ Connecting to feed...", "class": "loading"}'
        exit 0
    fi

    # Check if cache file has content
    if [[ ! -s "$CACHE_FILE" ]]; then
        echo '{"text": "⟳ Loading headlines...", "class": "loading"}'
        exit 0
    fi

    # Parse feed and get headlines
    local current_index=$(get_current_index)

    # Get total count for rotation
    local total=$(jq -r '.items | map(select(.title != null and .title != "")) | length' "$CACHE_FILE" 2>/dev/null)

    if [[ "$total" -gt 0 ]]; then
        # Update index for next run
        update_index "$total"

        # Extract headline and URL
        local text=$(jq -r --arg idx "$current_index" '
            .items
            | map(select(.title != null and .title != ""))
            | if length > 0 then
                .[(($idx | tonumber) % length)]
                | (.origin.title // "Feed") + " | " + .title
              else
                "⟳ No headlines available"
              end
        ' "$CACHE_FILE" 2>/dev/null)

        # Extract URL: HN -> comments, others -> article
        local url=$(jq -r --arg idx "$current_index" '
            .items
            | map(select(.title != null and .title != ""))
            | if length > 0 then
                .[(($idx | tonumber) % length)]
                | . as $item
                | if (.origin.title // "") | contains("Hacker News") then
                    # For HN, extract comments URL from summary
                    ($item.summary.content // "" |
                     if test("https://news\\.ycombinator\\.com/item\\?id=[0-9]+") then
                         (match("https://news\\.ycombinator\\.com/item\\?id=[0-9]+") | .string)
                     else
                         ($item.alternate[0].href // "")
                     end)
                  else
                    # For other feeds, use direct article link
                    (.alternate[0].href // .canonical[0].href // "")
                  end
              else
                ""
              end
        ' "$CACHE_FILE" 2>/dev/null)

        # Store the URL for the click handler
        if [[ -n "$url" ]]; then
            echo "$url" > "$URL_FILE"
        fi

        # Output in waybar format (no tooltip)
        echo "{\"text\":\"$text\",\"class\":\"ticker\"}" | jq -c '.'

        # Check if cursor is hovering over bar
        if is_cursor_over_bar; then
            # Enter hover loop - keep script alive while cursor is over bar
            # This prevents waybar from rotating to next article
            while is_cursor_over_bar; do
                sleep 1
            done
        fi
    else
        echo '{"text": "⟳ Feed temporarily offline", "class": "error"}'
    fi
}

main
