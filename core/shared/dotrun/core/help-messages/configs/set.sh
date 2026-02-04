#!/usr/bin/env bash
# Help message for: dr -c set / dr config set (without arguments)

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

FEATURE_COLOR="${RED}"

USAGE_LINE="${GRAY}Usage: ${RESET}${CYAN}dr ${FEATURE_COLOR}config set${RESET} ${YELLOW}<path/to/file>${RESET}"
EXAMPLES_HEADER="${GRAY}Examples:${RESET}"

cat <<EOF
${USAGE_LINE}

${GRAY}Creates or opens a config file for editing (idempotent).${RESET}
${GRAY}One file can contain multiple configuration exports.${RESET}

${EXAMPLES_HEADER}
  ${CYAN}dr ${FEATURE_COLOR}config set ${YELLOW}01-main${RESET}          ${GRAY}# Opens ~/.config/dotrun/configs/01-main.config${RESET}
  ${CYAN}dr ${FEATURE_COLOR}config set ${YELLOW}api/keys${RESET}         ${GRAY}# Opens ~/.config/dotrun/configs/api/keys.config${RESET}
EOF
