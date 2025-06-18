#!/usr/bin/env bash

_drun_autocomplete() {
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  local commands="add edit edit:docs help docs details"
  local flags="-l -L -h --help"
  local BIN_DIR="${DRUN_CONFIG:-$HOME/.config/dotrun}/bin"
  
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

  if [[ $COMP_CWORD -eq 1 ]]; then
    # First argument: commands, flags, or script names
    COMPREPLY=($(compgen -W "$commands $flags ${scripts[*]}" -- "$cur"))
  elif [[ $COMP_CWORD -eq 2 ]]; then
    case "$prev" in
      # Commands that need script names
      edit|edit:docs|help|docs|details)
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
      # -l and -L can take optional folder arguments
      -l|-L)
        COMPREPLY=($(compgen -W "${folders[*]}" -- "$cur"))
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