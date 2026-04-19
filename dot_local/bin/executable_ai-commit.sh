#!/usr/bin/env bash
#
# ai-commit - Generate git commit messages using a local MLX model on Apple Silicon.
#
# Usage:
#   ai-commit              # uses existing staged changes
#   ai-commit --amend      # regenerate message for the last commit
#   ai-commit --debug      # show the full mlx_lm invocation for troubleshooting
#
# Requirements: mlx_lm.generate (brew install mlx-lm or pip install mlx-lm)
#
# Installation:
#   1. Save this file somewhere on your PATH (e.g. ~/.local/bin/ai-commit)
#   2. chmod +x ~/.local/bin/ai-commit
#   3. Optionally set AI_COMMIT_MODEL env var to use a different model
#
# The default model auto-downloads on first run (~5GB). Subsequent runs use cache.
#
# Recommended MLX models for MacBook Pro M4 16GB:
#   - mlx-community/gemma-4-e4b-it-4bit   (4.9GB - default, strong instruction following)
#   - mlx-community/Qwen2.5-7B-Instruct-4bit (4.5GB - fast, good at structured output)
#   - mlx-community/Llama-3.2-3B-Instruct-4bit (2.0GB - fastest, good enough for commits)

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
MODEL="${AI_COMMIT_MODEL:-mlx-community/gemma-4-e4b-it-4bit}"
MAX_DIFF_CHARS=12000
MAX_TOKENS="${AI_COMMIT_MAX_TOKENS:-500}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
die()  { printf '\033[1;31merror:\033[0m %s\n' "$1" >&2; exit 1; }
info() { printf '\033[1;34m=>\033[0m %s\n' "$1"; }

# Resolve mlx_lm.generate - check PATH first, then common Homebrew locations
resolve_mlx() {
  if command -v mlx_lm.generate >/dev/null 2>&1; then
    MLX_BIN=$(command -v mlx_lm.generate)
  elif [ -x /opt/homebrew/bin/mlx_lm.generate ]; then
    MLX_BIN=/opt/homebrew/bin/mlx_lm.generate
  elif [ -x /usr/local/bin/mlx_lm.generate ]; then
    MLX_BIN=/usr/local/bin/mlx_lm.generate
  else
    die "mlx_lm.generate not found (brew install mlx-lm)"
  fi
}

check_deps() {
  command -v git >/dev/null 2>&1 || die "git is not installed"
  resolve_mlx
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
    --help|-h)  head -23 "$0" | tail -21; exit 0 ;;
    *)          die "unknown flag: $arg" ;;
  esac
done

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
check_deps

if [ "$AMEND" = true ]; then
  DIFF=$(git diff HEAD~1 HEAD)
else
  DIFF=$(git diff HEAD)
fi

[ -z "$DIFF" ] && die "no changes detected"

# Truncate massive diffs to stay within context limits
if [ ${#DIFF} -gt "$MAX_DIFF_CHARS" ]; then
  DIFF="${DIFF:0:$MAX_DIFF_CHARS}
... [diff truncated at ${MAX_DIFF_CHARS} chars]"
  info "diff was large — truncated to ${MAX_DIFF_CHARS} characters"
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

info "generating commit message with ${MODEL} ..." >&2

USER_PROMPT="<diff>
${DIFF}
</diff>"

if [ "$DEBUG" = true ]; then
  printf '\033[1;35m--- debug: mlx_lm invocation ---\033[0m\n' >&2
  printf 'binary:        %s\n' "$MLX_BIN" >&2
  printf 'model:         %s\n' "$MODEL" >&2
  printf 'max-tokens:    %s\n' "$MAX_TOKENS" >&2
  printf 'system-prompt: %s\n' "$SYSTEM_PROMPT" >&2
  printf 'user-prompt:\n%s\n' "$USER_PROMPT" >&2
  printf '\033[1;35m--------------------------------\033[0m\n' >&2
fi

MLX_STDERR=$(mktemp "${TMPDIR:-/tmp}/ai-commit.XXXXXX")
MESSAGE=$(printf '%s' "$USER_PROMPT" | "$MLX_BIN" \
  --model "$MODEL" \
  --system-prompt "$SYSTEM_PROMPT" \
  --prompt - \
  --max-tokens "$MAX_TOKENS" \
  --verbose F \
  --chat-template-config '{"enable_thinking": false}' \
  2>"$MLX_STDERR") || {
  err=$(cat "$MLX_STDERR")
  rm -f "$MLX_STDERR"
  die "mlx_lm.generate failed: ${err:-unknown error}"
}
rm -f "$MLX_STDERR"

# Strip any accidental code fences or excess whitespace
MESSAGE=$(echo "$MESSAGE" | /opt/homebrew/bin/gsed '/^```/d' | /opt/homebrew/bin/gsed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

[ -z "$MESSAGE" ] && die "model returned an empty response - try again"

echo "$MESSAGE"
