#!/usr/bin/env bash
#
# !!! IMPORTANT: this script is invoked from Obsidian (Shell Commands plugin),
# !!! which does NOT inherit the user's interactive shell PATH. Every external
# !!! command MUST be called via its absolute path. See the GIT/JQ/CURL/etc.
# !!! constants below - add new ones the same way and reference them with "$VAR"
# !!! rather than the bare command name.
#
# ai-commit - Generate git commit messages using a local oMLX model.
#
# Usage:
#   ai-commit              # message for current unstaged + staged changes
#   ai-commit --amend      # regenerate message for the last commit
#   ai-commit --debug      # print the request payload for troubleshooting
#
# Requirements:
#   - oMLX server running on 127.0.0.1:8000
#   - jq
#   - the chosen model available in oMLX (default: gemma-4-e2b-it-4bit)
#
# Recommended models:
#   - gemma-4-e2b-it-4bit   (default, local 4-bit quantized variant)

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
MODEL="${AI_COMMIT_MODEL:-gemma-4-e2b-it-4bit}"
API_BASE_URL="${AI_COMMIT_API_BASE:-${AI_COMMIT_OLLAMA_URL:-http://127.0.0.1:8000/v1}}"
API_KEY="${AI_COMMIT_API_KEY:-}"
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
  "$CURL" -fsS "${API_BASE_URL}/models" >/dev/null 2>&1 \
    || die "oMLX not reachable at ${API_BASE_URL}"
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
- Bullet points describe meaningful user-facing or content changes
- Prefer intent and substance over file mechanics
- Group related markdown or note edits into 1-3 high-signal bullets
- Do not mention mechanical scaffolding unless it is the actual change:
  frontmatter fields, empty lists, added headings, added sections, file paths,
  templates, or formatting-only setup
- One bullet per logical change
- No markdown, no code fences, no preamble, no sign-off
- If the diff is trivial (< 5 lines), skip bullets entirely

Example output:
Add GitLab Agentic AI security workflow meeting notes

- Capture discussion topics around MR approval policies
- Summarize scan and pipeline execution policy considerations
- Add decisions, action items, and notes from the meeting
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
    max_tokens: $max,
    temperature: 0.2,
    stream: false
  }')

if [ "$DEBUG" = true ]; then
  printf '\033[1;35m--- debug: oMLX request ---\033[0m\n' >&2
  printf 'url:    %s/chat/completions\n' "$API_BASE_URL" >&2
  printf 'model:  %s\n' "$MODEL" >&2
  printf 'payload:\n%s\n' "$PAYLOAD" | "$JQ" . >&2
  printf '\033[1;35m-----------------------------\033[0m\n' >&2
fi

info "generating commit message with ${MODEL} ..."

if [ -n "$API_KEY" ]; then
  RESPONSE=$("$CURL" -fsS "${API_BASE_URL}/chat/completions" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${API_KEY}" \
    -d "$PAYLOAD") || die "oMLX request failed"
else
  RESPONSE=$("$CURL" -fsS "${API_BASE_URL}/chat/completions" \
    -H 'Content-Type: application/json' \
    -d "$PAYLOAD") || die "oMLX request failed"
fi

MESSAGE=$(printf '%s' "$RESPONSE" | "$JQ" -r '.choices[0].message.content // .message.content // empty')

[ -z "$MESSAGE" ] && die "model returned an empty response (raw: $RESPONSE)"

# Strip accidental code fences and surrounding whitespace
MESSAGE=$(printf '%s\n' "$MESSAGE" \
  | "$GSED" '/^```/d' \
  | "$GSED" -e 's/[[:space:]]*$//' \
  | "$GSED" -e :a -e '/./,$!d;/^\n*$/{$d;N;ba' -e '}')

echo "$MESSAGE"
