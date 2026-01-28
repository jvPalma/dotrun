#!/usr/bin/env bash
# shellcheck disable=SC2155,SC2207
# Standard bash completion for dr (no emojis, clean insertion)
# For enhanced visual experience with colors, use ble.sh version

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
  # HELPER FUNCTIONS (Clean - no emojis)
  # ============================================================================

  # Extract folder context from current word
  _dr_get_context_path() {
    local word="$1"
    if [[ "$word" == */* ]]; then
      echo "${word%/*}/"
    else
      echo ""
    fi
  }

  # Get folders in context (with trailing slash for visual distinction)
  _dr_get_folders() {
    local context="$1"
    local search_dir="$BIN_DIR"

    if [[ -n "$context" ]]; then
      search_dir="$BIN_DIR/$context"
    fi

    if [[ ! -d "$search_dir" ]]; then
      return
    fi

    # Get immediate subdirectories, exclude hidden folders
    local strip_prefix="${search_dir%/}/"
    while IFS= read -r -d '' dir; do
      local dirname="${dir#"${strip_prefix}"}"
      dirname="${dirname%/}"
      [[ "$dirname" == .* ]] && continue
      [[ -n "$dirname" ]] && echo "${dirname}/"
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print0 2>/dev/null | sort -z)
  }

  # Get scripts in context (no .sh extension)
  _dr_get_scripts() {
    local context="$1"
    local search_dir="$BIN_DIR"

    if [[ -n "$context" ]]; then
      search_dir="$BIN_DIR/$context"
    fi

    if [[ ! -d "$search_dir" ]]; then
      return
    fi

    # Get immediate .sh files only
    local strip_prefix="${search_dir%/}/"
    while IFS= read -r -d '' file; do
      local filename="${file#"${strip_prefix}"}"
      filename="${filename%.sh}"
      [[ -n "$filename" ]] && echo "${filename}"
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type f -name "*.sh" -print0 2>/dev/null | sort -z)
  }

  # Get all scripts recursively
  _dr_get_all_scripts() {
    if [[ ! -d "$BIN_DIR" ]]; then
      return
    fi

    local -a result
    while IFS= read -r -d '' file; do
      local relpath="${file#"${BIN_DIR}"/}"
      [[ "$relpath" == .* ]] || [[ "$relpath" == */.* ]] && continue
      relpath="${relpath%.sh}"
      result+=("${relpath}")
    done < <(find "$BIN_DIR" -type f -name "*.sh" -print0 2>/dev/null | sort -z)

    printf '%s\n' "${result[@]}"
  }

  # Emit context with proper ordering (folders first, then scripts)
  _dr_emit_context() {
    local context="$1"
    local prefix="$2"
    local -a folders scripts

    # Collect folders
    while IFS= read -r item; do
      [[ -n "$item" ]] && folders+=("${prefix}${item}")
    done < <(_dr_get_folders "$context")

    # Collect scripts
    while IFS= read -r item; do
      [[ -n "$item" ]] && scripts+=("${prefix}${item}")
    done < <(_dr_get_scripts "$context")

    # Add to COMPREPLY in order: folders first, then scripts
    COMPREPLY+=("${folders[@]}")
    COMPREPLY+=("${scripts[@]}")
  }

  # Get alias folders in context (with trailing slash for visual distinction)
  _dr_get_alias_folders() {
    local context="$1"
    local search_dir="$ALIASES_DIR"

    if [[ -n "$context" ]]; then
      search_dir="$ALIASES_DIR/$context"
    fi

    if [[ ! -d "$search_dir" ]]; then
      return
    fi

    # Get immediate subdirectories, exclude hidden folders
    local strip_prefix="${search_dir%/}/"
    while IFS= read -r -d '' dir; do
      local dirname="${dir#"${strip_prefix}"}"
      dirname="${dirname%/}"
      [[ "$dirname" == .* ]] && continue
      [[ -n "$dirname" ]] && echo "${dirname}/"
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print0 2>/dev/null | sort -z)
  }

  # Get alias files in context (no .aliases extension)
  _dr_get_alias_files() {
    local context="$1"
    local search_dir="$ALIASES_DIR"

    if [[ -n "$context" ]]; then
      search_dir="$ALIASES_DIR/$context"
    fi

    if [[ ! -d "$search_dir" ]]; then
      return
    fi

    # Get immediate .aliases files only
    local strip_prefix="${search_dir%/}/"
    while IFS= read -r -d '' file; do
      local filename="${file#"${strip_prefix}"}"
      filename="${filename%.aliases}"
      [[ -n "$filename" ]] && echo "${filename}"
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type f -name "*.aliases" -print0 2>/dev/null | sort -z)
  }

  # Emit alias context with proper ordering (folders first, then alias files)
  _dr_emit_aliases_context() {
    local context="$1"
    local prefix="$2"
    local -a folders alias_files

    # Collect folders
    while IFS= read -r item; do
      [[ -n "$item" ]] && folders+=("${prefix}${item}")
    done < <(_dr_get_alias_folders "$context")

    # Collect alias files
    while IFS= read -r item; do
      [[ -n "$item" ]] && alias_files+=("${prefix}${item}")
    done < <(_dr_get_alias_files "$context")

    # Add to COMPREPLY in order: folders first, then alias files
    COMPREPLY+=("${folders[@]}")
    COMPREPLY+=("${alias_files[@]}")
  }

  # Get config folders in context (with trailing slash for visual distinction)
  _dr_get_config_folders() {
    local context="$1"
    local search_dir="$CONFIG_DIR"

    if [[ -n "$context" ]]; then
      search_dir="$CONFIG_DIR/$context"
    fi

    if [[ ! -d "$search_dir" ]]; then
      return
    fi

    # Get immediate subdirectories, exclude hidden folders
    local strip_prefix="${search_dir%/}/"
    while IFS= read -r -d '' dir; do
      local dirname="${dir#"${strip_prefix}"}"
      dirname="${dirname%/}"
      [[ "$dirname" == .* ]] && continue
      [[ -n "$dirname" ]] && echo "${dirname}/"
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print0 2>/dev/null | sort -z)
  }

  # Get config files in context (no .config extension)
  _dr_get_config_files() {
    local context="$1"
    local search_dir="$CONFIG_DIR"

    if [[ -n "$context" ]]; then
      search_dir="$CONFIG_DIR/$context"
    fi

    if [[ ! -d "$search_dir" ]]; then
      return
    fi

    # Get immediate .config files only
    local strip_prefix="${search_dir%/}/"
    while IFS= read -r -d '' file; do
      local filename="${file#"${strip_prefix}"}"
      filename="${filename%.config}"
      [[ -n "$filename" ]] && echo "${filename}"
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type f -name "*.config" -print0 2>/dev/null | sort -z)
  }

  # Emit config context with proper ordering (folders first, then config files)
  _dr_emit_configs_context() {
    local context="$1"
    local prefix="$2"
    local -a folders config_files

    # Collect folders
    while IFS= read -r item; do
      [[ -n "$item" ]] && folders+=("${prefix}${item}")
    done < <(_dr_get_config_folders "$context")

    # Collect config files
    while IFS= read -r item; do
      [[ -n "$item" ]] && config_files+=("${prefix}${item}")
    done < <(_dr_get_config_files "$context")

    # Add to COMPREPLY in order: folders first, then config files
    COMPREPLY+=("${folders[@]}")
    COMPREPLY+=("${config_files[@]}")
  }

  # ============================================================================
  # COMPLETION LOGIC BY POSITION
  # ============================================================================

  # Command definitions
  local script_mgmt_commands="set move rm help"
  local aliases_commands="move rm help init -l -L"
  local config_commands="move rm help init -l -L"
  local collections_commands="list list:details remove"
  local global_commands="reload"

  # Position 1: First argument
  if [[ $cword -eq 1 ]]; then
    if [[ "$cur" == */* ]]; then
      # In folder context - just show folder contents
      local context_path=$(_dr_get_context_path "$cur")
      _dr_emit_context "$context_path" "$context_path"
    else
      # Root context: global commands, folders, scripts
      COMPREPLY=($(compgen -W "$global_commands" -- "$cur"))
      _dr_emit_context "" ""
    fi
    return 0

  # Position 2: Second argument
  elif [[ $cword -eq 2 ]]; then
    case "$prev" in
      reload)
        # reload takes no arguments - return empty
        return 0
        ;;
      -s | scripts)
        # Script management commands
        COMPREPLY=($(compgen -W "$script_mgmt_commands" -- "$cur"))
        ;;
      -a | aliases)
        # Aliases commands AND folders/files for default add/edit behavior
        COMPREPLY=($(compgen -W "$aliases_commands" -- "$cur"))
        # Also show folders and alias files
        if [[ "$cur" == */* ]]; then
          local context_path=$(_dr_get_context_path "$cur")
          _dr_emit_aliases_context "$context_path" "$context_path"
        else
          _dr_emit_aliases_context "" ""
        fi
        ;;
      -l | -L)
        # List with folder filter
        if [[ "${words[1]}" == "-a" || "${words[1]}" == "aliases" ]]; then
          # For aliases list, show only folders
          local -a folders_only
          while IFS= read -r folder; do
            [[ -n "$folder" ]] && folders_only+=("$folder")
          done < <(_dr_get_alias_folders "")
          COMPREPLY+=("${folders_only[@]}")
        else
          # For scripts list, show only folders (already handled in existing code)
          local -a folders_only
          while IFS= read -r folder; do
            [[ -n "$folder" ]] && folders_only+=("$folder")
          done < <(_dr_get_folders "")
          COMPREPLY=("${folders_only[@]}")
        fi
        ;;
      -c | config)
        # Config commands AND folders/files for default add/edit behavior
        COMPREPLY=($(compgen -W "$config_commands" -- "$cur"))
        # Also show folders and config files
        if [[ "$cur" == */* ]]; then
          local context_path=$(_dr_get_context_path "$cur")
          _dr_emit_configs_context "$context_path" "$context_path"
        else
          _dr_emit_configs_context "" ""
        fi
        ;;
      -col | collections)
        # Collections commands
        COMPREPLY=($(compgen -W "$collections_commands" -- "$cur"))
        ;;
      set | help | move | mv | rm)
        # Direct commands with hierarchical navigation
        if [[ "$cur" == */* ]]; then
          local context_path=$(_dr_get_context_path "$cur")
          _dr_emit_context "$context_path" "$context_path"
        else
          _dr_emit_context "" ""
        fi
        ;;
      -l | -L)
        # List with folder filter
        local -a folders_only
        while IFS= read -r folder; do
          [[ -n "$folder" ]] && folders_only+=("$folder")
        done < <(_dr_get_folders "")
        COMPREPLY=("${folders_only[@]}")
        ;;
    esac
    return 0

  # Position 3: Third argument
  elif [[ $cword -eq 3 ]]; then
    case "${words[1]}" in
      move | rename | mv)
        # Destination argument
        if [[ "$cur" == */* ]]; then
          local context_path=$(_dr_get_context_path "$cur")
          _dr_emit_context "$context_path" "$context_path"
        else
          local -a folders_only
          while IFS= read -r folder; do
            [[ -n "$folder" ]] && folders_only+=("$folder")
          done < <(_dr_get_folders "")
          COMPREPLY=("${folders_only[@]}")
        fi
        ;;
      -s | scripts)
        case "$prev" in
          set | help | rm | move)
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_get_context_path "$cur")
              _dr_emit_context "$context_path" "$context_path"
            else
              _dr_emit_context "" ""
            fi
            ;;
          list)
            local -a folders_only
            while IFS= read -r folder; do
              [[ -n "$folder" ]] && folders_only+=("$folder")
            done < <(_dr_get_folders "")
            COMPREPLY=("${folders_only[@]}")
            ;;
        esac
        ;;
      -a | aliases)
        case "$prev" in
          move | rm | help)
            # Hierarchical navigation for alias files
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_get_context_path "$cur")
              _dr_emit_aliases_context "$context_path" "$context_path"
            else
              _dr_emit_aliases_context "" ""
            fi
            ;;
          -l | -L)
            # List with optional folder filter - show only folders
            local -a folders_only
            while IFS= read -r folder; do
              [[ -n "$folder" ]] && folders_only+=("$folder")
            done < <(_dr_get_alias_folders "")
            COMPREPLY=("${folders_only[@]}")
            ;;
        esac
        ;;
      -c | config)
        case "$prev" in
          set | move | rm | help)
            # Hierarchical navigation for config files
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_get_context_path "$cur")
              _dr_emit_configs_context "$context_path" "$context_path"
            else
              _dr_emit_configs_context "" ""
            fi
            ;;
          -l | -L)
            # List with optional folder filter - show only folders
            local -a folders_only
            while IFS= read -r folder; do
              [[ -n "$folder" ]] && folders_only+=("$folder")
            done < <(_dr_get_config_folders "")
            COMPREPLY=("${folders_only[@]}")
            ;;
          list)
            COMPREPLY=($(compgen -W "--categories --category --keys-only" -- "$cur"))
            ;;
        esac
        ;;
    esac
    return 0

  # Position 4+: Fourth argument and beyond
  elif [[ $cword -eq 4 ]]; then
    case "${words[1]}" in
      -s | scripts)
        case "${words[2]}" in
          move | rename)
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_get_context_path "$cur")
              _dr_emit_context "$context_path" "$context_path"
            else
              local -a folders_only
              while IFS= read -r folder; do
                [[ -n "$folder" ]] && folders_only+=("$folder")
              done < <(_dr_get_folders "")
              COMPREPLY=("${folders_only[@]}")
            fi
            ;;
        esac
        ;;
      -a | aliases)
        case "${words[2]}" in
          move)
            # Destination for move operations
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_get_context_path "$cur")
              _dr_emit_aliases_context "$context_path" "$context_path"
            else
              local -a folders_only
              while IFS= read -r folder; do
                [[ -n "$folder" ]] && folders_only+=("$folder")
              done < <(_dr_get_alias_folders "")
              COMPREPLY=("${folders_only[@]}")
            fi
            ;;
        esac
        ;;
      -c | config)
        case "${words[2]}" in
          move)
            # Destination for move operations
            if [[ "$cur" == */* ]]; then
              local context_path=$(_dr_get_context_path "$cur")
              _dr_emit_configs_context "$context_path" "$context_path"
            else
              local -a folders_only
              while IFS= read -r folder; do
                [[ -n "$folder" ]] && folders_only+=("$folder")
              done < <(_dr_get_config_folders "")
              COMPREPLY=("${folders_only[@]}")
            fi
            ;;
        esac
        ;;
    esac
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
