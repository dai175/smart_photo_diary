#!/usr/bin/env bash
# Fail if stale Gemini-direct API key markers reappear outside historical allowlist.
# Living provider/key facts live in README + docs/ci_cd_guide.md + CHANGELOG.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Split literals so this file is not a false positive for git grep.
NEEDLE_A='GEMINI_API_KEY'
NEEDLE_B='x-goog-api-key'
PATTERN="${NEEDLE_A}|${NEEDLE_B}"

# CHANGELOG may mention the migration; this script holds the needles by design.
HITS="$(
  git grep -nE "$PATTERN" -- \
    ':(exclude)CHANGELOG.md' \
    ':(exclude)scripts/check_no_stale_gemini_key.sh' \
    2>/dev/null || true
)"

if [[ -n "$HITS" ]]; then
  echo "Stale Gemini-direct API markers found (use OPENROUTER_* instead):" >&2
  echo "$HITS" >&2
  exit 1
fi

echo "OK: no stale Gemini-direct API markers outside allowlist"
