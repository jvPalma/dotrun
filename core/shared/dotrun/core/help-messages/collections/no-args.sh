#!/usr/bin/env bash
# Help message for: dr -col / dr collections (no valid subcommand)

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

NAMESPACE="${1:-collections}"
FEATURE_COLOR="${BLUE}"

USAGE_LINE="${GRAY}Usage: ${RESET}${CYAN}dr ${FEATURE_COLOR}${NAMESPACE}${RESET} ${GRAY}[command]${RESET}"
COMMANDS_HEADER="${GRAY}Commands:${RESET}"
EXAMPLES_HEADER="${GRAY}Examples:${RESET}"

cat <<EOF
${USAGE_LINE}

${COMMANDS_HEADER}
  ${GRAY}(no args)${RESET}         Interactive collection browser
  ${FEATURE_COLOR}init${RESET}              Initialize collection structure for authors
  ${FEATURE_COLOR}add${RESET} ${YELLOW}<url>${RESET}         Install collection from GitHub repository
  ${FEATURE_COLOR}list${RESET}              List installed collections with versions
  ${FEATURE_COLOR}sync${RESET}              Check all collections for updates
  ${FEATURE_COLOR}update${RESET} ${YELLOW}[name]${RESET}     Update collection ${GRAY}(interactive if no name given)${RESET}
  ${FEATURE_COLOR}remove${RESET} ${YELLOW}<name>${RESET}     Remove collection tracking
  ${FEATURE_COLOR}--help${RESET}, ${FEATURE_COLOR}-h${RESET}        Show detailed collections help

${EXAMPLES_HEADER}
  ${CYAN}dr ${FEATURE_COLOR}${NAMESPACE} init${RESET}                                          ${GRAY}# Initialize collection${RESET}
  ${CYAN}dr ${FEATURE_COLOR}${NAMESPACE} add ${YELLOW}https://github.com/user/repo${RESET}              ${GRAY}# Install collection${RESET}
  ${CYAN}dr ${FEATURE_COLOR}${NAMESPACE} list${RESET}                                          ${GRAY}# List collections${RESET}
  ${CYAN}dr ${FEATURE_COLOR}${NAMESPACE} sync${RESET}                                          ${GRAY}# Check for updates${RESET}
  ${CYAN}dr ${FEATURE_COLOR}${NAMESPACE} update${RESET}                                        ${GRAY}# Select interactively${RESET}
  ${CYAN}dr ${FEATURE_COLOR}${NAMESPACE} update ${YELLOW}my-scripts${RESET}                             ${GRAY}# Update specific one${RESET}
  ${CYAN}dr ${FEATURE_COLOR}${NAMESPACE} remove ${YELLOW}my-scripts${RESET}                             ${GRAY}# Remove collection${RESET}
  ${CYAN}dr ${FEATURE_COLOR}${NAMESPACE} --help${RESET}                                        ${GRAY}# Detailed guide${RESET}
EOF
