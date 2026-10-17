#!/bin/bash
# .claude/hooks/pre-bash-xcode.sh
# Runs before every Bash tool call. Exits 2 (blocking) on irreversible
# Xcode/signing/git operations the developer hasn't explicitly approved.
# PreToolUse hooks CAN block: exit 2 prevents the tool from running.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

case "$COMMAND" in
    *"simctl erase"*)
        echo "ERROR: simulator erase requires explicit human approval" >&2
        echo "Tell the developer what you wanted to erase and why; let them run it." >&2
        exit 2
        ;;
    *"xcodebuild archive"*|*"xcodebuild -exportArchive"*)
        echo "ERROR: xcodebuild archive/export invokes signing; requires human approval" >&2
        exit 2
        ;;
    *"git push --force"*|*"git push -f"*)
        echo "ERROR: force-push rewrites history; requires human approval" >&2
        exit 2
        ;;
    *"rm -rf"*)
        echo "ERROR: rm -rf requires explicit approval" >&2
        exit 2
        ;;
esac

exit 0

