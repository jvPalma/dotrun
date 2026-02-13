#!/usr/bin/env bash
# shellcheck disable=SC2155,SC2207
# Standard bash completion for dr — mirrors zsh reference behavior
# For enhanced visual experience with colors/emojis, use ble.sh version

_dr_autocomplete() {
  local cur prev words cword
  COMPREPLY=()

  # Use _init_completion if available
  if declare -F _init_completion >/dev/null; then
    _init_completion -n : || return
  else
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD - 1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD
  fi

  # Configuration directories
  local BIN_DIR="${DR_CONFIG:-$HOME/.config/dotrun}/scripts"
  local ALIASES_DIR="${DR_CONFIG:-$HOME/.config/dotrun}/aliases"
  local CONFIG_DIR="${DR_CONFIG:-$HOME/.config/dotrun}/configs"

  # ============================================================================
  # UNIFIED FILESYSTEM FINDER (mirrors zsh _dr_global_filesystem_find)
  # ============================================================================
  # _dr_filesystem_find <context> <type> <depth> [subcontext] [pattern]
  #
  # Args:
  #   $1 (context):    'scripts' | 'aliases' | 'configs'
  #   $2 (type):       'file' | 'directory'
  #   $3 (depth):      'single' | 'all'
  #   $4 (subcontext): Optional relative path within context
  #   $5 (pattern):    Optional filter pattern for case-insensitive matching
  #
  # Output: One result per line
  #   - Directories: "dirname/" (with trailing slash)
  #   - Files: "filename" (extension stripped)
  _dr_filesystem_find() {
    local context="$1" type="$2" depth="$3"
    local subcontext="${4:-}" pattern="${5:-}"

    local base_dir ext
    case "$context" in
      scripts)  base_dir="$BIN_DIR";     ext=".sh" ;;
      aliases)  base_dir="$ALIASES_DIR"; ext=".aliases" ;;
      configs)  base_dir="$CONFIG_DIR";  ext=".config" ;;
      *) return 1 ;;
    esac

    local search_dir="$base_dir"
    [[ -n "$subcontext" ]] && search_dir="$base_dir/${subcontext%/}"
    [[ ! -d "$search_dir" ]] && return 0

    local -a find_args=("$search_dir" -mindepth 1)
    [[ "$depth" == "single" ]] && find_args+=(-maxdepth 1)

    # Prune hidden directories
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
  # HELPER: Extract folder context from current word
  # ============================================================================
  _dr_get_context_path() {
    local word="$1"
    if [[ "$word" == */* ]]; then
      echo "${word%/*}/"
    else
      echo ""
    fi
  }

  # ============================================================================
  # HELPER: Emit feature context (folders + files) to COMPREPLY
  # ============================================================================
  # _dr_emit_feature_context <feature> <subcontext> <prefix>
  _dr_emit_feature_context() {
    local feature="$1" subcontext="$2" prefix="$3"

    while IFS= read -r item; do
      [[ -n "$item" ]] && COMPREPLY+=("${prefix}${item}")
    done < <(_dr_filesystem_find "$feature" directory single "$subcontext")

    while IFS= read -r item; do
      [[ -n "$item" ]] && COMPREPLY+=("${prefix}${item}")
    done < <(_dr_filesystem_find "$feature" file single "$subcontext")
  }

  # ============================================================================
  # HELPER: Emit recursive search results to COMPREPLY
  # ============================================================================
  # _dr_emit_recursive_search <feature> <pattern>
  _dr_emit_recursive_search() {
    local feature="$1" pattern="$2"

    while IFS= read -r item; do
      [[ -n "$item" ]] && COMPREPLY+=("$item")
    done < <(_dr_filesystem_find "$feature" directory all "" "$pattern")

    while IFS= read -r item; do
      [[ -n "$item" ]] && COMPREPLY+=("$item")
    done < <(_dr_filesystem_find "$feature" file all "" "$pattern")
  }

  # ============================================================================
  # HELPER: Emit folders-only to COMPREPLY
  # ============================================================================
  _dr_emit_folders_only() {
    local feature="$1" subcontext="${2:-}" prefix="${3:-}"

    while IFS= read -r item; do
      [[ -n "$item" ]] && COMPREPLY+=("${prefix}${item}")
    done < <(_dr_filesystem_find "$feature" directory single "$subcontext")
  }

  # ============================================================================
  # HELPER: Complete feature with hierarchical navigation or recursive search
  # Mirrors zsh behavior: folder/ → navigate, pattern → recursive search
  # ============================================================================
  _dr_complete_feature() {
    local feature="$1"

    if [[ "$cur" == */* ]]; then
      # Folder navigation
      local context_path=$(_dr_get_context_path "$cur")
      _dr_emit_feature_context "$feature" "$context_path" "$context_path"
    elif [[ -n "$cur" && "$cur" != -* ]]; then
      # Recursive search
      _dr_emit_recursive_search "$feature" "$cur"
    else
      # Root: folders + files
      _dr_emit_feature_context "$feature" "" ""
    fi
  }

  # ============================================================================
  # HELPER: Complete folder filter for -l/-L commands
  # ============================================================================
  _dr_complete_list_filter() {
    local feature="$1"

    if [[ "$cur" == */* ]]; then
      local context_path=$(_dr_get_context_path "$cur")
      _dr_emit_folders_only "$feature" "$context_path" "$context_path"
    else
      _dr_emit_folders_only "$feature" "" ""
    fi
  }

  # ============================================================================
  # COMPLETION LOGIC BY POSITION (mirrors zsh case $CURRENT)
  # ============================================================================

  # Command arrays (matching zsh definitions)
  local -a collections_commands=(set list "list:details" sync update remove)

  # Position 1: First argument after dr
  if [[ $cword -eq 1 ]]; then
    if [[ "$cur" == */* ]]; then
      # Folder navigation
      local context_path=$(_dr_get_context_path "$cur")
      _dr_emit_feature_context scripts "$context_path" "$context_path"
    elif [[ -n "$cur" && "$cur" != -* ]]; then
      # User typed a pattern — recursive search (mirrors zsh)
      _dr_emit_recursive_search scripts "$cur"
    else
      # Empty TAB or dash: show ONLY folders + scripts (NO commands)
      # Matches zsh: namespace flags are NOT shown, user must type them
      _dr_emit_feature_context scripts "" ""
    fi
    return 0

  # Position 2: Second argument
  elif [[ $cword -eq 2 ]]; then
    case "$prev" in
      -r|reload)
        return 0
        ;;
      -s|scripts)
        # Script management context — mirrors zsh: same as root dr TAB
        _dr_complete_feature scripts
        return 0
        ;;
      -a|aliases)
        # Aliases context — hint + folders + alias files (NO subcommands in TAB)
        _dr_complete_feature aliases
        return 0
        ;;
      -c|config)
        # Config context — hint + folders + config files (NO subcommands in TAB)
        _dr_complete_feature configs
        return 0
        ;;
      -col|collections)
        # Collections management — show subcommands
        COMPREPLY=($(compgen -W "${collections_commands[*]}" -- "$cur"))
        return 0
        ;;
      -l|-L)
        # List with folder filter — determine feature from context
        # At position 2, -l/-L is for scripts (default feature)
        _dr_complete_list_filter scripts
        return 0
        ;;
      set)
        # Implicit set: dr set <name>
        if [[ "$cur" == */* ]]; then
          local context_path=$(_dr_get_context_path "$cur")
          _dr_emit_feature_context scripts "$context_path" "$context_path"
        else
          _dr_emit_feature_context scripts "" ""
        fi
        return 0
        ;;
      edit|help)
        # Hierarchical navigation for edit/help
        if [[ "$cur" == */* ]]; then
          local context_path=$(_dr_get_context_path "$cur")
          _dr_emit_feature_context scripts "$context_path" "$context_path"
        else
          _dr_emit_feature_context scripts "" ""
        fi
        return 0
        ;;
      move|rename|mv)
        # Source argument for move/rename
        if [[ "$cur" == */* ]]; then
          local context_path=$(_dr_get_context_path "$cur")
          _dr_emit_feature_context scripts "$context_path" "$context_path"
        else
          _dr_emit_feature_context scripts "" ""
        fi
        return 0
        ;;
      rm)
        # Hierarchical navigation for removal
        if [[ "$cur" == */* ]]; then
          local context_path=$(_dr_get_context_path "$cur")
          _dr_emit_feature_context scripts "$context_path" "$context_path"
        else
          _dr_emit_feature_context scripts "" ""
        fi
        return 0
        ;;
    esac
    return 0

  # Position 3: Third argument
  elif [[ $cword -eq 3 ]]; then
    case "${words[1]}" in
      move|rename|mv)
        # Destination for implicit move: dr move old <dest>
        if [[ "$cur" == */* ]]; then
          local context_path=$(_dr_get_context_path "$cur")
          _dr_emit_feature_context scripts "$context_path" "$context_path"
        else
          _dr_emit_folders_only scripts
        fi
        ;;
      -s|scripts)
        case "$prev" in
          set|help|rm)
            # Hierarchical navigation
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_get_context_path "$cur")
              _dr_emit_feature_context scripts "$context_path" "$context_path"
            else
              _dr_emit_feature_context scripts "" ""
            fi
            ;;
          move|rename)
            # Source for move
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_get_context_path "$cur")
              _dr_emit_feature_context scripts "$context_path" "$context_path"
            else
              _dr_emit_feature_context scripts "" ""
            fi
            ;;
          -l|-L)
            # Folder filter for list
            _dr_complete_list_filter scripts
            ;;
        esac
        ;;
      -a|aliases)
        case "$prev" in
          move|rm|help)
            # Hierarchical navigation for alias files
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_get_context_path "$cur")
              _dr_emit_feature_context aliases "$context_path" "$context_path"
            else
              _dr_emit_feature_context aliases "" ""
            fi
            ;;
          -l|-L)
            _dr_complete_list_filter aliases
            ;;
        esac
        ;;
      -c|config)
        case "$prev" in
          set|move|rm|help)
            # Hierarchical navigation for config files
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_get_context_path "$cur")
              _dr_emit_feature_context configs "$context_path" "$context_path"
            else
              _dr_emit_feature_context configs "" ""
            fi
            ;;
          -l|-L)
            _dr_complete_list_filter configs
            ;;
          list)
            COMPREPLY=($(compgen -W "--categories --category --keys-only" -- "$cur"))
            ;;
        esac
        ;;
      -col|collections)
        # Collections subcommands don't need additional completion
        return 0
        ;;
    esac
    return 0

  # Position 4: Fourth argument
  elif [[ $cword -eq 4 ]]; then
    case "${words[1]}" in
      -s|scripts)
        case "${words[2]}" in
          move|rename)
            # Destination for: dr -s move old <dest>
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_get_context_path "$cur")
              _dr_emit_feature_context scripts "$context_path" "$context_path"
            else
              _dr_emit_folders_only scripts
            fi
            ;;
        esac
        ;;
      -a|aliases)
        case "${words[2]}" in
          move)
            # Destination for: dr -a move old <dest>
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_get_context_path "$cur")
              _dr_emit_feature_context aliases "$context_path" "$context_path"
            else
              _dr_emit_folders_only aliases
            fi
            ;;
        esac
        ;;
      -c|config)
        case "${words[2]}" in
          move)
            # Destination for: dr -c move old <dest>
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_get_context_path "$cur")
              _dr_emit_feature_context configs "$context_path" "$context_path"
            else
              _dr_emit_folders_only configs
            fi
            ;;
          list)
            if [[ "${words[3]}" == "--category" ]]; then
              # Config category completion
              local -a categories
              while IFS= read -r cat; do
                [[ -n "$cat" ]] && categories+=("$cat")
              done < <(_dr_filesystem_find configs file all | while IFS= read -r f; do
                echo "${f%/*}" 2>/dev/null
              done | sort -u)
              COMPREPLY=($(compgen -W "${categories[*]}" -- "$cur"))
            fi
            ;;
        esac
        ;;
    esac
    return 0
  fi

  return 0
}

# ============================================================================
# COMPLETION REGISTRATION
# ============================================================================

# Register with options:
# -o nospace: don't add space after completion (for folder navigation)
# -o nosort: maintain our custom ordering (folders first, scripts second)
complete -F _dr_autocomplete -o nospace -o nosort dr
