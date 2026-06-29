#!/bin/bash
# ─────────────────────────────────────────────────────────
# auto-push.sh  —  watches index.html / admin.html and
# auto-commits + pushes to GitHub whenever they change.
# Managed by ~/Library/LaunchAgents/com.familytrip.autopush.plist
# ─────────────────────────────────────────────────────────
REPO="/Users/andrewclark/Desktop/family-trip-2026"
LOG="/tmp/familytrip-autopush.log"

echo "$(date '+%Y-%m-%d %H:%M:%S')  Watcher started" >> "$LOG"

if ! command -v fswatch &>/dev/null; then
    echo "$(date '+%Y-%m-%d %H:%M:%S')  ERROR: fswatch not found — install with: brew install fswatch" >> "$LOG"
    exit 1
fi

# --latency=5  → batch events for 5 s (debounce rapid saves)
# --include    → only react to .html file changes
# --exclude    → ignore .git internals
fswatch --latency=5 --include='\.html$' --exclude='\.git' -r "$REPO" | \
while read -r _event; do
    cd "$REPO" || continue

    # Bail if there are no uncommitted changes to the HTML files
    if git diff --quiet HEAD -- '*.html' 2>/dev/null; then
        continue
    fi

    git add index.html admin.html 2>/dev/null

    # Nothing staged? skip
    if git diff --cached --quiet; then
        continue
    fi

    TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
    if git commit -m "Auto-sync $TIMESTAMP" >> "$LOG" 2>&1; then
        if git push >> "$LOG" 2>&1; then
            echo "$(date '+%Y-%m-%d %H:%M:%S')  ✅ Pushed — $TIMESTAMP" >> "$LOG"
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S')  ❌ Push failed (see above)" >> "$LOG"
        fi
    fi
done
