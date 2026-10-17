#!/bin/bash
# .claude/hooks/stop-simulator-cleanup.sh
# Soft cleanup: shuts down booted simulators we don't need anymore.
# Does NOT erase data; does NOT block. Logs only.

BOOTED=$(xcrun simctl list devices booted 2>/dev/null | grep -E "Booted" | wc -l | xargs)
if (( BOOTED > 0 )); then
    echo "[hook] $BOOTED booted simulators at session end; consider shutdown" >&2
    # Uncomment to auto-shutdown:
    # xcrun simctl shutdown all 2>/dev/null
fi

exit 0

