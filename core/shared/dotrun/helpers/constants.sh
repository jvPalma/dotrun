#!/usr/bin/env bash
# shellcheck disable=SC2155,SC2034

# =============================================================================
# DotRun Constants - Single Source of Truth
# =============================================================================
# This file defines shared constants for icons, colors, and paths used across
# all DotRun features (scripts, aliases, configs, collections).
#
# Usage: source "${SHARED_DR_HELPERS_PATH}/constants.sh"
# =============================================================================

# Prevent double-sourcing
[[ -n "${_DR_CONSTANTS_LOADED:-}" ]] && return 0
_DR_CONSTANTS_LOADED=1

# =============================================================================
# PATHS
# =============================================================================
# Base paths (these should already be set by dr, but provide defaults)
DR_CONFIG="${DR_CONFIG:-$HOME/.config/dotrun}"
SHARED_DR_PATH="${SHARED_DR_PATH:-$HOME/.local/share/dotrun}"

# User collection paths
export USER_COLLECTION_PATH="${DR_CONFIG}"
export USER_COLLECTION_SCRIPTS="${USER_COLLECTION_PATH}/scripts"
export USER_COLLECTION_ALIASES="${USER_COLLECTION_PATH}/aliases"
export USER_COLLECTION_CONFIGS="${USER_COLLECTION_PATH}/configs"
export USER_COLLECTION_HELPERS="${USER_COLLECTION_PATH}/helpers"

# =============================================================================
# ICONS (Unicode emoji - single source of truth)
# =============================================================================
export FOLDER_ICON='📁'
export SCRIPT_ICON='🚀'
export ALIAS_ICON='🎭'
export CONFIG_ICON='⚙'

# =============================================================================
# COLORS (ANSI escape codes)
# =============================================================================
# Feature colors (for file names in tree display)
export COLOR_SCRIPTS="\033[1;92m"   # Bright Green
export COLOR_ALIASES="\033[1;35m"   # Bright Purple
export COLOR_CONFIGS="\033[1;31m"   # Bright Red
export COLOR_COLLECTIONS="\033[1;34m" # Bright Blue

# Common colors
export COLOR_FOLDER="\033[1;33m"    # Bright Yellow (for folder names)
export COLOR_DOC="\033[0;37m"       # Gray (for documentation)
export COLOR_BOLD="\033[1m"         # Bold
export COLOR_RESET="\033[0m"        # Reset

# Tree depth colors (cycling palette for tree connectors)
export TREE_COLORS=(
  "\033[38;5;33m"   # Bright Blue
  "\033[38;5;35m"   # Bright Cyan
  "\033[38;5;141m"  # Bright Magenta
  "\033[38;5;214m"  # Orange
  "\033[38;5;228m"  # Yellow
  "\033[38;5;121m"  # Green
)

# =============================================================================
# FILE EXTENSIONS
# =============================================================================
export EXT_SCRIPTS=".sh"
export EXT_ALIASES=".aliases"
export EXT_CONFIGS=".config"

# =============================================================================
# FEATURE LOOKUP FUNCTIONS
# =============================================================================

# Get the base directory for a feature
# Usage: get_feature_dir scripts|aliases|configs
get_feature_dir() {
  local feature="$1"
  case "$feature" in
    scripts) echo "$USER_COLLECTION_SCRIPTS" ;;
    aliases) echo "$USER_COLLECTION_ALIASES" ;;
    configs) echo "$USER_COLLECTION_CONFIGS" ;;
    *) echo "Error: Unknown feature '$feature'" >&2; return 1 ;;
  esac
}

# Get the icon for a feature
# Usage: get_feature_icon scripts|aliases|configs
get_feature_icon() {
  local feature="$1"
  case "$feature" in
    scripts) echo "$SCRIPT_ICON" ;;
    aliases) echo "$ALIAS_ICON" ;;
    configs) echo "$CONFIG_ICON" ;;
    *) echo "?" ;;
  esac
}

# Get the color for a feature
# Usage: get_feature_color scripts|aliases|configs
get_feature_color() {
  local feature="$1"
  case "$feature" in
    scripts) echo "$COLOR_SCRIPTS" ;;
    aliases) echo "$COLOR_ALIASES" ;;
    configs) echo "$COLOR_CONFIGS" ;;
    *) echo "$COLOR_RESET" ;;
  esac
}

# Get the file extension for a feature
# Usage: get_feature_ext scripts|aliases|configs
get_feature_ext() {
  local feature="$1"
  case "$feature" in
    scripts) echo "$EXT_SCRIPTS" ;;
    aliases) echo "$EXT_ALIASES" ;;
    configs) echo "$EXT_CONFIGS" ;;
    *) echo "" ;;
  esac
}
