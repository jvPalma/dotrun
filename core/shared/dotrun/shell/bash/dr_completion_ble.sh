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
_dr_color_green=$'\e[32m'      # Green (script names)
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

  # Check if we're after -s/scripts with a search pattern
  local prev_word="${comp_words[comp_cword - 1]-}"
  local is_script_search=0
  [[ "$prev_word" == "-s" || "$prev_word" == "scripts" ]] && [[ -n "$cur" ]] && is_script_search=1

  # Show hint at root level only
  if [[ -z "$context" ]] && [[ ${comp_cword} -eq 1 ]]; then
    local hint="${_dr_color_gray}💡 (hint: run (default), set, move, rm, help, -l, -L)${_dr_color_reset}"
    ble/complete/cand/yield word "" "$hint"

    # Global reload command
    ble/complete/cand/yield word "reload" "🔄 reload"
  fi

  # Generate folder and script completions
  if [[ -d "$search_dir" ]]; then
    local strip_prefix="${search_dir%/}/"

    # If doing script search with pattern, search recursively
    if [[ $is_script_search -eq 1 ]]; then
      # Extract the search pattern from current word (handle folder prefix)
      local pattern="${cur##*/}"

      # Find all scripts recursively that match the pattern
      local -a results=()
      while IFS= read -r -d '' file; do
        local fullpath="${file#"$BIN_DIR/"}"
        fullpath="${fullpath%.sh}"

        # Extract just the filename to check pattern match
        local basename="${fullpath##*/}"
        if [[ "$basename" == "$pattern"* ]]; then
          # Count depth (number of slashes)
          local depth="${fullpath//[^\/]/}"
          depth="${#depth}"
          # Store as "depth:fullpath" for sorting
          results+=("$depth:$fullpath")
        fi
      done < <(find "$BIN_DIR" -type f -name "*.sh" -print0 2>/dev/null)

      # Sort by depth (least folders first) and display
      while IFS=: read -r depth fullpath; do
        # Split path into folder and script name
        if [[ "$fullpath" == */* ]]; then
          local folder="${fullpath%/*}/"
          local scriptname="${fullpath##*/}"
          local display="${_dr_color_yellow}${folder}${_dr_color_reset}${_dr_color_green}${scriptname}${_dr_color_reset}"
        else
          local scriptname="$fullpath"
          local display="${_dr_color_green}${scriptname}${_dr_color_reset}"
        fi
        ble/complete/cand/yield word "$fullpath" "$display"
      done < <(printf '%s\n' "${results[@]}" | sort -t: -k1,1n -k2)

    else
      # Normal completion: show only current directory level

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
  fi

  # Management commands (position 2)
  if [[ ${comp_cword} -eq 2 ]]; then
    case "${comp_words[1]}" in
      -s | scripts)
        ble/complete/cand/yield word "set" "➕ set"
        ble/complete/cand/yield word "move" "🔀 move"
        ble/complete/cand/yield word "rm" "🗑️  rm"
        ble/complete/cand/yield word "help" "❓ help"
        ;;
      -a | aliases)
        ble/complete/cand/yield word "move" "🔀 move"
        ble/complete/cand/yield word "rm" "🗑️  rm"
        ble/complete/cand/yield word "help" "❓ help"
        ble/complete/cand/yield word "init" "🆕 init"
        ble/complete/cand/yield word "-l" "📋 list (short)"
        ble/complete/cand/yield word "-L" "📋 list (long)"
        ;;
      -c | config)
        ble/complete/cand/yield word "move" "🔀 move"
        ble/complete/cand/yield word "rm" "🗑️  rm"
        ble/complete/cand/yield word "help" "❓ help"
        ble/complete/cand/yield word "init" "🆕 init"
        ble/complete/cand/yield word "-l" "📋 list (short)"
        ble/complete/cand/yield word "-L" "📋 list (long)"
        ;;
    esac
  fi
}
