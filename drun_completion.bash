#!/usr/bin/env bash

_drun_autocomplete() {
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  local commands="add edit edit:docs help docs details move rename mv aliases config"
  local flags="-l -L -h --help"
  local BIN_DIR="${DRUN_CONFIG:-$HOME/.config/dotrun}/bin"
  local ALIASES_DIR="${DRUN_CONFIG:-$HOME/.config/dotrun}/aliases"
  local CONFIG_DIR="${DRUN_CONFIG:-$HOME/.config/dotrun}/config"

  # Get all scripts including those in subfolders
  local scripts
  if [[ -d "$BIN_DIR" ]]; then
    IFS=$'\n' scripts=($(find "$BIN_DIR" -type f -name "*.sh" 2>/dev/null | sed "s|^$BIN_DIR/||; s/\.sh$//" | sort))
  else
    scripts=()
  fi

  # Get all subfolders for -l and -L completion
  local folders
  if [[ -d "$BIN_DIR" ]]; then
    IFS=$'\n' folders=($(find "$BIN_DIR" -type d 2>/dev/null | sed "s|^$BIN_DIR||; s|^/||" | grep -v '^$' | sed 's|$|/|' | sort))
  else
    folders=()
  fi

  # Get alias names for completion
  local aliases=()
  if [[ -f "$ALIASES_DIR/.aliases" ]]; then
    IFS=$'\n' aliases+=($(grep -E "^alias " "$ALIASES_DIR/.aliases" 2>/dev/null | sed 's/^alias \([^=]*\)=.*/\1/' | sort))
  fi
  if [[ -d "$ALIASES_DIR/.aliases.d" ]]; then
    for category_file in "$ALIASES_DIR/.aliases.d"/*.aliases; do
      [[ -f "$category_file" ]] && IFS=$'\n' aliases+=($(grep -E "^alias " "$category_file" 2>/dev/null | sed 's/^alias \([^=]*\)=.*/\1/' | sort))
    done
  fi

  # Get config keys for completion
  local config_keys=()
  if [[ -f "$CONFIG_DIR/.dotrun_config" ]]; then
    IFS=$'\n' config_keys+=($(grep -E "^export " "$CONFIG_DIR/.dotrun_config" 2>/dev/null | sed 's/^export \([^=]*\)=.*/\1/' | sort))
  fi
  if [[ -d "$CONFIG_DIR/.dotrun_config.d" ]]; then
    for category_file in "$CONFIG_DIR/.dotrun_config.d"/*.config; do
      [[ -f "$category_file" ]] && IFS=$'\n' config_keys+=($(grep -E "^export " "$category_file" 2>/dev/null | sed 's/^export \([^=]*\)=.*/\1/' | sort))
    done
  fi

  # Get categories for aliases and config
  local alias_categories=()
  if [[ -d "$ALIASES_DIR/.aliases.d" ]]; then
    for category_file in "$ALIASES_DIR/.aliases.d"/*.aliases; do
      [[ -f "$category_file" ]] && alias_categories+=($(basename "$category_file" .aliases))
    done
  fi
  local config_categories=()
  if [[ -d "$CONFIG_DIR/.dotrun_config.d" ]]; then
    for category_file in "$CONFIG_DIR/.dotrun_config.d"/*.config; do
      [[ -f "$category_file" ]] && config_categories+=($(basename "$category_file" .config))
    done
  fi

  if [[ $COMP_CWORD -eq 1 ]]; then
    # First argument: commands, flags, or script names
    COMPREPLY=($(compgen -W "$commands $flags ${scripts[*]}" -- "$cur"))
  elif [[ $COMP_CWORD -eq 2 ]]; then
    case "$prev" in
    # Commands that need script names
    edit | edit:docs | help | docs | details)
      COMPREPLY=($(compgen -W "${scripts[*]}" -- "$cur"))
      ;;
    # Move/rename commands need existing script names as first argument
    move | rename | mv)
      COMPREPLY=($(compgen -W "${scripts[*]}" -- "$cur"))
      ;;
    # Add command can take new script names or existing ones
    add)
      # Suggest existing scripts and allow custom input
      COMPREPLY=($(compgen -W "${scripts[*]}" -- "$cur"))
      # Also allow typing new names by not restricting to existing scripts
      if [[ -n "$cur" ]]; then
        COMPREPLY+=("$cur")
      fi
      ;;
    # Collections subcommands
    collections)
      COMPREPLY=($(compgen -W "list list:details remove" -- "$cur"))
      ;;
    # Team subcommands
    team)
      COMPREPLY=($(compgen -W "init sync" -- "$cur"))
      ;;
    # Aliases subcommands
    aliases)
      COMPREPLY=($(compgen -W "init add list edit remove reload" -- "$cur"))
      ;;
    # Config subcommands
    config)
      COMPREPLY=($(compgen -W "init set get list edit unset reload" -- "$cur"))
      ;;
    # Import/export need different completion
    import)
      case "$COMP_CWORD" in
      2)
        # First argument: URL or path
        COMPREPLY=($(compgen -f -- "$cur"))
        ;;
      3)
        # Second argument: collection name or options
        if [[ "$cur" =~ ^-- ]]; then
          COMPREPLY=($(compgen -W "--preview --pick" -- "$cur"))
        else
          # Collection name (allow custom input)
          COMPREPLY=()
        fi
        ;;
      4)
        # Third argument: options or script name for --pick
        if [[ "${COMP_WORDS[3]}" == "--pick" ]]; then
          # Complete with available script names from preview (if possible)
          COMPREPLY=()
        elif [[ "$cur" =~ ^-- ]]; then
          COMPREPLY=($(compgen -W "--preview --pick" -- "$cur"))
        fi
        ;;
      *)
        # Additional arguments
        if [[ "$cur" =~ ^-- ]]; then
          COMPREPLY=($(compgen -W "--preview --pick" -- "$cur"))
        fi
        ;;
      esac
      ;;
    export)
      # Complete with available collections
      local COLLECTIONS_DIR="${DRUN_CONFIG:-$HOME/.config/dotrun}/collections"
      if [[ -d "$COLLECTIONS_DIR" ]]; then
        local collections=($(ls -1 "$COLLECTIONS_DIR" 2>/dev/null))
        COMPREPLY=($(compgen -W "${collections[*]}" -- "$cur"))
      fi
      ;;
    # -l and -L can take optional folder arguments
    -l | -L)
      COMPREPLY=($(compgen -W "${folders[*]}" -- "$cur"))
      ;;
    esac
  elif [[ $COMP_CWORD -eq 3 ]]; then
    case "${COMP_WORDS[1]}" in
    # Move/rename commands need destination name as second argument
    move | rename | mv)
      # For destination, suggest existing scripts and folder structure
      # but allow custom names by also suggesting the current input
      local suggestions=("${scripts[@]}" "${folders[@]}")
      COMPREPLY=($(compgen -W "${suggestions[*]}" -- "$cur"))
      # Also allow typing new names by including the current input
      if [[ -n "$cur" ]]; then
        COMPREPLY+=("$cur")
      fi
      ;;
    # Aliases commands that need alias names
    aliases)
      case "${COMP_WORDS[2]}" in
      edit | remove)
        COMPREPLY=($(compgen -W "${aliases[*]}" -- "$cur"))
        ;;
      list)
        if [[ "$cur" == "--category" ]]; then
          COMPREPLY=($(compgen -W "--category" -- "$cur"))
        elif [[ "$cur" == "--categories" ]]; then
          COMPREPLY=($(compgen -W "--categories" -- "$cur"))
        else
          COMPREPLY=($(compgen -W "--categories --category" -- "$cur"))
        fi
        ;;
      esac
      ;;
    # Config commands that need config keys
    config)
      case "${COMP_WORDS[2]}" in
      get)
        COMPREPLY=($(compgen -W "${config_keys[*]}" -- "$cur"))
        ;;
      edit | unset)
        COMPREPLY=($(compgen -W "${config_keys[*]}" -- "$cur"))
        ;;
      list)
        COMPREPLY=($(compgen -W "--categories --category --keys-only" -- "$cur"))
        ;;
      esac
      ;;
    esac
  elif [[ $COMP_CWORD -eq 4 ]]; then
    case "${COMP_WORDS[1]}" in
    aliases)
      case "${COMP_WORDS[2]}" in
      list)
        if [[ "${COMP_WORDS[3]}" == "--category" ]]; then
          COMPREPLY=($(compgen -W "${alias_categories[*]}" -- "$cur"))
        fi
        ;;
      add)
        if [[ "${COMP_WORDS[3]}" == "--category" ]]; then
          COMPREPLY=($(compgen -W "${alias_categories[*]}" -- "$cur"))
        else
          # Suggest --category flag for aliases add command  
          COMPREPLY=($(compgen -W "--category" -- "$cur"))
        fi
        ;;
      esac
      ;;
    config)
      case "${COMP_WORDS[2]}" in
      list)
        if [[ "${COMP_WORDS[3]}" == "--category" ]]; then
          COMPREPLY=($(compgen -W "${config_categories[*]}" -- "$cur"))
        fi
        ;;
      set)
        if [[ "${COMP_WORDS[3]}" == "--category" ]]; then
          COMPREPLY=($(compgen -W "${config_categories[*]}" -- "$cur"))
        else
          # Suggest flags for config set command
          COMPREPLY=($(compgen -W "--category --secure" -- "$cur"))
        fi
        ;;
      get)
        # Suggest --show-value flag for config get command
        COMPREPLY=($(compgen -W "--show-value" -- "$cur"))
        ;;
      esac
      ;;
    esac
  elif [[ $COMP_CWORD -ge 2 ]]; then
    # For script execution, no further completion
    if [[ ! "${COMP_WORDS[1]}" =~ ^($commands|$flags)$ ]]; then
      # Running a script - no completion for script arguments
      COMPREPLY=()
    fi
  fi

  return 0
}

complete -F _drun_autocomplete drun
