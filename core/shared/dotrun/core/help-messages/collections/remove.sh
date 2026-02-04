#!/usr/bin/env bash
# Help message for: dr -col remove (without arguments)

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

FEATURE_COLOR="${BLUE}"

USAGE_LINE="${GRAY}Usage: ${RESET}${CYAN}dr ${FEATURE_COLOR}-col remove${RESET} ${YELLOW}<collection-name>${RESET}"

cat <<EOF
${USAGE_LINE}

${GRAY}Run '${RESET}${CYAN}dr ${FEATURE_COLOR}-col list${RESET}${GRAY}' to see installed collections${RESET}
EOF
