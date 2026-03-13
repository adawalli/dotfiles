#!/usr/bin/env bash

# Catppuccin Mocha color definitions
# Model colors
REGULAR_COLOR='\033[1;38;2;243;139;168m'    # Red - regular models
BOLD_1M_COLOR='\033[0;38;2;30;30;46;48;2;249;226;175m'  # Dark on yellow bg - 1M models
# UI element colors
DIR_COLOR='\033[0;38;2;137;180;250m'        # Blue - directory
COST_COLOR='\033[0;38;2;203;166;247m'       # Mauve - cost
WORKTREE_COLOR='\033[0;38;2;148;226;213m'  # Teal - worktree indicator
BRANCH_COLOR='\033[0;38;2;166;227;161m'   # Green - git branch
# Context usage gradient (Catppuccin Mocha)
CTX_GREEN='\033[0;38;2;166;227;161m'        # Green - low usage (0-50%)
CTX_YELLOW='\033[0;38;2;249;226;175m'       # Yellow - moderate (50-75%)
CTX_PEACH='\033[0;38;2;250;179;135m'        # Peach - high (75-90%)
CTX_RED='\033[1;38;2;243;139;168m'          # Red bold - critical (90%+)
RESET='\033[0m'
PIPE="${RESET} | "
CTX_SUBTLE='\033[0;38;2;147;153;178m'  # Overlay1 - muted text for token counts

# Read JSON input from stdin
input=$(cat)

# Extract values using jq
MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.cwd')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd')

# Extract context window info using current_usage (actual context state)
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
USAGE=$(echo "$input" | jq '.context_window.current_usage')

# Choose color based on whether model has "1M" in the name
if [[ "$MODEL_DISPLAY" =~ 1M ]]; then
    MODEL_COLOR="$BOLD_1M_COLOR"
else
    MODEL_COLOR="$REGULAR_COLOR"
fi

# Calculate context usage percentage from current_usage fields
if [[ "$USAGE" != "null" ]]; then
    CTX_USED=$(echo "$USAGE" | jq '(.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)')
else
    CTX_USED=0
fi

if [[ "$CTX_SIZE" -gt 0 && "$CTX_USED" -gt 0 ]]; then
    CTX_PCT=$(echo "scale=1; $CTX_USED * 100 / $CTX_SIZE" | bc)
else
    CTX_PCT="0"
fi

# Format token counts (K for thousands)
if [[ "$CTX_USED" -ge 1000 ]]; then
    TOKENS_DISPLAY="$((CTX_USED / 1000))K"
else
    TOKENS_DISPLAY="$CTX_USED"
fi
CTX_SIZE_DISPLAY="$((CTX_SIZE / 1000))K"

# Choose context color based on usage percentage
CTX_PCT_INT=${CTX_PCT%.*}
CTX_PCT_INT=${CTX_PCT_INT:-0}
if [[ "$CTX_PCT_INT" -ge 90 ]]; then
    CTX_COLOR="$CTX_RED"
elif [[ "$CTX_PCT_INT" -ge 75 ]]; then
    CTX_COLOR="$CTX_PEACH"
elif [[ "$CTX_PCT_INT" -ge 50 ]]; then
    CTX_COLOR="$CTX_YELLOW"
else
    CTX_COLOR="$CTX_GREEN"
fi

# Build progress bar (10 chars wide)
BAR_WIDTH=10
FILLED=$((CTX_PCT_INT * BAR_WIDTH / 100))
[[ "$FILLED" -gt "$BAR_WIDTH" ]] && FILLED=$BAR_WIDTH
EMPTY=$((BAR_WIDTH - FILLED))
BAR="${CTX_COLOR}$(printf '%*s' "$FILLED" '' | tr ' ' '█')${RESET}$(printf '%*s' "$EMPTY" '' | tr ' ' '░')"

# Git branch (read .git/HEAD directly - no subprocess)
BRANCH_SECTION=""
if [[ -r "${CURRENT_DIR}/.git/HEAD" ]]; then
    read -r HEAD_REF < "${CURRENT_DIR}/.git/HEAD"
    BRANCH="${HEAD_REF#ref: refs/heads/}"
    BRANCH_SECTION="${PIPE}${BRANCH_COLOR}${BRANCH}${RESET}"
fi

# Worktree info (only shown when active)
WORKTREE_NAME=$(echo "$input" | jq -r '.worktree.name // empty')
WORKTREE_SECTION=""
if [[ -n "$WORKTREE_NAME" ]]; then
    WORKTREE_SECTION="${PIPE}${WORKTREE_COLOR}wt:${WORKTREE_NAME}${RESET}"
fi

# Build output with pipe separators between sections
OUTPUT="${RESET}[${MODEL_COLOR}${MODEL_DISPLAY}${RESET}]${PIPE}${DIR_COLOR}${CURRENT_DIR}${RESET}${BRANCH_SECTION}${WORKTREE_SECTION}"

# Append cost and context bar
if [[ -n "$COST" && "$COST" != "null" && $(echo "$COST > 0" | bc) -eq 1 ]]; then
    COST_FORMATTED=$(printf "%.2f" "$COST")
    OUTPUT="${OUTPUT}${PIPE}\$${COST_COLOR}${COST_FORMATTED}${RESET}${PIPE}${BAR} ${CTX_COLOR}${CTX_PCT}%${RESET} ${CTX_SUBTLE}(${TOKENS_DISPLAY}/${CTX_SIZE_DISPLAY})${RESET}"
else
    OUTPUT="${OUTPUT}${PIPE}${BAR} ${CTX_COLOR}${CTX_PCT}%${RESET} ${CTX_SUBTLE}(${TOKENS_DISPLAY}/${CTX_SIZE_DISPLAY})${RESET}"
fi

echo -e "$OUTPUT"
