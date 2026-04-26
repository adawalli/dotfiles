#!/usr/bin/env bash
#
# !!! IMPORTANT: this script is invoked from Obsidian (Shell Commands plugin),
# !!! which does NOT inherit the user's interactive shell PATH. Every external
# !!! command MUST be called via its absolute path. See the GIT/JQ/CURL/etc.
# !!! constants below - add new ones the same way and reference them with "$VAR"
# !!! rather than the bare command name.
#
# ai-commit - Generate git commit messages using a local Ollama model.
#
# Usage:
#   ai-commit              # message for current unstaged + staged changes
#   ai-commit --amend      # regenerate message for the last commit
#   ai-commit --debug      # print the request payload for troubleshooting
#
# Requirements:
#   - ollama running on localhost:11434  (brew install ollama && brew services start ollama)
#   - jq
#   - the chosen model pulled (ollama pull gemma4:e4b)
#
# Recommended models:
#   - gemma4:e4b              (default, bf16, ~9.6GB - best quality)
#   - gemma4:e4b-it-q4_K_M    (~3GB - 4-bit quant, much smaller, near-identical quality)
#   - gemma4:e2b              (~5GB - smaller, faster)

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
MODEL="${AI_COMMIT_MODEL:-gemma4:e4b}"
OLLAMA_URL="${AI_COMMIT_OLLAMA_URL:-http://localhost:11434}"
MAX_DIFF_CHARS="${AI_COMMIT_MAX_DIFF_CHARS:-60000}"
MAX_TOKENS="${AI_COMMIT_MAX_TOKENS:-500}"

# Absolute paths for every external command - this script is invoked from
# Obsidian (Shell Commands plugin) which doesn't inherit our shell PATH.
GIT=/usr/bin/git
JQ=/opt/homebrew/bin/jq
CURL=/usr/bin/curl
HEAD=/usr/bin/head
TAIL=/usr/bin/tail
GSED=/opt/homebrew/bin/gsed

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
die()  { printf '\033[1;31merror:\033[0m %s\n' "$1" >&2; exit 1; }
info() { printf '\033[1;34m=>\033[0m %s\n' "$1" >&2; }

check_deps() {
  for bin in "$GIT" "$JQ" "$CURL" "$HEAD" "$TAIL" "$GSED"; do
    [ -x "$bin" ] || die "required binary not found: $bin"
  done
  "$CURL" -fsS "${OLLAMA_URL}/api/version" >/dev/null 2>&1 \
    || die "ollama not reachable at ${OLLAMA_URL} (try: brew services start ollama)"
}

# ---------------------------------------------------------------------------
# Parse flags
# ---------------------------------------------------------------------------
AMEND=false
DEBUG=false
for arg in "$@"; do
  case "$arg" in
    --amend)    AMEND=true ;;
    --debug|-d) DEBUG=true ;;
    --help|-h)  "$HEAD" -24 "$0" | "$TAIL" -16; exit 0 ;;
    *)          die "unknown flag: $arg" ;;
  esac
done

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
check_deps

collect_diff() {
  if [ "$AMEND" = true ]; then
    "$GIT" diff HEAD~1 HEAD
    return
  fi
  "$GIT" diff HEAD
  # Include untracked files as "new file" diffs (read-only, doesn't touch the index)
  while IFS= read -r -d '' f; do
    "$GIT" diff --no-index --no-color -- /dev/null "$f" 2>/dev/null || true
  done < <("$GIT" ls-files --others --exclude-standard -z)
}

DIFF=$(collect_diff)

[ -z "$DIFF" ] && die "no changes detected"

if [ ${#DIFF} -gt "$MAX_DIFF_CHARS" ]; then
  DIFF="${DIFF:0:$MAX_DIFF_CHARS}
... [diff truncated at ${MAX_DIFF_CHARS} chars]"
  info "diff was large - truncated to ${MAX_DIFF_CHARS} characters"
fi

read -r -d '' SYSTEM_PROMPT <<'PROMPT' || true
You are a git commit message generator. Output ONLY the commit message.

FORMAT (follow exactly):
- Line 1: imperative verb + concise summary, max 72 characters
- Line 2: blank
- Lines 3+: bullet points starting with "- " describing each concrete change

RULES:
- First word must be a verb (Add, Fix, Update, Remove, Refactor, etc.)
- Bullet points describe WHAT changed, not WHY
- One bullet per file or logical change
- No markdown, no code fences, no preamble, no sign-off
- If the diff is trivial (< 5 lines), skip bullets entirely

Example output:
Add Niklas Luhmann details and slip-box workflow notes

- Fix author name formatting in preface
- Add section on Luhmann's index card system
- Document step-by-step process for creating permanent notes
PROMPT

USER_PROMPT="<diff>
${DIFF}
</diff>"

PAYLOAD=$("$JQ" -n \
  --arg model "$MODEL" \
  --arg sys "$SYSTEM_PROMPT" \
  --arg usr "$USER_PROMPT" \
  --argjson max "$MAX_TOKENS" \
  '{
    model: $model,
    messages: [
      {role: "system", content: $sys},
      {role: "user",   content: $usr}
    ],
    stream: false,
    think: false,
    options: {num_predict: $max, temperature: 0.2}
  }')

if [ "$DEBUG" = true ]; then
  printf '\033[1;35m--- debug: ollama request ---\033[0m\n' >&2
  printf 'url:    %s/api/chat\n' "$OLLAMA_URL" >&2
  printf 'model:  %s\n' "$MODEL" >&2
  printf 'payload:\n%s\n' "$PAYLOAD" | "$JQ" . >&2
  printf '\033[1;35m-----------------------------\033[0m\n' >&2
fi

info "generating commit message with ${MODEL} ..."

RESPONSE=$("$CURL" -fsS "${OLLAMA_URL}/api/chat" \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD") || die "ollama request failed"

MESSAGE=$(printf '%s' "$RESPONSE" | "$JQ" -r '.message.content // empty')

[ -z "$MESSAGE" ] && die "model returned an empty response (raw: $RESPONSE)"

# Strip accidental code fences and surrounding whitespace
MESSAGE=$(printf '%s\n' "$MESSAGE" \
  | "$GSED" '/^```/d' \
  | "$GSED" -e 's/[[:space:]]*$//' \
  | "$GSED" -e :a -e '/./,$!d;/^\n*$/{$d;N;ba' -e '}')

echo "$MESSAGE"
