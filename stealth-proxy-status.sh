#!/bin/bash
# Stealth Proxy status script for Waybar
# Left-click: toggle on/off
# Right-click: toggle concentrated/unconcentrated

FLAGFILE="/tmp/proxy-unconcentrated"

get_status() {
    # Check if proxy is running (check for mitmdump process from antigravity-proxy service)
    if pgrep -f "mitmdump.*STEALTH_PROXY" >/dev/null 2>&1; then
        running=true
    elif systemctl --user is-active antigravity-proxy >/dev/null 2>&1; then
        running=true
    else
        running=false
    fi

    # Check if unconcentrated mode
    if [ -f "$FLAGFILE" ]; then
        mode="unconcentrated"
        mode_icon="󰊠"  # all-seeing eye / wide net
        mode_text="AUDIT"
    else
        mode="concentrated"
        mode_icon="󰓾"  # focused / laser
        mode_text="FILTER"
    fi

    if [ "$running" = true ]; then
        if [ "$mode" = "unconcentrated" ]; then
            # Running in audit mode - amber/orange
            echo "{\"text\": \"󱡓\", \"tooltip\": \"Stealth Proxy: ON ($mode_text)\\nLeft-click: Stop\\nRight-click: Switch to FILTER\", \"class\": \"proxy-audit\"}"
        else
            # Running in filter mode - green
            echo "{\"text\": \"󱡓\", \"tooltip\": \"Stealth Proxy: ON ($mode_text)\\nLeft-click: Stop\\nRight-click: Switch to AUDIT\", \"class\": \"proxy-on\"}"
        fi
    else
        # Proxy off - dimmed
        echo "{\"text\": \"󱡒\", \"tooltip\": \"Stealth Proxy: OFF\\nLeft-click: Start\\nRight-click: Toggle mode ($mode_text)\", \"class\": \"proxy-off\"}"
    fi
}

toggle_proxy() {
    if pgrep -f "mitmdump.*STEALTH_PROXY" >/dev/null 2>&1 || systemctl --user is-active antigravity-proxy >/dev/null 2>&1; then
        # Running - stop it
        systemctl --user stop antigravity-proxy 2>/dev/null
        pkill -f "mitmdump.*STEALTH_PROXY" 2>/dev/null
        notify-send -t 2000 "Stealth Proxy" "Stopped"
    else
        # Not running - start it
        systemctl --user start antigravity-proxy
        notify-send -t 2000 "Stealth Proxy" "Started"
    fi
}

toggle_mode() {
    if [ -f "$FLAGFILE" ]; then
        rm -f "$FLAGFILE"
        notify-send -t 2000 "Stealth Proxy" "Mode: CONCENTRATED (filter)"
    else
        touch "$FLAGFILE"
        notify-send -t 2000 "Stealth Proxy" "Mode: UNCONCENTRATED (audit)"
    fi
}

case "${1:-}" in
    toggle)
        toggle_proxy
        ;;
    mode)
        toggle_mode
        ;;
    *)
        get_status
        ;;
esac
