#!/usr/bin/env bash
# Help messages for: git-related collection errors
# Usage: git-errors.sh <error-type> [dynamic-vars...]

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
shift

case "$error_type" in
  clone-timeout-30)
    url="$1"
    cat >&2 <<EOF
${GRAY}Reason:${RESET} Operation timed out after 30 seconds

${GRAY}Possible causes:${RESET}
  • Network connectivity issues
  • Very large repository
  • Slow connection

${GRAY}Troubleshooting steps:${RESET}
  1. Check your internet connection
  2. Try again later
  3. Clone manually first: ${CYAN}git clone ${YELLOW}$url${RESET} ~/temp-clone
  4. Then add from local path: ${CYAN}dr -col add${RESET} ~/temp-clone
EOF
    ;;
  clone-timeout-60)
    url="$1"
    dest="$2"
    cat >&2 <<EOF
${GRAY}Reason:${RESET} Operation timed out after 60 seconds

${GRAY}This may indicate:${RESET}
  • Large repository size
  • Network connectivity issues

${GRAY}Recovery options:${RESET}
  1. Clone manually: ${CYAN}git clone ${YELLOW}$url $dest${RESET}
  2. Try again with better connection
  3. Contact repository owner about size
EOF
    ;;
  not-git-repo)
    collection_dir="$1"
    cat >&2 <<EOF
${RED}Error:${RESET} Not a git repository: ${YELLOW}$collection_dir${RESET}
Directory: $collection_dir

The collection directory may have been corrupted or moved.

${GRAY}Recovery options:${RESET}
  1. Remove and re-add the collection
  2. Check if the directory exists: ${CYAN}ls -la $collection_dir${RESET}
EOF
    ;;
  fetch-timeout)
    collection_dir="$1"
    cat >&2 <<EOF
${GRAY}Reason:${RESET} Operation timed out after 30 seconds

${GRAY}Possible causes:${RESET}
  • Network connectivity issues
  • Remote server not responding

${GRAY}Troubleshooting:${RESET}
  1. Check internet connection
  2. Try again later
  3. Test remote access: ${CYAN}cd $collection_dir && git fetch origin --dry-run${RESET}
EOF
    ;;
  cannot-access-repo)
    url="$1"
    owner_repo="$2"
    cat >&2 <<EOF
${RED}Error:${RESET} Cannot access repository: ${CYAN}$owner_repo${RESET}

${YELLOW}This may be because:${RESET}
  ${GRAY}1.${RESET} Repository is private and you're not authenticated
  ${GRAY}2.${RESET} Repository doesn't exist
  ${GRAY}3.${RESET} URL is incorrect

${BOLD}For private repositories, use one of these options:${RESET}

${BOLD}Option 1:${RESET} Use SSH URL ${GRAY}(requires SSH keys configured)${RESET}
  ${CYAN}dr -col add git@github.com:$owner_repo.git${RESET}

${BOLD}Option 2:${RESET} Authenticate with GitHub CLI
  ${CYAN}gh auth login${RESET}
  ${CYAN}dr -col add $url${RESET}

${BOLD}Option 3:${RESET} Configure Git credentials
  ${CYAN}git config --global credential.helper store${RESET}
  ${GRAY}# Then manually clone once to save credentials${RESET}

${BOLD}Option 4:${RESET} Use local path ${GRAY}(if repo already cloned)${RESET}
  ${CYAN}dr -col add ~/dotrun-anc${RESET}
EOF
    ;;
esac
