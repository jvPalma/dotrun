#!/usr/bin/env bash
# Help message for: dr -a init (aliases initialization)

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
ALIASES_DIR="${1:-\$USER_COLLECTION_ALIASES}"

cat <<EOF
${GREEN}Initializing aliases system...${RESET}
${GREEN}✓${RESET} Created aliases directory: ${YELLOW}${ALIASES_DIR}${RESET}

Set aliases with: ${CYAN}dr ${FEATURE_COLOR}-a${RESET} ${YELLOW}<path/to/file>${RESET}
${GRAY}Example:${RESET} ${CYAN}dr ${FEATURE_COLOR}-a ${YELLOW}01-git${RESET}
         ${CYAN}dr ${FEATURE_COLOR}-a ${YELLOW}cd/shortcuts${RESET}
EOF
