#!/usr/bin/env bash
# shellcheck disable=SC2155

# ble.sh completion for dr — mirrors zsh reference with full color/emoji support (ble.sh 0.4 API)

# Abort quietly if ble.sh is not loaded yet
[[ ${BLE_VERSION-} ]] || return 0

# ============================================================================
# BLE.SH SETTINGS
# ============================================================================

bleopt complete_menu_style=desc
bleopt complete_menu_color=on

# ============================================================================
# ICON CONSTANTS (matching zsh SINGLE SOURCE OF TRUTH)
# ============================================================================

_dr_icon_folder='📁'
_dr_icon_script='🚀'
_dr_icon_alias='🎭'
_dr_icon_config='⚙'

# ============================================================================
# ANSI COLOR CODES (matching zsh color scheme)
# ============================================================================

_dr_color_gray=$'\e[38;5;240m'   # Gray (hints)
_dr_color_yellow=$'\e[33m'       # Yellow (folders)
_dr_color_green=$'\e[32m'        # Green (scripts)
_dr_color_purple=$'\e[35m'       # Purple (aliases)
_dr_color_red=$'\e[31m'          # Red (configs)
_dr_color_blue=$'\e[34m'         # Blue (collections)
_dr_color_reset=$'\e[m'          # Reset

# ============================================================================
# UNIFIED FILESYSTEM FINDER (mirrors zsh _dr_global_filesystem_find)
# ============================================================================
# _dr_ble_filesystem_find <context> <type> <depth> [subcontext] [pattern]
_dr_ble_filesystem_find() {
  local context="$1" type="$2" depth="$3"
  local subcontext="${4:-}" pattern="${5:-}"

  local base_dir ext
  case "$context" in
    scripts)  base_dir="${DR_CONFIG:-$HOME/.config/dotrun}/scripts";  ext=".sh" ;;
    aliases)  base_dir="${DR_CONFIG:-$HOME/.config/dotrun}/aliases";  ext=".aliases" ;;
    configs)  base_dir="${DR_CONFIG:-$HOME/.config/dotrun}/configs";  ext=".config" ;;
    *) return 1 ;;
  esac

  local search_dir="$base_dir"
  [[ -n "$subcontext" ]] && search_dir="$base_dir/${subcontext%/}"
  [[ ! -d "$search_dir" ]] && return 0

  local -a find_args=("$search_dir" -mindepth 1)
  [[ "$depth" == "single" ]] && find_args+=(-maxdepth 1)

  find_args+=(-name '.*' -prune -o)

  case "$type" in
    file)      find_args+=(-type f) ;;
    directory) find_args+=(-type d) ;;
  esac

  [[ "$type" == "file" && -n "$ext" ]] && find_args+=(-name "*${ext}")
  [[ -n "$pattern" ]] && find_args+=(-ipath "*${pattern}*")
  find_args+=(-print0)

  local strip_prefix="${search_dir%/}/"
  local item rel_path

  while IFS= read -r -d '' item; do
    rel_path="${item#"${strip_prefix}"}"
    [[ -z "$rel_path" ]] && continue

    if [[ -d "$item" ]]; then
      echo "${rel_path%/}/"
    else
      [[ -n "$ext" ]] && rel_path="${rel_path%"${ext}"}"
      echo "$rel_path"
    fi
  done < <(find "${find_args[@]}" 2>/dev/null | sort -z)
}

# ============================================================================
# HELPER: Get context path from word
# ============================================================================
_dr_ble_get_context_path() {
  local word="$1"
  if [[ "$word" == */* ]]; then
    echo "${word%/*}/"
  else
    echo ""
  fi
}

# ============================================================================
# HELPER: Get icon and color for a feature
# ============================================================================
_dr_ble_feature_icon() {
  case "$1" in
    scripts) echo "$_dr_icon_script" ;;
    aliases) echo "$_dr_icon_alias" ;;
    configs) echo "$_dr_icon_config" ;;
    *) echo "📄" ;;
  esac
}

_dr_ble_feature_color() {
  case "$1" in
    scripts) echo "$_dr_color_green" ;;
    aliases) echo "$_dr_color_purple" ;;
    configs) echo "$_dr_color_red" ;;
    *) echo "$_dr_color_reset" ;;
  esac
}

# ============================================================================
# HELPER: Emit feature context (folders + files) with colors
# ============================================================================
# _dr_ble_emit_feature_context <feature> <subcontext> <prefix>
_dr_ble_emit_feature_context() {
  local feature="$1" subcontext="$2" prefix="$3"
  local icon=$(_dr_ble_feature_icon "$feature")
  local color=$(_dr_ble_feature_color "$feature")

  # Folders (yellow)
  while IFS= read -r item; do
    [[ -n "$item" ]] && ble/complete/cand/yield word "${prefix}${item}" \
      "${_dr_color_yellow}${_dr_icon_folder} ${item}${_dr_color_reset}"
  done < <(_dr_ble_filesystem_find "$feature" directory single "$subcontext")

  # Files (feature color)
  while IFS= read -r item; do
    [[ -n "$item" ]] && ble/complete/cand/yield word "${prefix}${item}" \
      "${color}${icon} ${item}${_dr_color_reset}"
  done < <(_dr_ble_filesystem_find "$feature" file single "$subcontext")
}

# ============================================================================
# HELPER: Emit recursive search results with fullpath coloring
# ============================================================================
# _dr_ble_emit_recursive_search <feature> <pattern>
_dr_ble_emit_recursive_search() {
  local feature="$1" pattern="$2"
  local icon=$(_dr_ble_feature_icon "$feature")
  local color=$(_dr_ble_feature_color "$feature")

  # Folders
  while IFS= read -r item; do
    if [[ -n "$item" ]]; then
      local path_no_slash="${item%/}"
      if [[ "$path_no_slash" == */* ]]; then
        local parent="${path_no_slash%/*}/"
        local dirname="${path_no_slash##*/}"
        ble/complete/cand/yield word "$item" \
          "${_dr_color_yellow}${parent}${_dr_icon_folder} ${dirname}/${_dr_color_reset}"
      else
        ble/complete/cand/yield word "$item" \
          "${_dr_color_yellow}${_dr_icon_folder} ${item}${_dr_color_reset}"
      fi
    fi
  done < <(_dr_ble_filesystem_find "$feature" directory all "" "$pattern")

  # Files
  while IFS= read -r item; do
    if [[ -n "$item" ]]; then
      if [[ "$item" == */* ]]; then
        local folder="${item%/*}/"
        local filename="${item##*/}"
        ble/complete/cand/yield word "$item" \
          "${_dr_color_yellow}${folder}${color}${icon} ${filename}${_dr_color_reset}"
      else
        ble/complete/cand/yield word "$item" \
          "${color}${icon} ${item}${_dr_color_reset}"
      fi
    fi
  done < <(_dr_ble_filesystem_find "$feature" file all "" "$pattern")
}

# ============================================================================
# HELPER: Emit folders-only with coloring
# ============================================================================
_dr_ble_emit_folders_only() {
  local feature="$1" subcontext="${2:-}" prefix="${3:-}"

  while IFS= read -r item; do
    [[ -n "$item" ]] && ble/complete/cand/yield word "${prefix}${item}" \
      "${_dr_color_yellow}${_dr_icon_folder} ${item}${_dr_color_reset}"
  done < <(_dr_ble_filesystem_find "$feature" directory single "$subcontext")
}

# ============================================================================
# HELPER: Complete feature with hierarchical navigation or recursive search
# ============================================================================
_dr_ble_complete_feature() {
  local feature="$1" cur="$2"

  if [[ "$cur" == */* ]]; then
    local context_path=$(_dr_ble_get_context_path "$cur")
    _dr_ble_emit_feature_context "$feature" "$context_path" "$context_path"
  elif [[ -n "$cur" && "$cur" != -* ]]; then
    _dr_ble_emit_recursive_search "$feature" "$cur"
  else
    _dr_ble_emit_feature_context "$feature" "" ""
  fi
}

# ============================================================================
# HELPER: Complete folder filter for -l/-L commands
# ============================================================================
_dr_ble_complete_list_filter() {
  local feature="$1" cur="$2"

  if [[ "$cur" == */* ]]; then
    local context_path=$(_dr_ble_get_context_path "$cur")
    _dr_ble_emit_folders_only "$feature" "$context_path" "$context_path"
  else
    _dr_ble_emit_folders_only "$feature" "" ""
  fi
}

# ============================================================================
# HELPER: Emit commands with color
# ============================================================================
_dr_ble_emit_commands() {
  local color="$1"
  shift
  local cmd desc
  for item in "$@"; do
    cmd="${item%%:*}"
    desc="${item#*:}"
    ble/complete/cand/yield word "$cmd" "${color}${cmd}${_dr_color_reset} -- ${_dr_color_gray}${desc}${_dr_color_reset}"
  done
}

# ============================================================================
# MAIN COMPLETION FUNCTION (ble.sh 0.4 API)
# ============================================================================

function ble/cmdinfo/complete:dr {
  local cur="${comp_words[comp_cword]-}"
  local cword=$comp_cword

  # Command arrays (matching zsh definitions)
  local -a collections_cmds=(
    "set:Add a new collection"
    "list:List installed collections"
    "sync:Sync installed collections"
    "update:Update collection by given name"
    "list\:details:List collections with detailed information"
    "remove:Remove a collection"
  )

  # Position 1: First argument after dr
  if [[ $cword -eq 1 ]]; then
    if [[ "$cur" == */* ]]; then
      local context_path=$(_dr_ble_get_context_path "$cur")
      _dr_ble_emit_feature_context scripts "$context_path" "$context_path"
    elif [[ -n "$cur" && "$cur" != -* ]]; then
      # Recursive search
      _dr_ble_emit_recursive_search scripts "$cur"
    else
      # Empty TAB: show hint + folders + scripts only (no commands)
      ble/complete/cand/yield word "" \
        "${_dr_color_gray}(hint: run (default), set, move, rm, help, -l, -L)${_dr_color_reset}"
      _dr_ble_emit_feature_context scripts "" ""
    fi
    return 0

  # Position 2: Second argument
  elif [[ $cword -eq 2 ]]; then
    local prev="${comp_words[1]-}"
    case "$prev" in
      -r|reload)
        return 0
        ;;
      -s|scripts)
        # Script management context — same as root dr TAB
        if [[ -z "$cur" || "$cur" == -* ]]; then
          ble/complete/cand/yield word "" \
            "${_dr_color_gray}(hint: run (default), set, move, rm, help, -l, -L)${_dr_color_reset}"
        fi
        _dr_ble_complete_feature scripts "$cur"
        return 0
        ;;
      -a|aliases)
        # Aliases context
        if [[ -z "$cur" || "$cur" == -* ]]; then
          ble/complete/cand/yield word "" \
            "${_dr_color_gray}(hint: add/edit (default), -l, -L, move, rm, help, init)${_dr_color_reset}"
        fi
        _dr_ble_complete_feature aliases "$cur"
        return 0
        ;;
      -c|config)
        # Config context
        if [[ -z "$cur" || "$cur" == -* ]]; then
          ble/complete/cand/yield word "" \
            "${_dr_color_gray}(hint: add/edit (default), -l, -L, move, rm, help, init)${_dr_color_reset}"
        fi
        _dr_ble_complete_feature configs "$cur"
        return 0
        ;;
      -col|collections)
        # Collections commands (blue)
        _dr_ble_emit_commands "$_dr_color_blue" "${collections_cmds[@]}"
        return 0
        ;;
      -l|-L)
        # List with folder filter
        _dr_ble_complete_list_filter scripts "$cur"
        return 0
        ;;
      set)
        # Implicit set
        if [[ "$cur" == */* ]]; then
          local context_path=$(_dr_ble_get_context_path "$cur")
          _dr_ble_emit_feature_context scripts "$context_path" "$context_path"
        else
          _dr_ble_emit_feature_context scripts "" ""
        fi
        return 0
        ;;
      edit|help)
        if [[ "$cur" == */* ]]; then
          local context_path=$(_dr_ble_get_context_path "$cur")
          _dr_ble_emit_feature_context scripts "$context_path" "$context_path"
        else
          _dr_ble_emit_feature_context scripts "" ""
        fi
        return 0
        ;;
      move|rename|mv)
        if [[ "$cur" == */* ]]; then
          local context_path=$(_dr_ble_get_context_path "$cur")
          _dr_ble_emit_feature_context scripts "$context_path" "$context_path"
        else
          _dr_ble_emit_feature_context scripts "" ""
        fi
        return 0
        ;;
      rm)
        if [[ "$cur" == */* ]]; then
          local context_path=$(_dr_ble_get_context_path "$cur")
          _dr_ble_emit_feature_context scripts "$context_path" "$context_path"
        else
          _dr_ble_emit_feature_context scripts "" ""
        fi
        return 0
        ;;
    esac
    return 0

  # Position 3: Third argument
  elif [[ $cword -eq 3 ]]; then
    local word1="${comp_words[1]-}" word2="${comp_words[2]-}"
    case "$word1" in
      move|rename|mv)
        # Destination for implicit move
        if [[ "$cur" == */* ]]; then
          local context_path=$(_dr_ble_get_context_path "$cur")
          _dr_ble_emit_feature_context scripts "$context_path" "$context_path"
        else
          _dr_ble_emit_folders_only scripts
        fi
        ;;
      -s|scripts)
        case "$word2" in
          set|help|rm|move|rename)
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_ble_get_context_path "$cur")
              _dr_ble_emit_feature_context scripts "$context_path" "$context_path"
            else
              _dr_ble_emit_feature_context scripts "" ""
            fi
            ;;
          -l|-L)
            _dr_ble_complete_list_filter scripts "$cur"
            ;;
        esac
        ;;
      -a|aliases)
        case "$word2" in
          move|rm|help)
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_ble_get_context_path "$cur")
              _dr_ble_emit_feature_context aliases "$context_path" "$context_path"
            else
              _dr_ble_emit_feature_context aliases "" ""
            fi
            ;;
          -l|-L)
            _dr_ble_complete_list_filter aliases "$cur"
            ;;
        esac
        ;;
      -c|config)
        case "$word2" in
          set|move|rm|help)
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_ble_get_context_path "$cur")
              _dr_ble_emit_feature_context configs "$context_path" "$context_path"
            else
              _dr_ble_emit_feature_context configs "" ""
            fi
            ;;
          -l|-L)
            _dr_ble_complete_list_filter configs "$cur"
            ;;
          list)
            _dr_ble_emit_commands "$_dr_color_red" \
              "--categories:Show all categories" \
              "--category:Filter by category" \
              "--keys-only:Show only key names"
            ;;
        esac
        ;;
      -col|collections)
        return 0
        ;;
    esac
    return 0

  # Position 4: Fourth argument
  elif [[ $cword -eq 4 ]]; then
    local word1="${comp_words[1]-}" word2="${comp_words[2]-}"
    case "$word1" in
      -s|scripts)
        case "$word2" in
          move|rename)
            # Destination for: dr -s move old <dest>
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_ble_get_context_path "$cur")
              _dr_ble_emit_feature_context scripts "$context_path" "$context_path"
            else
              _dr_ble_emit_folders_only scripts
            fi
            ;;
        esac
        ;;
      -a|aliases)
        case "$word2" in
          move)
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_ble_get_context_path "$cur")
              _dr_ble_emit_feature_context aliases "$context_path" "$context_path"
            else
              _dr_ble_emit_folders_only aliases
            fi
            ;;
        esac
        ;;
      -c|config)
        case "$word2" in
          move)
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_ble_get_context_path "$cur")
              _dr_ble_emit_feature_context configs "$context_path" "$context_path"
            else
              _dr_ble_emit_folders_only configs
            fi
            ;;
        esac
        ;;
    esac
    return 0
  fi

  return 0
}
