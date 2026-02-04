#!/usr/bin/env bash
# Help message for: dr -c / dr config (no valid subcommand)

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

USAGE_LINE="${GRAY}Usage: ${RESET}${CYAN}dr ${FEATURE_COLOR}-c${RESET} ${YELLOW}<configname>${RESET}  ${GRAY}(opens config for editing)${RESET}"
COMMANDS_HEADER="${GRAY}Commands:${RESET}"
EXAMPLES_HEADER="${GRAY}Examples:${RESET}"

cat <<EOF
${USAGE_LINE}
       ${CYAN}dr ${FEATURE_COLOR}-c${RESET} ${GRAY}<command> [args...]${RESET}

${COMMANDS_HEADER}
  ${YELLOW}<configname>${RESET}                  Add/edit config file ${GRAY}(default action)${RESET}
  ${FEATURE_COLOR}-l${RESET} ${YELLOW}[FOLDER/]${RESET}                  List configs ${GRAY}(tree view)${RESET}
  ${FEATURE_COLOR}-L${RESET} ${YELLOW}[FOLDER/]${RESET}                  List configs with descriptions
  ${FEATURE_COLOR}move${RESET} ${YELLOW}<source> <dest>${RESET}          Move/rename config file
  ${FEATURE_COLOR}rm${RESET} ${YELLOW}<path/to/file>${RESET}             Remove config file
  ${FEATURE_COLOR}help${RESET} ${YELLOW}<path/to/file>${RESET}           Show config documentation
  ${FEATURE_COLOR}init${RESET}                          Initialize configs folder

${GRAY}Note: 'set' is optional - 'dr -c myconfig' and 'dr -c set myconfig' are equivalent${RESET}

${EXAMPLES_HEADER}
  ${CYAN}dr ${FEATURE_COLOR}-c ${YELLOW}myconfig${RESET}                ${GRAY}# Opens myconfig.config for editing${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-c -l${RESET}                      ${GRAY}# List all configs${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-c ${YELLOW}api/keys${RESET}                ${GRAY}# Opens api/keys.config for editing${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-c move ${YELLOW}old new${RESET}            ${GRAY}# Rename config file${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-c rm ${YELLOW}api/keys${RESET}             ${GRAY}# Remove config file${RESET}
EOF
