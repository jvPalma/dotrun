#!/usr/bin/env bash
# Conflict resolution menu for collection updates
# Usage: conflict-menu.sh <rel_path>

BOLD=$'\e[1m'
CYAN=$'\e[36m'
GREEN=$'\e[32m'
PURPLE=$'\e[35m'
RED=$'\e[31m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
GRAY=$'\e[90m'
RESET=$'\e[0m'

rel_path="${1:-file}"

cat <<EOF

$rel_path: ${YELLOW}⚠️  LOCAL CHANGES DETECTED${RESET}
  Your version: Modified locally

  [${CYAN}K${RESET}]eep yours (skip update)
  [${CYAN}O${RESET}]verwrite with collection version
  [${CYAN}D${RESET}]iff (show changes)
  [${CYAN}B${RESET}]ackup yours, then overwrite

EOF
