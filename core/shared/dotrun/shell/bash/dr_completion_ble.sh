#!/usr/bin/env bash

# ble.sh completion for dr with colored, emoji-decorated completion (ble.sh 0.4 API)

# Abort quietly if ble.sh is not loaded yet
[[ ${BLE_VERSION-} ]] || return 0

# ============================================================================
# BLE.SH SETTINGS
# ============================================================================

# Show descriptions with colors
bleopt complete_menu_style=desc

# Enable colored completion menu
bleopt complete_menu_color=on

# ============================================================================
# ANSI COLOR CODES (for inline formatting)
# ============================================================================

# Using ANSI escape codes directly in display text
_dr_color_gray=$'\e[38;5;240m' # Gray (hint)
_dr_color_yellow=$'\e[33m'     # Yellow (folders)
_dr_color_cyan=$'\e[36m'       # Cyan (scripts)
_dr_color_reset=$'\e[m'        # Reset

# ============================================================================
# CUSTOM COMPLETION FUNCTION (ble.sh 0.4 API: ble/cmdinfo/complete:COMMAND)
# ============================================================================

function ble/cmdinfo/complete:dr {
  local BIN_DIR="${DR_CONFIG:-$HOME/.config/dotrun}/scripts"

  # Get current word and determine folder context
  local cur="${comp_words[comp_cword]-}"
  local context=""
  [[ "$cur" == */* ]] && context="${cur%/*}/"

  local search_dir="$BIN_DIR"
  [[ -n "$context" ]] && search_dir="$BIN_DIR/$context"

  # Show hint at root level only
  if [[ -z "$context" ]] && [[ ${comp_cword} -eq 1 ]]; then
    local hint="${_dr_color_gray}💡 (hint: -s/scripts, -a/aliases, -c/config, -col/collections)${_dr_color_reset}"
    ble/complete/cand/yield word "" "$hint"
  fi

  # Generate folder and script completions
  if [[ -d "$search_dir" ]]; then
    local strip_prefix="${search_dir%/}/"

    # Folders (yellow 📁)
    # Left: plain text to insert, Right: colored emoji to display
    while IFS= read -r -d '' dir; do
      local dirname="${dir#"$strip_prefix"}"
      dirname="${dirname%/}"
      if [[ -n "$dirname" ]]; then
        local display="${_dr_color_yellow}📁 ${dirname}/${_dr_color_reset}"
        ble/complete/cand/yield word "${context}${dirname}/" "$display"
      fi
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print0 2>/dev/null | sort -z)

    # Scripts (cyan ⚙)
    # Left: plain text to insert, Right: colored emoji to display
    while IFS= read -r -d '' file; do
      local filename="${file#"$strip_prefix"}"
      filename="${filename%.sh}"
      if [[ -n "$filename" ]]; then
        local display="${_dr_color_cyan}⚙ ${filename}${_dr_color_reset}"
        ble/complete/cand/yield word "${context}${filename}" "$display"
      fi
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type f -name "*.sh" -print0 2>/dev/null | sort -z)
  fi

  # Management commands (position 2)
  if [[ ${comp_cword} -eq 2 ]]; then
    case "${comp_words[1]}" in
      -s | scripts)
        ble/complete/cand/yield word "add" "➕ add"
        ble/complete/cand/yield word "edit" "✏️  edit"
        ble/complete/cand/yield word "move" "🔀 move"
        ble/complete/cand/yield word "rename" "📝 rename"
        ble/complete/cand/yield word "help" "❓ help"
        ble/complete/cand/yield word "list" "📋 list"
        ;;
      -a | aliases)
        ble/complete/cand/yield word "init" "🆕 init"
        ble/complete/cand/yield word "add" "➕ add"
        ble/complete/cand/yield word "list" "📋 list"
        ble/complete/cand/yield word "edit" "✏️  edit"
        ble/complete/cand/yield word "remove" "🗑️  remove"
        ble/complete/cand/yield word "reload" "🔄 reload"
        ;;
      -c | config)
        ble/complete/cand/yield word "init" "🆕 init"
        ble/complete/cand/yield word "set" "💾 set"
        ble/complete/cand/yield word "get" "🔍 get"
        ble/complete/cand/yield word "list" "📋 list"
        ble/complete/cand/yield word "edit" "✏️  edit"
        ble/complete/cand/yield word "unset" "🗑️  unset"
        ble/complete/cand/yield word "reload" "🔄 reload"
        ;;
    esac
  fi
}
