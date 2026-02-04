#!/usr/bin/env bash
# Help messages for: dr upgrade --check results
# Usage: check-result.sh <status> [current-version] [latest-version]

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

status="${1:-}"
current_version="${2:-}"
latest_version="${3:-}"

case "$status" in
  up-to-date)
    cat <<EOF
${GREEN}✓${RESET} ${BOLD}DotRun is up to date${RESET}

${GRAY}Current version:${RESET} ${GREEN}${current_version}${RESET}
${GRAY}Latest version:${RESET}  ${GREEN}${latest_version}${RESET}

${GRAY}You're running the latest release.${RESET}
EOF
    ;;

  update-available)
    cat <<EOF
${YELLOW}⚠${RESET} ${BOLD}Update available${RESET}

${GRAY}Current version:${RESET} ${YELLOW}${current_version}${RESET}
${GRAY}Latest version:${RESET}  ${GREEN}${latest_version}${RESET}

${GRAY}To upgrade, run:${RESET}
  ${CYAN}dr upgrade${RESET}

${GRAY}What's new:${RESET}
  View the changelog at ${BLUE}https://github.com/jvPalma/dotrun/releases/tag/${latest_version}${RESET}
EOF
    ;;

  *)
    cat >&2 <<EOF
${BOLD}${GRAY}Unknown check status: ${status}${RESET}
EOF
    exit 1
    ;;
esac
