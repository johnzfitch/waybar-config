# Waybar Configuration

Custom waybar configuration for dual-monitor setup with FreshRSS feed integration.

## Setup

### Environment Variables

The feed ticker requires a FreshRSS auth token. Set it in `~/.config/environment.d/freshrss.conf`:

```bash
FRESHRSS_AUTH_TOKEN=your_username/your_token_here
```

This makes it available to all user services and graphical applications.

Optionally, also add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) for command-line use:

```bash
export FRESHRSS_AUTH_TOKEN="your_username/your_token_here"
```

To get your FreshRSS auth token:
1. Log into FreshRSS at https://feed.internetuniverse.org
2. Go to Settings → Authentication
3. Copy your API token in format: `username/token_string`

### Files

- `config.jsonc` - Main waybar configuration (dual monitor setup)
- `feed-ticker.sh` - FreshRSS feed ticker script
- `style-dp1.css` - Styling for DP-1 monitor (primary)
- `style-dp3.css` - Styling for DP-3 monitor (secondary)
- `style.css` - Main styling file

## Features

### DP-1 (Primary Monitor)
- Full featured bar with workspaces 1-8
- FreshRSS feed ticker (rotates every 5 seconds)
- System tray and status icons
- Clock, network, audio, CPU, battery

### DP-3 (Secondary Monitor)
- Minimal bar with workspaces 9-10
- Smaller font size for compact display

## Feed Ticker

The feed ticker displays headlines from your FreshRSS reading list and rotates through them every 5 seconds. Click to open the main feed page.
