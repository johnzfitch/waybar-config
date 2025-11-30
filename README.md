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

The feed ticker displays headlines from your FreshRSS reading list. It fetches fresh headlines directly from the FreshRSS API every 5 seconds, showing one headline at a time.

### Hover-Pause Feature

The ticker automatically pauses rotation when you hover your cursor over the waybar (top 50 pixels of the screen). This lets you read headlines without them rotating away. The ticker resumes normal rotation when you move your cursor away from the bar.

**How it works:**
- Uses `hyprctl cursorpos` to detect cursor position
- Pauses rotation when Y-coordinate < 50 pixels
- No background daemons - pause detection runs within the existing 5-second waybar interval

### Controls

- **Click**: Open article link
  - Hacker News articles → Opens HN comments page
  - All other feeds → Opens direct article link
- **Hover over bar**: Pause rotation on current headline
  - Text underlines on hover for visual feedback
  - No tooltip popup
