#compdef drun

# Zsh completion for drun
_drun() {
  local -a commands flags scripts folders
  local BIN_DIR="${DRUN_CONFIG:-$HOME/.config/dotrun}/bin"
  
  # Define commands
  commands=(
    'add:Create and open a new script in editor'
    'edit:Open existing script in editor'
    'edit\:docs:Edit documentation for a script'
    'help:Show embedded docs for a script'
    'docs:Show full markdown documentation'
    'details:Alias for docs command'
  )
  
  # Define flags
  flags=(
    '-l:List all scripts (names only)'
    '-L:List scripts with docs'
    '-h:Show help'
    '--help:Show help'
  )
  
  # Get all scripts
  if [[ -d "$BIN_DIR" ]]; then
    scripts=(${(f)"$(find "$BIN_DIR" -type f -name "*.sh" 2>/dev/null | sed "s|^$BIN_DIR/||; s/\.sh$//" | sort)"})
  else
    scripts=()
  fi
  
  # Get all folders for -l and -L
  if [[ -d "$BIN_DIR" ]]; then
    folders=(${(f)"$(find "$BIN_DIR" -type d 2>/dev/null | sed "s|^$BIN_DIR||; s|^/||" | grep -v '^$' | sed 's|$|/|' | sort)"})
  else
    folders=()
  fi
  
  # Main completion logic
  case $CURRENT in
    2)
      # First argument
      _alternative \
        'commands:command:compadd -a commands' \
        'flags:flag:compadd -a flags' \
        'scripts:script:compadd -a scripts'
      ;;
    3)
      # Second argument
      case "${words[2]}" in
        add)
          # For add, suggest existing scripts but allow new names
          _alternative \
            'scripts:existing script:compadd -a scripts' \
            'files:new script name:_files'
          ;;
        edit|edit:docs|help|docs|details)
          # These commands need existing script names
          compadd -a scripts
          ;;
        collections)
          # Collections subcommands
          local collection_commands=(
            'list:List installed collections'
            'list\:details:List collections with detailed information'
            'remove:Remove a collection'
          )
          compadd -a collection_commands
          ;;
        team)
          # Team subcommands
          local team_commands=(
            'init:Setup team collection from repository'
            'sync:Sync team collections'
          )
          compadd -a team_commands
          ;;
        import)
          # File/directory completion for local paths or options
          _alternative \
            'files:path:_files' \
            'options:option:compadd -- --preview --pick'
          ;;
        export)
          # Complete with available collections
          local COLLECTIONS_DIR="${DRUN_CONFIG:-$HOME/.config/dotrun}/collections"
          if [[ -d "$COLLECTIONS_DIR" ]]; then
            local collections=(${(f)"$(ls -1 "$COLLECTIONS_DIR" 2>/dev/null)"})
            compadd -a collections
          fi
          ;;
        -l|-L)
          # Optional folder argument
          compadd -a folders
          ;;
      esac
      ;;
    *)
      # For script execution (when first arg is not a command/flag)
      if [[ ! "${words[2]}" =~ ^(add|edit|edit:docs|help|docs|details|-l|-L|-h|--help)$ ]]; then
        # Don't complete script arguments
        return 0
      fi
      ;;
  esac
}

# Register the completion function
compdef _drun drun

# Also support the function being called directly
_drun "$@"