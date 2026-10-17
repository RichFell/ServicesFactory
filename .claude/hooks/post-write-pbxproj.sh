#!/bin/bash
# .claude/hooks/post-write-pbxproj.sh
# Runs after every Edit or Write tool call. Exits 2 to surface the
# validation failure to the agent so it can revert/repair the broken
# .pbxproj before the session moves on. (PostToolUse cannot prevent
# the write itself; it can only feed the error back.)

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ "$FILE" != *.pbxproj ]]; then
    exit 0
fi

if ! plutil -lint "$FILE" >/dev/null 2>&1; then
    echo "ERROR: $FILE failed plutil -lint after write" >&2
    echo "The Xcode project file is structurally broken. Revert and try again." >&2
    exit 2
fi

exit 0

