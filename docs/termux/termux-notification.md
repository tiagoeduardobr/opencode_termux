> **Fonte**: https://github.com/termux/termux-api-package/blob/master/scripts/termux-notification.in
> **Snapshot**: 19/06/2026
> **Formato**: termux-notification script (Termux API package)

# termux-notification

Display a system notification. Content text is specified using `-c/--content` or read from stdin.

## Usage

```
termux-notification [options]
```

## Options

| Option | Description |
|---|---|
| `--action action` | Action to execute when pressing the notification |
| `--alert-once` | Do not alert when the notification is edited |
| `--button1 text` | Text to show on the first notification button |
| `--button1-action action` | Action to execute on the first notification button |
| `--button2 text` | Text to show on the second notification button |
| `--button2-action action` | Action to execute on the second notification button |
| `--button3 text` | Text to show on the third notification button |
| `--button3-action action` | Action to execute on the third notification button |
| `-c/--content content` | Content to show in the notification. Takes precedence over stdin. |
| `--channel channel-id` | Specifies the notification channel id |
| `--group group` | Notification group (notifications with the same group are shown together) |
| `-h/--help` | Show help |
| `--help-actions` | Show help for actions |
| `-i/--id id` | Notification id (will overwrite any previous notification with the same id) |
| `--icon icon-name` | Set the icon that shows up in the status bar |
| `--image-path path` | Absolute path to an image which will be shown in the notification |
| `--led-color rrggbb` | Color of the blinking led as RRGGBB |
| `--led-off milliseconds` | Milliseconds for the LED to be off while flashing |
| `--led-on milliseconds` | Milliseconds for the LED to be on while flashing |
| `--on-delete action` | Action to execute when the notification is cleared |
| `--ongoing` | Pin the notification |
| `--priority prio` | Notification priority (high/low/max/min/default) |
| `--sound` | Play a sound with the notification |
| `-t/--title title` | Notification title to show |
| `--vibrate pattern` | Vibrate pattern, comma separated as in 500,1000,200 |
| `--type type` | Notification style to use (default/media) |

## Media actions (available with `--type "media"`)

| Option | Description |
|---|---|
| `--media-next` | Action to execute on the media-next button |
| `--media-pause` | Action to execute on the media-pause button |
| `--media-play` | Action to execute on the media-play button |
| `--media-previous` | Action to execute on the media-previous button |

## Actions

Actions are strings fed to `dash -c`. Important notes:

- Use actions that do things outside of the terminal (e.g., `termux-toast hello`)
- Anything that outputs to the terminal is useless — redirect output
- Running more than one command: `command1; command2; command3`
- On Android N+, use `$REPLY` for Direct Reply feature
- The action is run in a different environment (not a subshell), so `$PATH` is lost

## Examples

```bash
# Basic notification
termux-notification --title "Title" --content "Content"

# Ongoing notification (pinned, not removable by swipe)
termux-notification --id "my-id" --title "Pinned" --content "Cannot swipe" --ongoing

# Notification with action
termux-notification --title "Open URL" --content "Click to open" --action "termux-open-url https://example.com"

# Notification with button
termux-notification --id "progress" --title "Download" --content "In progress" \
  --button1 "Cancel" --button1-action "pkill wget"

# Update notification (same id overwrites)
termux-notification --id "progress" --title "Download" --content "Complete!"
```

## Important notes

- **Ongoing notifications** without an `--id` are not removable. Always set `--id` with `--ongoing`.
- **Notification removal** on MIUI/Xiaomi can cause battery settings to open. Use `--id` + `--ongoing` pattern instead of `termux-notification-remove`.
- Notifications with `--id` and `--ongoing` are automatically cleaned by Android when the process terminates.
