#!/usr/bin/env bash
# Help message for: dr upgrade

# Color codes (standard set)
BOLD=$'\e[1m'
CYAN=$'\e[36m'
GREEN=$'\e[32m'
PURPLE=$'\e[35m'
RED=$'\e[31m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
GRAY=$'\e[90m'
RESET=$'\e[0m'

FEATURE_COLOR="${GREEN}"

cat <<EOF
${GRAY}Usage:${RESET} ${CYAN}dr ${FEATURE_COLOR}upgrade${RESET} ${YELLOW}[--check]${RESET}

${GRAY}Description:${RESET}
  Upgrade DotRun to the latest version from GitHub releases.

${GRAY}Options:${RESET}
  ${YELLOW}--check${RESET}      Check for updates without installing
  ${YELLOW}--help${RESET}       Show this help message

${GRAY}Upgrade Process:${RESET}
  1. Fetches the latest release version from GitHub API
  2. Compares with your currently installed version
  3. Downloads and runs the installer if an update is available
  4. Preserves your existing scripts, aliases, and configs

${GRAY}Examples:${RESET}
  ${CYAN}dr ${FEATURE_COLOR}upgrade${RESET}          ${GRAY}# Upgrade to latest version${RESET}
  ${CYAN}dr ${FEATURE_COLOR}upgrade ${YELLOW}--check${RESET}  ${GRAY}# Check if update is available${RESET}

${GRAY}Note:${RESET}
  Your custom scripts in ${YELLOW}~/.config/dotrun/${RESET} are never modified during upgrades.
  The upgrade only updates core DotRun files in ${YELLOW}~/.local/share/dotrun/${RESET}.
EOF
