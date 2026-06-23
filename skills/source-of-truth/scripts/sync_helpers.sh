#!/usr/bin/env bash
# Helpers for source-of-truth SYNC and BOOTSTRAP modes.
# Usage:
#   bash sync_helpers.sh diff        - print files changed since last commit + commit hash + today
#   bash sync_helpers.sh stamp       - print today + short commit hash for "Last verified" field
#   bash sync_helpers.sh stale       - check each spec's "Source files" still exist (run from project root)

set -euo pipefail

cmd="${1:-help}"

case "$cmd" in
  diff)
    echo "=== Today ==="
    date +%Y-%m-%d
    echo
    echo "=== Current commit (short) ==="
    git rev-parse --short HEAD 2>/dev/null || echo "(not a git repo)"
    echo
    echo "=== Files changed (committed: HEAD~1..HEAD) ==="
    git diff --name-only HEAD~1 HEAD 2>/dev/null || echo "(no committed history)"
    echo
    echo "=== Files changed (uncommitted: working tree) ==="
    git diff --name-only 2>/dev/null || true
    echo
    echo "=== Untracked files ==="
    git status --porcelain 2>/dev/null | awk '/^\?\?/ {print $2}' || true
    ;;

  stamp)
    today=$(date +%Y-%m-%d)
    hash=$(git rev-parse --short HEAD 2>/dev/null || echo "no-git")
    echo "Last verified: ${today} against \`${hash}\`"
    ;;

  stale)
    # Find specs referencing files that no longer exist.
    # Run from project root. Looks at docs/specs/spec-*.md.
    if [ ! -d "docs/specs" ]; then
      echo "ERROR: docs/specs/ not found. Run from project root." >&2
      exit 1
    fi

    found_stale=0
    for spec in docs/specs/spec-*.md; do
      [ -f "$spec" ] || continue
      # Extract paths from "- **Source files**:" line. Files are comma-separated, possibly backtick-quoted.
      grep -E '^\s*-\s*\*\*Source files\*\*:' "$spec" | \
        sed 's/^[^:]*://' | \
        tr ',`' '\n\n' | \
        sed 's/^\s*//;s/\s*$//' | \
        grep -vE '^\s*$' | \
        while IFS= read -r path; do
          if [ -n "$path" ] && [ ! -e "$path" ]; then
            echo "STALE: $spec references missing $path"
            found_stale=1
          fi
        done
    done
    [ "$found_stale" -eq 0 ] && echo "All Source files paths exist."
    ;;

  *)
    cat <<EOF
sync_helpers.sh — helpers for source-of-truth catalog

Commands:
  diff    Print today, commit hash, files changed (committed + uncommitted + untracked)
  stamp   Print a ready-to-paste "Last verified: YYYY-MM-DD against \`hash\`" line
  stale   Scan docs/specs/spec-*.md for Source files that no longer exist (run from project root)

Examples:
  bash sync_helpers.sh diff
  bash sync_helpers.sh stamp
  bash sync_helpers.sh stale
EOF
    ;;
esac
