#!/usr/bin/env bash
# Help message for: loadHelpers (no arguments)

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

FEATURE_COLOR="${CYAN}"

cat <<EOF
${GRAY}Usage: ${RESET}${FEATURE_COLOR}loadHelpers${RESET} ${YELLOW}<pattern>${RESET} ${GRAY}[--list]${RESET}

${GRAY}Patterns (from most to least specific):${RESET}
  ${FEATURE_COLOR}loadHelpers ${YELLOW}01-dotrun-anc/gcp/workstation.sh${RESET}  ${GRAY}# Exact with namespace${RESET}
  ${FEATURE_COLOR}loadHelpers ${YELLOW}01-dotrun-anc/gcp/workstation${RESET}     ${GRAY}# Namespace + path${RESET}
  ${FEATURE_COLOR}loadHelpers ${YELLOW}dotrun-anc/gcp/workstation${RESET}        ${GRAY}# Collection name${RESET}
  ${FEATURE_COLOR}loadHelpers ${YELLOW}gcp/workstation${RESET}                   ${GRAY}# Path (searches all)${RESET}
  ${FEATURE_COLOR}loadHelpers ${YELLOW}workstation${RESET}                       ${GRAY}# Filename only${RESET}

${GRAY}Special:${RESET}
  ${FEATURE_COLOR}loadHelpers ${YELLOW}@dotrun-anc${RESET}                       ${GRAY}# Load all from collection${RESET}
  ${FEATURE_COLOR}loadHelpers ${YELLOW}<pattern>${RESET} ${BLUE}--list${RESET}                  ${GRAY}# Preview matches${RESET}

${GRAY}Environment:${RESET}
  ${PURPLE}DR_HELPERS_VERBOSE${RESET}=${GREEN}1${RESET}  ${GRAY}# Enable verbose output${RESET}
  ${PURPLE}DR_HELPERS_QUIET${RESET}=${GREEN}1${RESET}    ${GRAY}# Suppress non-error output${RESET}
EOF
