---
name: notify
description: Toggle cc-notification desktop notifications on or off
user_invocable: true
---

Toggle the cc-notification plugin's desktop notifications.

## Behavior

Check if the flag file `~/.cc-notification-disabled` exists:

- **If it exists** (notifications are OFF): Delete the file and tell the user "Notifications enabled."
- **If it doesn't exist** (notifications are ON): Create the file and tell the user "Notifications disabled."

Use the Bash tool to check and toggle:
```bash
# Check current state
test -f "$USERPROFILE/.cc-notification-disabled" && echo "disabled" || echo "enabled"
```

To disable:
```bash
touch "$USERPROFILE/.cc-notification-disabled"
```

To enable:
```bash
rm "$USERPROFILE/.cc-notification-disabled"
```

Keep the response to a single line confirming the new state.
