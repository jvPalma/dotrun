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
    'move:Move/rename a script'
    'rename:Move/rename a script (alias for move)'
    'mv:Move/rename a script (alias for move)'
    'aliases:Manage shell aliases'
    'config:Manage configuration variables'
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
  
  # Get aliases and config for completion
  local ALIASES_DIR="${DRUN_CONFIG:-$HOME/.config/dotrun}/aliases"
  local CONFIG_DIR="${DRUN_CONFIG:-$HOME/.config/dotrun}/config"
  
  # Get alias names
  local aliases=()
  if [[ -f "$ALIASES_DIR/.aliases" ]]; then
    aliases+=(${(f)"$(grep -E "^alias " "$ALIASES_DIR/.aliases" 2>/dev/null | sed 's/^alias \([^=]*\)=.*/\1/' | sort)"})
  fi
  if [[ -d "$ALIASES_DIR/.aliases.d" ]]; then
    for category_file in "$ALIASES_DIR/.aliases.d"/*.aliases; do
      [[ -f "$category_file" ]] && aliases+=(${(f)"$(grep -E "^alias " "$category_file" 2>/dev/null | sed 's/^alias \([^=]*\)=.*/\1/' | sort)"})
    done
  fi
  
  # Get config keys
  local config_keys=()
  if [[ -f "$CONFIG_DIR/.dotrun_config" ]]; then
    config_keys+=(${(f)"$(grep -E "^export " "$CONFIG_DIR/.dotrun_config" 2>/dev/null | sed 's/^export \([^=]*\)=.*/\1/' | sort)"})
  fi
  if [[ -d "$CONFIG_DIR/.dotrun_config.d" ]]; then
    for category_file in "$CONFIG_DIR/.dotrun_config.d"/*.config; do
      [[ -f "$category_file" ]] && config_keys+=(${(f)"$(grep -E "^export " "$category_file" 2>/dev/null | sed 's/^export \([^=]*\)=.*/\1/' | sort)"})
    done
  fi
  
  # Get categories
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
        move|rename|mv)
          # Move/rename commands need existing script names as first argument
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
        aliases)
          # Aliases subcommands
          local aliases_commands=(
            'init:Initialize aliases system'
            'add:Add new alias'
            'list:List all aliases'
            'edit:Edit existing alias'
            'remove:Remove alias'
            'reload:Reload aliases in current shell'
          )
          compadd -a aliases_commands
          ;;
        config)
          # Config subcommands
          local config_commands=(
            'init:Initialize configuration system'
            'set:Set configuration value'
            'get:Get configuration value'
            'list:List all configuration'
            'edit:Edit existing configuration'
            'unset:Remove configuration'
            'reload:Reload config in current shell'
          )
          compadd -a config_commands
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
    4)
      # Third argument (for move/rename commands - destination)
      case "${words[2]}" in
        move|rename|mv)
          # For destination, suggest existing scripts and folders, but allow custom names
          _alternative \
            'scripts:existing script:compadd -a scripts' \
            'folders:folder:compadd -a folders' \
            'files:custom name:_files'
          ;;
        aliases)
          case "${words[3]}" in
            edit|remove)
              compadd -a aliases
              ;;
            list)
              compadd -- --categories --category
              ;;
            add)
              compadd -- --category
              ;;
          esac
          ;;
        config)
          case "${words[3]}" in
            get|edit|unset)
              compadd -a config_keys
              ;;
            list)
              compadd -- --categories --category --keys-only
              ;;
            set)
              compadd -- --category --secure
              ;;
          esac
          ;;
      esac
      ;;
    5)
      # Fourth argument (category completion for --category flags)
      case "${words[2]}" in
        aliases)
          case "${words[3]}" in
            list)
              if [[ "${words[4]}" == "--category" ]]; then
                compadd -a alias_categories
              fi
              ;;
            add)
              if [[ "${words[4]}" == "--category" ]]; then
                compadd -a alias_categories
              fi
              ;;
          esac
          ;;
        config)
          case "${words[3]}" in
            get)
              if [[ "${words[4]}" == "${config_keys[(r)${words[4]}]}" ]]; then
                compadd -- --show-value
              fi
              ;;
            list)
              if [[ "${words[4]}" == "--category" ]]; then
                compadd -a config_categories
              fi
              ;;
            set)
              if [[ "${words[4]}" == "--category" ]]; then
                compadd -a config_categories
              fi
              ;;
          esac
          ;;
      esac
      ;;
    *)
      # For script execution (when first arg is not a command/flag)
      if [[ ! "${words[2]}" =~ ^(add|edit|edit:docs|help|docs|details|move|rename|mv|aliases|config|-l|-L|-h|--help)$ ]]; then
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