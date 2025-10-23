#!/usr/bin/env bash

# Color definitions from LS_COLORS palette
# Using executable color (bold pink/red) for regular models
REGULAR_COLOR='\033[1;38;2;243;139;168m'
# Using README file style (dark text on yellow/cream background) for 1M models - highly visible
BOLD_1M_COLOR='\033[0;38;2;30;30;46;48;2;249;226;175m'
# Using directory color (blue) for folder
DIR_COLOR='\033[0;38;2;137;180;250m'
# Using source code color (green) for cost
COST_COLOR='\033[0;38;2;166;227;161m'
RESET='\033[0m'

# Read JSON input from stdin
input=$(cat)
#echo "$input" > /tmp/input.json
# Extract values using jq
MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.cwd')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd')

# Choose color based on whether model has "1M" in the name
if [[ "$MODEL_DISPLAY" =~ 1M ]]; then
    MODEL_COLOR="$BOLD_1M_COLOR"
else
    MODEL_COLOR="$REGULAR_COLOR"
fi

# Build base output
OUTPUT="${RESET}[${MODEL_COLOR}${MODEL_DISPLAY}${RESET}] in ${DIR_COLOR}${CURRENT_DIR}${RESET}"

# Only append cost if non-zero
if [[ -n "$COST" && "$COST" != "null" && $(echo "$COST > 0" | bc) -eq 1 ]]; then
    COST_FORMATTED=$(printf "%.2f" "$COST")
    OUTPUT="${OUTPUT} for \$${COST_COLOR}${COST_FORMATTED}${RESET}"
fi

echo -e "$OUTPUT"
