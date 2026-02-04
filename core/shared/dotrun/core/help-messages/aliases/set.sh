#!/usr/bin/env bash
# Help message for: dr -a set / dr aliases set (without arguments)

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

USAGE_LINE="${GRAY}Usage: ${RESET}${CYAN}dr ${FEATURE_COLOR}aliases set${RESET} ${YELLOW}<path/to/file>${RESET}"
EXAMPLES_HEADER="${GRAY}Examples:${RESET}"

cat <<EOF
${USAGE_LINE}

${GRAY}Creates or opens an alias file for editing (idempotent).${RESET}
${GRAY}One file can contain multiple aliases.${RESET}

${EXAMPLES_HEADER}
  ${CYAN}dr ${FEATURE_COLOR}aliases set ${YELLOW}01-git${RESET}          ${GRAY}# Opens ~/.config/dotrun/aliases/01-git.aliases${RESET}
  ${CYAN}dr ${FEATURE_COLOR}aliases set ${YELLOW}cd/shortcuts${RESET}    ${GRAY}# Opens ~/.config/dotrun/aliases/cd/shortcuts.aliases${RESET}
EOF
