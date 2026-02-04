#!/usr/bin/env bash
# Help message for: dr -s / dr scripts (no valid subcommand)

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

NAMESPACE="${1:-scripts}"
FEATURE_COLOR="${GREEN}"

USAGE_LINE="${GRAY}Usage: ${RESET}${CYAN}dr ${FEATURE_COLOR}${NAMESPACE}${RESET} ${GRAY}<command> [args]${RESET}"
COMMANDS_HEADER="${GRAY}Commands:${RESET}"
EXAMPLES_HEADER="${GRAY}Examples:${RESET}"

cat <<EOF
${USAGE_LINE}
       ${CYAN}dr ${FEATURE_COLOR}${NAMESPACE}${RESET} ${YELLOW}<scriptname>${RESET}  ${GRAY}(runs the script)${RESET}

${GRAY}Default: Runs the script (no command needed)${RESET}

${COMMANDS_HEADER}
  ${YELLOW}<scriptname>${RESET}        Run script ${GRAY}(default action)${RESET}
  ${FEATURE_COLOR}set${RESET} ${YELLOW}<name>${RESET}          Create or open a script in editor
  ${FEATURE_COLOR}move${RESET} ${YELLOW}<src> <dst>${RESET}    Move/rename a script
  ${FEATURE_COLOR}rm${RESET} ${YELLOW}<name>${RESET}           Remove a script
  ${FEATURE_COLOR}help${RESET} ${YELLOW}<name>${RESET}         Show script documentation

${GRAY}Use 'dr -l' or 'dr -L' to list scripts.${RESET}

${EXAMPLES_HEADER}
  ${CYAN}dr ${FEATURE_COLOR}${NAMESPACE} ${YELLOW}myScript${RESET}          ${GRAY}# Runs myScript${RESET}
  ${CYAN}dr ${FEATURE_COLOR}${NAMESPACE} set ${YELLOW}myScript${RESET}      ${GRAY}# Opens myScript in editor${RESET}
  ${CYAN}dr ${FEATURE_COLOR}${NAMESPACE} move ${YELLOW}old new${RESET}      ${GRAY}# Renames script${RESET}
  ${CYAN}dr ${FEATURE_COLOR}${NAMESPACE} rm ${YELLOW}myScript${RESET}       ${GRAY}# Removes script${RESET}
  ${CYAN}dr ${FEATURE_COLOR}${NAMESPACE} help ${YELLOW}myScript${RESET}     ${GRAY}# Shows documentation${RESET}
EOF
