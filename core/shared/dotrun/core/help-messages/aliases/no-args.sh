#!/usr/bin/env bash
# Help message for: dr -a / dr aliases (no valid subcommand)

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

USAGE_LINE="${GRAY}Usage: ${RESET}${CYAN}dr ${FEATURE_COLOR}-a${RESET} ${GRAY}[command] [args]${RESET}"
COMMANDS_HEADER="${GRAY}Commands:${RESET}"
EXAMPLES_HEADER="${GRAY}Examples:${RESET}"

cat <<EOF
${USAGE_LINE}

${GRAY}Default: Opens alias file for editing (no command needed)${RESET}

${COMMANDS_HEADER}
  ${YELLOW}<name>${RESET}                        Edit alias file ${GRAY}(default action)${RESET}
  ${FEATURE_COLOR}-l${RESET} ${YELLOW}[folder/]${RESET}                  List aliases ${GRAY}(tree view, short)${RESET}
  ${FEATURE_COLOR}-L${RESET} ${YELLOW}[folder/]${RESET}                  List aliases ${GRAY}(tree view, with descriptions)${RESET}
  ${FEATURE_COLOR}move${RESET} ${YELLOW}<source> <dest>${RESET}          Move/rename alias file
  ${FEATURE_COLOR}rm${RESET} ${YELLOW}<name>${RESET}                     Remove alias file
  ${FEATURE_COLOR}help${RESET} ${YELLOW}<name>${RESET}                   Show alias file documentation
  ${FEATURE_COLOR}init${RESET}                          Initialize aliases folder structure

${GRAY}Note: 'set' is optional - 'dr -a myalias' and 'dr -a set myalias' are equivalent${RESET}

${EXAMPLES_HEADER}
  ${CYAN}dr ${FEATURE_COLOR}-a ${YELLOW}git-shortcuts${RESET}           ${GRAY}# Edit (or create) git-shortcuts.aliases${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-a -l${RESET}                      ${GRAY}# List all aliases in tree format${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-a -L ${YELLOW}cd/${RESET}                  ${GRAY}# List aliases in cd/ with descriptions${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-a move ${YELLOW}old-name new-name${RESET}  ${GRAY}# Rename alias file${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-a rm ${YELLOW}unused-alias${RESET}         ${GRAY}# Remove alias file${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-a help ${YELLOW}git-shortcuts${RESET}      ${GRAY}# Show documentation for alias file${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-a init${RESET}                    ${GRAY}# Initialize aliases directory${RESET}
EOF
