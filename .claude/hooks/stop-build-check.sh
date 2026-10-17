#!/bin/bash
# .claude/hooks/stop-build-check.sh
# Runs when the agent tries to stop. Exits 2 if the build is broken,
# which prevents the session from concluding until the agent fixes it.

cd "$CLAUDE_PROJECT_DIR" || exit 0

# Hard-code project, scheme, and destination per repo. Do not rely on
# auto-discovery: workspaces, multiple projects, or shared-vs-user
# schemes all break naive heuristics.
PROJECT="ListApp.xcodeproj"
SCHEME="ListApp"
DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro"

LOG=/tmp/claude-stop-build.log
if ! xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
        -configuration Debug \
        -destination "$DESTINATION" \
        build > "$LOG" 2>&1; then
    echo "ERROR: build failed; cannot stop with a broken build" >&2
    echo "See $LOG for the full xcodebuild output." >&2
    tail -50 "$LOG" >&2
    exit 2
fi

exit 0

