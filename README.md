# Claude Code Windows Notification Hook

A PowerShell script that displays Claude Code notifications as Windows desktop notifications from WSL.
Integrates with Claude Code's `Notification` and `Stop` hook system to provide native Windows notifications.

## Files

- `scripts/toast-notification.ps1` - PowerShell script that displays Windows notifications with fallback chain
- `.claude-plugin/plugin.json` - Claude Code plugin manifest
- `hooks/hooks.json` - Hook definitions for Notification and Stop events

## Requirements

- Windows 10 or later
- PowerShell execution permissions
- Windows Runtime API (for toast notifications)
- System.Windows.Forms (.NET Framework)

## Installation

### Option 1: Claude Code Plugin (Recommended)

Install as a plugin using the Claude Code CLI:

```bash
# Add this repo as a marketplace
claude plugin marketplace add kmio11/cc-notification

# Install the plugin
claude plugin install cc-notification
```

The plugin automatically registers `Notification` and `Stop` hooks — no manual configuration needed.

### Option 2: Manual Hook Configuration

If you prefer manual setup, add to your Claude Code settings file (`~/.claude/settings.json`):

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -ExecutionPolicy Bypass -File \"/path/to/scripts/toast-notification.ps1\""
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -ExecutionPolicy Bypass -File \"/path/to/scripts/toast-notification.ps1\""
          }
        ]
      }
    ]
  }
}
```

Refer to the [Claude Code hooks documentation](https://docs.anthropic.com/en/docs/claude-code/hooks) for more details.

## Usage

### Direct Execution and Testing

**Input Priority**: JsonInput → Stdin → Default  
**Override Rule**: Title/Message parameters force override regardless of input source

```bash
# Default notification (lowest priority)
powershell.exe -File "/path/to/toast-notification.ps1"

# Manual JSON input (highest priority) 
powershell.exe -File "/path/to/toast-notification.ps1" -JsonInput '{"title":"Test","message":"JSON test"}'

# Stdin input (Claude Code hook simulation)
echo '{"hook_event_name":"Notification","title":"Claude Code","message":"Hook message"}' | powershell.exe -File "/path/to/toast-notification.ps1"

# Force override examples
# Override Stop hook message
echo '{"hook_event_name":"Stop","stop_hook_active":false}' | powershell.exe -File "/path/to/toast-notification.ps1" -Message "Custom Complete Message"

# Override title only (keep parsed message)
echo '{"hook_event_name":"Notification","title":"Original","message":"Keep this"}' | powershell.exe -File "/path/to/toast-notification.ps1" -Title "My App"
```

## How It Works

The script uses a robust fallback chain to ensure reliable notification delivery:

### 1. Primary Method: Windows Toast Notifications
- Uses Windows Runtime API with `Anthropic.ClaudeCode` AppID
- Appears in Windows Action Center with modern toast styling
- Persistent in Action Center until dismissed

### 2. Fallback Method: Balloon Tip Notifications
- Traditional balloon notifications from system tray
- Appears in bottom-right corner for 5 seconds
- Used when toast notifications fail