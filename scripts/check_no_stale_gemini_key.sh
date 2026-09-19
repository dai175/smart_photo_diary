#!/usr/bin/env bash
# Fail if stale Gemini-direct API key markers reappear outside historical allowlist.
# Living provider/key facts live in README + docs/ci_cd_guide.md + CHANGELOG.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PATTERN='GEMINI_API_KEY|x-goog-api-key'
# CHANGELOG may mention the migration; do not scan git metadata.
HITS="$(
  git grep -nE "$PATTERN" -- \
    ':(exclude)CHANGELOG.md' \
    ':(exclude).git/*' \
    2>/dev/null || true
)"

if [[ -n "$HITS" ]]; then
  echo "Stale Gemini-direct API markers found (use OPENROUTER_* instead):" >&2
  echo "$HITS" >&2
  exit 1
fi

echo "OK: no GEMINI_API_KEY / x-goog-api-key outside CHANGELOG.md"
