#!/bin/bash

# Mullvad VPN status script for Waybar

get_status() {
    status=$(mullvad status 2>/dev/null)

    if echo "$status" | grep -q "Connected"; then
        # Extract location and IP
        location=$(echo "$status" | grep "Visible location" | awk -F': ' '{print $2}' | awk -F',' '{print $2}' | xargs)
        ip=$(echo "$status" | grep "IPv4" | awk -F'IPv4: ' '{print $2}')

        # Check if multihop is enabled
        relay=$(echo "$status" | grep "Relay:" | awk -F': ' '{print $2}')

        echo "{\"text\": \"󰖂\", \"tooltip\": \"Connected: $location\\n$ip\", \"class\": \"connected\"}"
    elif echo "$status" | grep -q "Connecting"; then
        echo "{\"text\": \"󰖂\", \"tooltip\": \"Connecting...\", \"class\": \"connecting\"}"
    else
        echo "{\"text\": \"󰖂\", \"tooltip\": \"Disconnected\", \"class\": \"disconnected\"}"
    fi
}

get_status
