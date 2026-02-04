#!/usr/bin/env bash
# Help messages for: dr upgrade network errors
# Usage: network-errors.sh <error-type>

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

error_type="${1:-}"

case "$error_type" in
  api-failure)
    cat >&2 <<EOF
${RED}Error:${RESET} Failed to fetch latest version from GitHub API

${GRAY}Possible causes:${RESET}
  1. No internet connection
  2. GitHub API rate limit exceeded
  3. GitHub service unavailable

${GRAY}Troubleshooting:${RESET}
  ${BOLD}Check connection:${RESET}
    ${CYAN}ping -c 1 github.com${RESET}

  ${BOLD}Check API status:${RESET}
    ${CYAN}curl -s https://www.githubstatus.com/${RESET}

  ${BOLD}Manual upgrade:${RESET}
    ${CYAN}curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh | bash${RESET}

  ${BOLD}Try again later:${RESET}
    API rate limits reset after 60 minutes
EOF
    ;;

  install-failure)
    cat >&2 <<EOF
${RED}Error:${RESET} Failed to download or execute installer

${GRAY}Possible causes:${RESET}
  1. Network interruption during download
  2. Installer script unavailable
  3. Insufficient permissions

${GRAY}Troubleshooting:${RESET}
  ${BOLD}Manual installation:${RESET}
    ${CYAN}curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh | bash${RESET}

  ${BOLD}Check permissions:${RESET}
    Ensure ${YELLOW}~/.local/share/dotrun/${RESET} is writable

  ${BOLD}Download installer first:${RESET}
    ${CYAN}curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh -o /tmp/dr-install.sh${RESET}
    ${CYAN}bash /tmp/dr-install.sh${RESET}
EOF
    ;;

  no-downloader)
    cat >&2 <<EOF
${RED}Error:${RESET} No download tool available

${GRAY}Required:${RESET}
  Either ${YELLOW}curl${RESET} or ${YELLOW}wget${RESET} must be installed

${GRAY}Install a download tool:${RESET}
  ${BOLD}Ubuntu/Debian:${RESET}
    ${CYAN}sudo apt install curl${RESET}

  ${BOLD}Fedora/RHEL:${RESET}
    ${CYAN}sudo dnf install curl${RESET}

  ${BOLD}macOS:${RESET}
    ${CYAN}brew install curl${RESET}

${GRAY}Then retry:${RESET}
  ${CYAN}dr upgrade${RESET}
EOF
    ;;

  *)
    cat >&2 <<EOF
${RED}Error:${RESET} Unknown network error type: ${error_type}
EOF
    exit 1
    ;;
esac
