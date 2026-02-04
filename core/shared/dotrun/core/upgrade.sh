#!/usr/bin/env bash
# Upgrade module for DotRun
# Handles version checking and updates from GitHub releases

set -euo pipefail

# Color codes (standard set matching other modules)
BOLD=$'\e[1m'
CYAN=$'\e[36m'
GREEN=$'\e[32m'
PURPLE=$'\e[35m'
RED=$'\e[31m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
GRAY=$'\e[90m'
RESET=$'\e[0m'

# GitHub configuration
readonly GITHUB_REPO="jvPalma/dotrun"
readonly GITHUB_API_URL="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
readonly INSTALL_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/master/install.sh"

# Timeout settings (in seconds)
readonly CONNECT_TIMEOUT=10
readonly API_TIMEOUT=30
readonly INSTALL_TIMEOUT=120

# Compare two semantic version strings
# Returns 0 if $1 < $2, 1 otherwise
version_less_than() {
    local version1="$1"
    local version2="$2"

    # Handle v prefix
    version1="${version1#v}"
    version2="${version2#v}"

    # Use sort -V for semantic version comparison
    # If version1 appears first in sorted output, it's less than version2
    local sorted
    sorted="$(printf '%s\n%s\n' "$version1" "$version2" | sort -V | head -n1)"

    if [[ "$sorted" == "$version1" ]] && [[ "$version1" != "$version2" ]]; then
        return 0  # version1 < version2
    else
        return 1  # version1 >= version2
    fi
}

# Fetch latest release info from GitHub API
# Returns: "tag_name" or empty string on failure
fetch_latest_release() {
    local response=""
    local exit_code=0

    # Try curl first
    if command -v curl &>/dev/null; then
        response="$(curl -sSL \
            --connect-timeout "$CONNECT_TIMEOUT" \
            --max-time "$API_TIMEOUT" \
            -H "Accept: application/vnd.github.v3+json" \
            "$GITHUB_API_URL" 2>/dev/null)" || exit_code=$?
    # Fallback to wget
    elif command -v wget &>/dev/null; then
        response="$(wget -qO- \
            --timeout="$API_TIMEOUT" \
            --connect-timeout="$CONNECT_TIMEOUT" \
            --header="Accept: application/vnd.github.v3+json" \
            "$GITHUB_API_URL" 2>/dev/null)" || exit_code=$?
    else
        cat >&2 <<EOF
${RED}Error:${RESET} Neither ${CYAN}curl${RESET} nor ${CYAN}wget${RESET} found
${GRAY}Install one of these tools to check for updates${RESET}
EOF
        return 1
    fi

    if [[ $exit_code -ne 0 ]] || [[ -z "$response" ]]; then
        cat >&2 <<EOF
${RED}Error:${RESET} Failed to fetch release information
${GRAY}URL:${RESET} ${YELLOW}$GITHUB_API_URL${RESET}
${GRAY}Troubleshooting:${RESET}
  ${CYAN}1.${RESET} Check internet connection
  ${CYAN}2.${RESET} Verify GitHub API access: ${CYAN}curl -I https://api.github.com${RESET}
  ${CYAN}3.${RESET} Try again later (API rate limit may apply)
EOF
        return 1
    fi

    # Extract tag_name from JSON response
    # Using grep + sed for portability (no jq dependency)
    local tag_name
    tag_name="$(echo "$response" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"

    if [[ -z "$tag_name" ]]; then
        cat >&2 <<EOF
${RED}Error:${RESET} Could not parse release information
${GRAY}Response may be malformed or API format changed${RESET}
EOF
        return 1
    fi

    echo "$tag_name"
    return 0
}

# Check for updates (check-only mode)
upgrade_check() {
    local current_version="${DRUN_VERSION:-unknown}"

    if [[ "$current_version" == "unknown" ]]; then
        cat >&2 <<EOF
${RED}Error:${RESET} Cannot determine current version
${GRAY}DRUN_VERSION variable not set${RESET}
EOF
        return 1
    fi

    echo "${GRAY}Current version:${RESET} ${CYAN}$current_version${RESET}"
    echo "${GRAY}Checking for updates...${RESET}"

    local latest_version
    latest_version="$(fetch_latest_release)" || return 1

    echo "${GRAY}Latest version:${RESET}  ${GREEN}$latest_version${RESET}"
    echo ""

    if version_less_than "$current_version" "$latest_version"; then
        cat <<EOF
${GREEN}${BOLD}Update available!${RESET}

${GRAY}To upgrade, run:${RESET}
  ${CYAN}dr upgrade${RESET}

${GRAY}Or install manually:${RESET}
  ${CYAN}bash <(curl -sL $INSTALL_URL)${RESET}

${GRAY}Release notes:${RESET}
  ${YELLOW}https://github.com/${GITHUB_REPO}/releases/tag/${latest_version}${RESET}
EOF
        return 0
    else
        echo "${GREEN}✓ ${BOLD}You're up to date!${RESET}"
        return 0
    fi
}

# Install update with user confirmation
upgrade_install() {
    local current_version="${DRUN_VERSION:-unknown}"

    if [[ "$current_version" == "unknown" ]]; then
        cat >&2 <<EOF
${RED}Error:${RESET} Cannot determine current version
${GRAY}DRUN_VERSION variable not set${RESET}
EOF
        return 1
    fi

    echo "${GRAY}Current version:${RESET} ${CYAN}$current_version${RESET}"
    echo "${GRAY}Checking for updates...${RESET}"

    local latest_version
    latest_version="$(fetch_latest_release)" || return 1

    echo "${GRAY}Latest version:${RESET}  ${GREEN}$latest_version${RESET}"
    echo ""

    # Check if update needed
    if ! version_less_than "$current_version" "$latest_version"; then
        echo "${GREEN}✓ ${BOLD}Already up to date!${RESET}"
        return 0
    fi

    # Show upgrade prompt
    cat <<EOF
${YELLOW}${BOLD}Update available: ${current_version} → ${latest_version}${RESET}

${GRAY}This will download and run the installer from:${RESET}
  ${YELLOW}$INSTALL_URL${RESET}

${GRAY}Release notes:${RESET}
  ${YELLOW}https://github.com/${GITHUB_REPO}/releases/tag/${latest_version}${RESET}

EOF

    # Confirmation prompt
    read -rp "${BOLD}Proceed with upgrade? [y/N]:${RESET} " confirmation
    echo ""

    case "$confirmation" in
        [yY]|[yY][eE][sS])
            echo "${GRAY}Downloading installer...${RESET}"

            local installer_script
            local exit_code=0

            # Download installer
            if command -v curl &>/dev/null; then
                installer_script="$(curl -sSL \
                    --connect-timeout "$CONNECT_TIMEOUT" \
                    --max-time "$INSTALL_TIMEOUT" \
                    "$INSTALL_URL" 2>/dev/null)" || exit_code=$?
            elif command -v wget &>/dev/null; then
                installer_script="$(wget -qO- \
                    --timeout="$INSTALL_TIMEOUT" \
                    --connect-timeout="$CONNECT_TIMEOUT" \
                    "$INSTALL_URL" 2>/dev/null)" || exit_code=$?
            else
                cat >&2 <<EOF
${RED}Error:${RESET} Neither ${CYAN}curl${RESET} nor ${CYAN}wget${RESET} found
${GRAY}Install one of these tools to upgrade${RESET}
EOF
                return 1
            fi

            if [[ $exit_code -ne 0 ]] || [[ -z "$installer_script" ]]; then
                cat >&2 <<EOF
${RED}Error:${RESET} Failed to download installer
${GRAY}URL:${RESET} ${YELLOW}$INSTALL_URL${RESET}
${GRAY}Troubleshooting:${RESET}
  ${CYAN}1.${RESET} Check internet connection
  ${CYAN}2.${RESET} Try manual install: ${CYAN}bash <(curl -sL $INSTALL_URL)${RESET}
EOF
                return 1
            fi

            echo "${GRAY}Running installer...${RESET}"
            echo ""

            # Execute installer
            bash <(echo "$installer_script") || {
                cat >&2 <<EOF

${RED}Error:${RESET} Installation failed
${GRAY}Please check the error messages above${RESET}
EOF
                return 1
            }

            cat <<EOF

${GREEN}✓ ${BOLD}Upgrade complete!${RESET}
${GRAY}Restart your shell or run:${RESET} ${CYAN}dr reload${RESET}
EOF
            return 0
            ;;
        *)
            echo "${GRAY}Upgrade cancelled${RESET}"
            return 0
            ;;
    esac
}

# Main upgrade command entry point
cmd_upgrade() {
    local check_only=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check)
                check_only=true
                shift
                ;;
            --help|-h)
                exec "${SHARED_DR_HELP_MESSAGES_PATH:-${BASH_SOURCE[0]%/core/*}/core/help-messages}/upgrade/no-args.sh"
                ;;
            *)
                cat >&2 <<EOF
${RED}Error:${RESET} Unknown option: ${YELLOW}$1${RESET}

${GRAY}Usage:${RESET} ${CYAN}dr upgrade${RESET} ${YELLOW}[--check]${RESET}
${GRAY}Help:${RESET}  ${CYAN}dr upgrade --help${RESET}
EOF
                return 1
                ;;
        esac
    done

    # Execute appropriate mode
    if [[ "$check_only" == true ]]; then
        upgrade_check
    else
        upgrade_install
    fi
}

