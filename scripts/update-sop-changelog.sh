#!/usr/bin/env bash
set -euo pipefail

# Update SOP changelog with recent commits.
# This script prepends a dated section to docs/SOP/08-Change-Log.md
# and writes the last processed commit hash to docs/SOP/.sop_changelog_last.

REPO_ROOT="$(git rev-parse --show-toplevel)"
CHANGELOG="${REPO_ROOT}/docs/SOP/08-Change-Log.md"
LASTFILE="${REPO_ROOT}/docs/SOP/.sop_changelog_last"

if [ ! -f "$CHANGELOG" ]; then
  echo "Changelog file missing: $CHANGELOG"
  exit 1
fi

cd "$REPO_ROOT"

if [ -f "$LASTFILE" ]; then
  SINCE=$(cat "$LASTFILE")
else
  # fallback: last 50 commits
  SINCE=""
fi

if [ -n "$SINCE" ]; then
  LOG_RANGE="$SINCE..HEAD"
else
  LOG_RANGE="HEAD~50..HEAD"
fi

# Get commit list
ENTRIES=$(git log --pretty=format:"- %h %s (%an)" $LOG_RANGE || true)

if [ -z "$ENTRIES" ]; then
  echo "No new commits since ${SINCE:-'recent range'}"
  exit 0
fi

DATE=$(date -u +"%Y-%m-%d")
TMPFILE=$(mktemp)

{
  echo "## $DATE — Automated changelog"
  echo
  echo "$ENTRIES"
  echo
  cat "$CHANGELOG"
} > "$TMPFILE"

mv "$TMPFILE" "$CHANGELOG"

# update last processed commit
git rev-parse --verify --short HEAD > "$LASTFILE"

# Commit & push changes if any
git add "$CHANGELOG" "$LASTFILE"
if git diff --cached --quiet; then
  echo "No changelog changes to commit"
  exit 0
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git commit -m "chore(changelog): update SOP changelog ($DATE)"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "GITHUB_TOKEN not set; cannot push the changelog from script. Exiting."
  exit 1
fi

REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
git push "$REPO_URL" HEAD:main

echo "Changelog updated and pushed."
