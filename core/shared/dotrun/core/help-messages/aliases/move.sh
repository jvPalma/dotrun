#!/usr/bin/env bash
# Help message for: dr -a move (without arguments)

# Color codes for help output
BOLD=$'\e[1m'
CYAN=$'\e[36m'
GREEN=$'\e[32m'
PURPLE=$'\e[35m'
RED=$'\e[31m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
GRAY=$'\e[90m'
RESET=$'\e[0m'

FEATURE_COLOR="${PURPLE}"

USAGE_LINE="${GRAY}Usage: ${RESET}${CYAN}dr ${FEATURE_COLOR}-a move${RESET} ${YELLOW}<source> <destination>${RESET}"
EXAMPLES_HEADER="${GRAY}Examples:${RESET}"

cat <<EOF
${USAGE_LINE}
${EXAMPLES_HEADER}
  ${CYAN}dr ${FEATURE_COLOR}-a move ${YELLOW}old-name new-name${RESET}       ${GRAY}# Simple rename${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-a move ${YELLOW}git cd/git${RESET}              ${GRAY}# Move to folder${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-a move ${YELLOW}cd/nav shortcuts/nav${RESET}    ${GRAY}# Move between folders${RESET}
EOF
