#!/usr/bin/env bash
# Help message for: dr move (without arguments)

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

COMMAND="${1:-move}"
FEATURE_COLOR="${GREEN}"

USAGE_LINE="${GRAY}Usage: ${RESET}${CYAN}dr ${FEATURE_COLOR}${COMMAND}${GRAY} <source> <destination>"
EXAMPLES_HEADER="${GRAY}Examples:${RESET}"

cat <<EOF
${USAGE_LINE}
${EXAMPLES_HEADER}
  ${CYAN}dr $COMMAND ${GREEN}oldName newName          ${RESET}# Simple rename
  ${CYAN}dr $COMMAND ${GREEN}gitCmd git/gitCmd        ${RESET}# Move to folder
  ${CYAN}dr $COMMAND ${GREEN}folderA/cmd folderB/cmd  ${RESET}# Move between folders
  ${CYAN}dr $COMMAND ${GREEN}oldName folder/newName   ${RESET}# Rename and move
EOF
