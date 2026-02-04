#!/usr/bin/env bash
# Help message for: dr (no valid command provided)

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

cat <<EOF
${RED}Error:${RESET} No command provided
${GRAY}Run '${RESET}${CYAN}dr --help${RESET}${GRAY}' for usage information${RESET}
EOF
