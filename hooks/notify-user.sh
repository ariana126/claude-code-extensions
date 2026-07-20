#!/usr/bin/env bash
# Claude Code Notification hook: desktop notification + sound.
# Receives hook JSON on stdin; `.message` holds the reason for the notification.

set -uo pipefail

SOUND=/usr/share/sounds/freedesktop/stereo/complete.oga

message=$(jq -r '.message // empty' 2>/dev/null)

notify-send -u critical 'Claude Code' "${message:-Needs your attention}"
[ -r "$SOUND" ] && paplay "$SOUND"

exit 0
