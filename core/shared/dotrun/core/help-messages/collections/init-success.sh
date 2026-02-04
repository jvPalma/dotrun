#!/usr/bin/env bash
# Success message for collection init
# Usage: init-success.sh <collection_name> <metadata_file>

BOLD=$'\e[1m'
CYAN=$'\e[36m'
GREEN=$'\e[32m'
PURPLE=$'\e[35m'
RED=$'\e[31m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
GRAY=$'\e[90m'
RESET=$'\e[0m'

COLOR_S="${GREEN}"
COLOR_A="${PURPLE}"
COLOR_H="${BLUE}"
COLOR_C="${RED}"

collection_name="${1:-my-collection}"
metadata_file="${2:-dotrun.collection.yml}"

cat <<EOF

${BOLD}${GREEN}Collection initialized successfully!${RESET}

${BOLD}Next steps:${RESET}
  ${GRAY}1.${RESET} Add your ${COLOR_S}scripts${RESET} to ${COLOR_S}scripts/${RESET}
  ${GRAY}2.${RESET} Add your ${COLOR_A}aliases${RESET} to ${COLOR_A}aliases/${RESET}
  ${GRAY}3.${RESET} Add your ${COLOR_H}helpers${RESET} to ${COLOR_H}helpers/${RESET}
  ${GRAY}4.${RESET} Add your ${COLOR_C}configs${RESET} to ${COLOR_C}configs/${RESET}
  ${GRAY}5.${RESET} Update version in ${CYAN}$metadata_file${RESET}
  ${GRAY}6.${RESET} Commit to git and tag with version: ${CYAN}git tag v0.1.0${RESET}
  ${GRAY}7.${RESET} Push to GitHub for sharing

${BOLD}Structure:${RESET}
  ${CYAN}$collection_name/${RESET}
  ├── ${CYAN}dotrun.collection.yml${RESET}
  ├── ${COLOR_S}scripts/${RESET}
  ├── ${COLOR_A}aliases/${RESET}
  ├── ${COLOR_H}helpers/${RESET}
  └── ${COLOR_C}configs/${RESET}

EOF
