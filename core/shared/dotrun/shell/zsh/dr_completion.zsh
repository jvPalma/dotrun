#compdef dr
# shellcheck shell=bash disable=SC2148,SC2034,SC2154,SC2206,SC2207,SC2295,SC2296

# Zsh completion for dr with namespace-based UX, colorized hierarchical display

# Configure zstyle for dr completion
# Enable menu selection and list format (one per line)
zstyle ':completion:*:*:dr:*' menu yes select
zstyle ':completion:*:*:dr:*' list-separator ''
zstyle ':completion:*:*:dr:*' group-name ''
zstyle ':completion:*:*:dr:*' list-rows-first true
zstyle ':completion:*:*:dr:*' format ''
zstyle ':completion:*:*:dr:*' group-order hints folders scripts aliases configs script-commands aliases-commands config-commands collections-commands

# Configure colors for completion groups
# Colors: 33=yellow, 36=cyan, 90=dark gray, 32=green, 35=purple, 31=red
zstyle ':completion:*:*:dr:*:hints' list-colors '=(#b)(*)=90'              # Dark gray for hints
zstyle ':completion:*:*:dr:*:folders' list-colors '=(#b)(*)=33'            # Yellow for folders
zstyle ':completion:*:*:dr:*:scripts' list-colors '=(#b)(*)=32'            # Green for scripts
zstyle ':completion:*:*:dr:*:aliases' list-colors '=(#b)(*)=35'            # Purple for aliases
zstyle ':completion:*:*:dr:*:configs' list-colors '=(#b)(*)=31'            # Red for configs
zstyle ':completion:*:*:dr:*:script-commands' list-colors '=(#b)(*)=32'    # Green for script management
zstyle ':completion:*:*:dr:*:aliases-commands' list-colors '=(#b)(*)=35'   # Purple for aliases
zstyle ':completion:*:*:dr:*:config-commands' list-colors '=(#b)(*)=31'    # Red for config
zstyle ':completion:*:*:dr:*:collections-commands' list-colors '=(#b)(*)=34'  # Blue for collections

# Main completion function
_dr() {
  local -a special_commands script_commands aliases_commands config_commands collections_commands
  # Get aliases and config directories
  local BIN_DIR="${DR_CONFIG:-$HOME/.config/dotrun}/scripts"
  local ALIASES_DIR="${DR_CONFIG:-$HOME/.config/dotrun}/aliases"
  local CONFIG_DIR="${DR_CONFIG:-$HOME/.config/dotrun}/configs"

  # Define special commands (appear at root)
  special_commands=(
    '-l:List all scripts (names only)'
    '-L:List scripts with docs'
    '-h:Show help'
    '--help:Show help'
    '-r:Reload all Aliases and Configs in current shell'
    'reload:Reload all Aliases and Configs in current shell'
  )

  # Define script management commands (accessible via -s/scripts)
  script_commands=(
    'set:Create or open a script in editor (idempotent)'
    'move:Move/rename a script'
    'rename:Move/rename a script (alias for move)'
    'help:Show script documentation'
  )

  # Define aliases management commands (accessible via -a/aliases)
  aliases_commands=(
    'set:Create or edit alias file (opens editor)'
    'list:List all alias files'
    'remove:Remove alias file'
  )

  # Define config management commands (accessible via -c/config)
  config_commands=(
    'set:Create or edit config file (opens editor)'
    'list:List all config files'
    'remove:Remove config file'
  )

  # Define collections management commands (accessible via -col/collections)
  collections_commands=(
    'set:Add a new collection'
    'list:List installed collections'
    'sync:Sync installed collections'
    'update:Update collection by given name'
    'list\:details:List collections with detailed information'
    'remove:Remove a collection'
  )

  # Helper: Add commands with tag for proper coloring via zstyle
  _dr_add_commands_with_tag() {
    local tag="$1"
    shift
    local -a commands descriptions
    local cmd desc

    # Parse command:description format
    for item in "$@"; do
      cmd="${item%%:*}"
      desc="${item#*:}"
      commands+=("$cmd")
      descriptions+=("$cmd -- $desc")
    done

    # Use _wanted with compadd for proper tag registration and list-colors
    # This is the same approach used for folders and scripts
    (( ${#commands[@]} )) && _wanted "$tag" expl "${tag//-/ }" compadd -d descriptions -a commands
  }

  # Helper function: Extract folder context from current word
  _dr_get_context_path() {
    local word="$1"
    if [[ "$word" == */* ]]; then
      # Extract folder path (everything before the last /)
      echo "${word%/*}/"
    else
      # Root context
      echo ""
    fi
  }

  # Helper function: Get folders in context
  # Outputs folders (one per line) without emoji - use _dr_add_folders to display with emoji
  _dr_get_folders() {
    local context="$1"
    local search_dir="$BIN_DIR"

    if [[ -n "$context" ]]; then
      search_dir="$BIN_DIR/$context"
    fi

    if [[ ! -d "$search_dir" ]]; then
      return
    fi

    # Get immediate subdirectories only, add trailing /, ascending sort
    # Exclude hidden folders (starting with .)
    local strip_prefix="${search_dir%/}/"
    while IFS= read -r -d '' dir; do
      local dirname="${dir#${strip_prefix}}"
      dirname="${dirname%/}"
      # Skip hidden folders (starting with .)
      [[ "$dirname" == .* ]] && continue
      [[ -n "$dirname" ]] && echo "${dirname}/"
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print0 2>/dev/null | sort -z)
  }

  # Helper: Show the gray hint at root
  _dr_show_hint() {
    _message -r $'\e[90m(hint: -s/scripts, -a/aliases, -c/config, -col/collections)\e[0m'
  }

  # Helper: Collect and emit candidates for a context.
  # Arg1: context (e.g., "ai/tools/" or ""), Arg2: prefix to insert (usually same as context)
  _dr_emit_context() {
    local context="$1"
    local prefix="$2"
    local -a folders scripts folder_matches folder_displays script_matches script_displays
    local item

    # Collect
    while IFS= read -r item; do [[ -n "$item" ]] && folders+=("$item"); done < <(_dr_get_folders "$context")
    while IFS= read -r item; do [[ -n "$item" ]] && scripts+=("$item");  done < <(_dr_get_scripts  "$context")

    # Decorate for display/insert
    for item in "${folders[@]}"; do
      folder_matches+=("${prefix}${item}")   # insert: "ai/tools/<child>/"
      folder_displays+=("📁 ${item}")        # show:    "📁 <child>/"
    done
    for item in "${scripts[@]}"; do
      script_matches+=("${prefix}${item}")   # insert: "ai/tools/<script>"
      script_displays+=("🚀 ${item}")        # show:    "🚀 <script>"
    done

    # Emit with tags so group-order (folders → scripts) applies; keep -S '' for folders
    (( ${#folder_matches[@]} )) && _wanted folders expl 'folders' compadd -Q -S '' -d folder_displays -a -- folder_matches
    (( ${#script_matches[@]} )) && _wanted scripts  expl 'scripts'  compadd -Q      -d script_displays -a -- script_matches
  }

  # Helper function: Add folders with emoji display using compadd
  _dr_add_folders() {
    local -a folders displays
    while IFS= read -r folder; do
      [[ -n "$folder" ]] && folders+=("$folder") && displays+=("📁 $folder")
    done

    (( ${#folders[@]} )) && compadd -U -S '' -Q -d displays -a folders
  }

  # Helper function: Get scripts in context (strip .sh extension)
  # Outputs scripts (one per line) without emoji - use _dr_add_scripts to display with emoji
  _dr_get_scripts() {
    local context="$1"
    local search_dir="$BIN_DIR"

    if [[ -n "$context" ]]; then
      search_dir="$BIN_DIR/$context"
    fi

    if [[ ! -d "$search_dir" ]]; then
      return
    fi

    # Get immediate .sh files only, strip extension, ascending sort
    local strip_prefix="${search_dir%/}/"
    while IFS= read -r -d '' file; do
      local filename="${file#${strip_prefix}}"
      filename="${filename%.sh}"
      [[ -n "$filename" ]] && echo "${filename}"
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type f -name "*.sh" -print0 2>/dev/null | sort -z)
  }

  # Helper function: Add scripts with emoji display using compadd
  _dr_add_scripts() {
    local -a scripts displays
    while IFS= read -r script; do
      [[ -n "$script" ]] && scripts+=("$script") && displays+=("🚀 $script")
    done

    (( ${#scripts[@]} )) && compadd -U -d displays -a scripts
  }

  # Helper function: Get all scripts recursively (for edit/help/move)
  _dr_get_all_scripts() {
    if [[ ! -d "$BIN_DIR" ]]; then
      return
    fi

    local -a result
    while IFS= read -r -d '' file; do
      local relpath="${file#${BIN_DIR}/}"  # Strip directory path with trailing slash
      # Skip scripts in hidden folders (check relative path only)
      [[ "$relpath" == .* ]] || [[ "$relpath" == */.* ]] && continue
      relpath="${relpath%.sh}"  # Strip .sh extension
      result+=("${relpath}")
    done < <(find "$BIN_DIR" -type f -name "*.sh" -print0 2>/dev/null | sort -z)

    # Use echo instead of print -l for proper subshell capture
    for item in "${result[@]}"; do
      echo "$item"
    done
  }


  # Helper function: Get alias folders in context
  _dr_get_alias_folders() {
    local context="$1"
    local search_dir="$ALIASES_DIR"

    if [[ -n "$context" ]]; then
      search_dir="$ALIASES_DIR/$context"
    fi

    if [[ ! -d "$search_dir" ]]; then
      return
    fi

    # Get immediate subdirectories only, add trailing /, ascending sort
    # Exclude hidden folders (starting with .)
    local strip_prefix="${search_dir%/}/"
    while IFS= read -r -d '' dir; do
      local dirname="${dir#${strip_prefix}}"
      dirname="${dirname%/}"
      # Skip hidden folders (starting with .)
      [[ "$dirname" == .* ]] && continue
      [[ -n "$dirname" ]] && echo "${dirname}/"
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print0 2>/dev/null | sort -z)
  }

  # Helper function: Get alias files in context (strip .aliases extension)
  _dr_get_alias_files() {
    local context="$1"
    local search_dir="$ALIASES_DIR"

    if [[ -n "$context" ]]; then
      search_dir="$ALIASES_DIR/$context"
    fi

    if [[ ! -d "$search_dir" ]]; then
      return
    fi

    # Get immediate .aliases files only, strip extension, ascending sort
    local strip_prefix="${search_dir%/}/"
    while IFS= read -r -d '' file; do
      local filename="${file#${strip_prefix}}"
      filename="${filename%.aliases}"
      [[ -n "$filename" ]] && echo "${filename}"
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type f -name "*.aliases" -print0 2>/dev/null | sort -z)
  }

  # Helper: Collect and emit candidates for alias context
  # Arg1: context (e.g., "cd/" or ""), Arg2: prefix to insert (usually same as context)
  _dr_emit_aliases_context() {
    local context="$1"
    local prefix="$2"
    local -a folders alias_files folder_matches folder_displays alias_matches alias_displays
    local item

    # Collect
    while IFS= read -r item; do [[ -n "$item" ]] && folders+=("$item"); done < <(_dr_get_alias_folders "$context")
    while IFS= read -r item; do [[ -n "$item" ]] && alias_files+=("$item");  done < <(_dr_get_alias_files  "$context")

    # Decorate for display/insert
    for item in "${folders[@]}"; do
      folder_matches+=("${prefix}${item}")   # insert: "cd/<child>/"
      folder_displays+=("📁 ${item}")        # show:    "📁 <child>/"
    done
    for item in "${alias_files[@]}"; do
      alias_matches+=("${prefix}${item}")    # insert: "cd/<file>"
      alias_displays+=("🎭 ${item}")         # show:    "🎭 <file>"
    done

    # Emit with tags so group-order (folders → alias files) applies; keep -S '' for folders
    (( ${#folder_matches[@]} )) && _wanted folders expl 'folders' compadd -Q -S '' -d folder_displays -a -- folder_matches
    (( ${#alias_matches[@]} )) && _wanted aliases  expl 'aliases'  compadd -Q      -d alias_displays -a -- alias_matches
  }

  # Helper function: Get config folders in context
  _dr_get_config_folders() {
    local context="$1"
    local search_dir="$CONFIG_DIR"

    if [[ -n "$context" ]]; then
      search_dir="$CONFIG_DIR/$context"
    fi

    if [[ ! -d "$search_dir" ]]; then
      return
    fi

    # Get immediate subdirectories only, add trailing /, ascending sort
    # Exclude hidden folders (starting with .)
    local strip_prefix="${search_dir%/}/"
    while IFS= read -r -d '' dir; do
      local dirname="${dir#${strip_prefix}}"
      dirname="${dirname%/}"
      # Skip hidden folders (starting with .)
      [[ "$dirname" == .* ]] && continue
      [[ -n "$dirname" ]] && echo "${dirname}/"
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print0 2>/dev/null | sort -z)
  }

  # Helper function: Get config files in context (strip .config extension)
  _dr_get_config_files() {
    local context="$1"
    local search_dir="$CONFIG_DIR"

    if [[ -n "$context" ]]; then
      search_dir="$CONFIG_DIR/$context"
    fi

    if [[ ! -d "$search_dir" ]]; then
      return
    fi

    # Get immediate .config files only, strip extension, ascending sort
    local strip_prefix="${search_dir%/}/"
    while IFS= read -r -d '' file; do
      local filename="${file#${strip_prefix}}"
      filename="${filename%.config}"
      [[ -n "$filename" ]] && echo "${filename}"
    done < <(find "$search_dir" -mindepth 1 -maxdepth 1 -type f -name "*.config" -print0 2>/dev/null | sort -z)
  }

  # Helper: Collect and emit candidates for config context
  # Arg1: context (e.g., "api/" or ""), Arg2: prefix to insert (usually same as context)
  _dr_emit_configs_context() {
    local context="$1"
    local prefix="$2"
    local -a folders config_files folder_matches folder_displays config_matches config_displays
    local item

    # Collect
    while IFS= read -r item; do [[ -n "$item" ]] && folders+=("$item"); done < <(_dr_get_config_folders "$context")
    while IFS= read -r item; do [[ -n "$item" ]] && config_files+=("$item");  done < <(_dr_get_config_files  "$context")

    # Decorate for display/insert
    for item in "${folders[@]}"; do
      folder_matches+=("${prefix}${item}")   # insert: "api/<child>/"
      folder_displays+=("📁 ${item}")        # show:    "📁 <child>/"
    done
    for item in "${config_files[@]}"; do
      config_matches+=("${prefix}${item}")    # insert: "api/<file>"
      config_displays+=("⚙ ${item}")         # show:    "⚙ <file>"
    done

    # Emit with tags so group-order (folders → config files) applies; keep -S '' for folders
    (( ${#folder_matches[@]} )) && _wanted folders expl 'folders' compadd -Q -S '' -d folder_displays -a -- folder_matches
    (( ${#config_matches[@]} )) && _wanted configs  expl 'configs'  compadd -Q      -d config_displays -a -- config_matches
  }

  # Get config keys (recursive search)
  local -a config_keys
  if [[ -d "$CONFIG_DIR" ]]; then
    while IFS= read -r config_file; do
      [[ -f "$config_file" ]] && config_keys+=(${(f)"$(grep -E "^export " "$config_file" 2>/dev/null | sed 's/^export \([^=]*\)=.*/\1/' | sort)"})
    done < <(find "$CONFIG_DIR" -name "*.config" -type f 2>/dev/null)
  fi

  # Get alias categories
  local -a alias_categories
  if [[ -d "$ALIASES_DIR" ]]; then
    while IFS= read -r alias_file; do
      if [[ -f "$alias_file" ]]; then
        local rel_path="${alias_file#$ALIASES_DIR/}"
        local category="${rel_path%.aliases}"
        alias_categories+=("$category")
      fi
    done < <(find "$ALIASES_DIR" -name "*.aliases" -type f 2>/dev/null)
  fi

  # Get config categories
  local -a config_categories
  if [[ -d "$CONFIG_DIR" ]]; then
    while IFS= read -r config_file; do
      if [[ -f "$config_file" ]]; then
        local rel_path="${config_file#$CONFIG_DIR/}"
        local category="${rel_path%.config}"
        config_categories+=("$category")
      fi
    done < <(find "$CONFIG_DIR" -name "*.config" -type f 2>/dev/null)
  fi

  # Main completion logic by argument position
  case $CURRENT in
    2)
      # First argument after dr - always show root content (folders, scripts, special commands, hint)
      # Namespace flags/subcommands are NOT shown in tab completion - user must type them
      local current_word="${words[2]}"

      # Check for folder context
      if [[ "$current_word" == */* ]]; then
        # In folder context - show folder contents only (no commands, no hint)
        local context_path=$(_dr_get_context_path "$current_word")

        # Collect and emit in one go (prefix equals the context)
        _dr_emit_context "$context_path" "$context_path"

        return 0
      else
        # Root context - show ONLY hint, folders, and scripts (NO special commands)
        # Do NOT show namespace flags (-s, -a, -c, -col) or subcommands (scripts, aliases, config, collections)

        # Show hint as non-selectable message
        _message -r $'\e[90m(hint: -s/scripts, -a/aliases, -c/config, -col/collections)\e[0m'

        # Hint + collect + emit via helpers
        _dr_show_hint
        _dr_emit_context "" ""

        return 0
      fi
      ;;
    3)
      # Second argument - context depends on first argument
      case "${words[2]}" in
        -s|scripts)
          # Script management context - show subcommands with proper tag
          _dr_add_commands_with_tag 'script-commands' "${script_commands[@]}"
          return 0
          ;;
        -a|aliases)
          # Aliases management context - show subcommands with proper tag
          _dr_add_commands_with_tag 'aliases-commands' "${aliases_commands[@]}"
          return 0
          ;;
        -c|config)
          # Config management context - show subcommands with proper tag
          _dr_add_commands_with_tag 'config-commands' "${config_commands[@]}"
          return 0
          ;;
        -col|collections)
          # Collections management context - show subcommands
          _dr_add_commands_with_tag 'collections-commands' "${collections_commands[@]}"
          return 0
          ;;
        set)
          # Support folder navigation for implicit set: dr set git/<tab>
          local current_word="${words[3]}"
          if [[ "$current_word" == */* ]]; then
            # In folder context - use _dr_emit_context to preserve path prefix
            local context_path=$(_dr_get_context_path "$current_word")
            _dr_emit_context "$context_path" "$context_path"
          else
            # Root context - show folders and scripts
            _dr_emit_context "" ""
          fi
          ;;
        edit|help)
          # Support hierarchical navigation for edit/help commands
          local current_word="${words[3]}"
          if [[ "$current_word" == */* ]]; then
            # In folder context - use _dr_emit_context to preserve path prefix
            local context_path=$(_dr_get_context_path "$current_word")
            _dr_emit_context "$context_path" "$context_path"
          else
            # Root context - show folders and scripts with colors/emojis
            _dr_emit_context "" ""
          fi
          ;;
        move|rename|mv)
          # Support hierarchical navigation for move/rename source argument
          local current_word="${words[3]}"
          if [[ "$current_word" == */* ]]; then
            # In folder context - use _dr_emit_context to preserve path prefix
            local context_path=$(_dr_get_context_path "$current_word")
            _dr_emit_context "$context_path" "$context_path"
          else
            # Root context - show folders and scripts with colors/emojis
            _dr_emit_context "" ""
          fi
          ;;
        remove)
          # Support hierarchical navigation for removal
          local current_word="${words[3]}"
          if [[ "$current_word" == */* ]]; then
            # In folder context - use _dr_emit_context to preserve path prefix
            local context_path=$(_dr_get_context_path "$current_word")
            _dr_emit_context "$context_path" "$context_path"
          else
            # Root context - show folders and scripts with colors/emojis
            _dr_emit_context "" ""
          fi
          ;;
        -l|-L)
          # Optional folder filter for list commands
          _dr_get_folders "" | _dr_add_folders
          ;;
      esac
      ;;
    4)
      # Third argument - depends on first and second arguments
      case "${words[2]}" in
        move|rename|mv)
          # Destination argument for implicit move/rename
          # Support folder navigation: dr move old git/new
          local current_word="${words[4]}"
          if [[ "$current_word" == */* ]]; then
            # In folder context - use _dr_emit_context to preserve path prefix
            local context_path=$(_dr_get_context_path "$current_word")
            _dr_emit_context "$context_path" "$context_path"
          else
            # Root context - show folders for organization
            local -a folders folder_displays
            while IFS= read -r folder; do
              [[ -n "$folder" ]] && folders+=("$folder") && folder_displays+=("📁 $folder")
            done < <(_dr_get_folders "")
            (( ${#folders[@]} )) && _wanted folders expl 'folders' compadd -Q -S '' -d folder_displays -a -- folders
          fi
          ;;
        -s|scripts)
          # Script management subcommands
          case "${words[3]}" in
            set)
              # Show folders and existing scripts for reference
              # Support folder navigation: dr -s set git/<tab>
              local current_word="${words[4]}"
              if [[ "$current_word" == */* ]]; then
                # In folder context - use _dr_emit_context to preserve path prefix
                local context_path=$(_dr_get_context_path "$current_word")
                _dr_emit_context "$context_path" "$context_path"
              else
                # Root context - show folders and scripts
                _dr_emit_context "" ""
              fi
              ;;
            help|remove)
              # Support hierarchical navigation with colors/emojis
              local current_word="${words[4]}"
              if [[ "$current_word" == */* ]]; then
                # In folder context - use _dr_emit_context to preserve path prefix
                local context_path=$(_dr_get_context_path "$current_word")
                _dr_emit_context "$context_path" "$context_path"
              else
                # Root context - show folders and scripts with colors/emojis
                _dr_emit_context "" ""
              fi
              ;;
            move|rename)
              # Support hierarchical navigation for source argument
              local current_word="${words[4]}"
              if [[ "$current_word" == */* ]]; then
                # In folder context - use _dr_emit_context to preserve path prefix
                local context_path=$(_dr_get_context_path "$current_word")
                _dr_emit_context "$context_path" "$context_path"
              else
                # Root context - show folders and scripts with colors/emojis
                _dr_emit_context "" ""
              fi
              ;;
            list)
              # Optional folder filter - support navigation
              local current_word="${words[4]}"
              if [[ "$current_word" == */* ]]; then
                # In folder context - preserve path
                local context_path=$(_dr_get_context_path "$current_word")
                _dr_emit_context "$context_path" "$context_path"
              else
                # Root context - just show folders
                local -a folders folder_displays
                while IFS= read -r folder; do
                  [[ -n "$folder" ]] && folders+=("$folder") && folder_displays+=("📁 $folder")
                done < <(_dr_get_folders "")
                (( ${#folders[@]} )) && _wanted folders expl 'folders' compadd -Q -S '' -d folder_displays -a -- folders
              fi
              ;;
          esac
          ;;
        -a|aliases)
          # Aliases subcommands
          case "${words[3]}" in
            set)
              # Hierarchical navigation for alias files
              # Support folder navigation: dr -a set cd/<tab>
              local current_word="${words[4]}"
              if [[ "$current_word" == */* ]]; then
                # In folder context - use _dr_emit_aliases_context to preserve path prefix
                local context_path=$(_dr_get_context_path "$current_word")
                _dr_emit_aliases_context "$context_path" "$context_path"
              else
                # Root context - show folders and alias files
                _dr_emit_aliases_context "" ""
              fi
              ;;
            remove)
              # Hierarchical navigation for alias files
              local current_word="${words[4]}"
              if [[ "$current_word" == */* ]]; then
                # In folder context - use _dr_emit_aliases_context to preserve path prefix
                local context_path=$(_dr_get_context_path "$current_word")
                _dr_emit_aliases_context "$context_path" "$context_path"
              else
                # Root context - show folders and alias files
                _dr_emit_aliases_context "" ""
              fi
              ;;
            list)
              compadd -- --categories --category
              ;;
          esac
          ;;
        -c|config)
          # Config subcommands
          case "${words[3]}" in
            set)
              # Hierarchical navigation for config files
              # Support folder navigation: dr -c set api/<tab>
              local current_word="${words[4]}"
              if [[ "$current_word" == */* ]]; then
                # In folder context - use _dr_emit_configs_context to preserve path prefix
                local context_path=$(_dr_get_context_path "$current_word")
                _dr_emit_configs_context "$context_path" "$context_path"
              else
                # Root context - show folders and config files
                _dr_emit_configs_context "" ""
              fi
              ;;
            edit)
              # Hierarchical navigation for config files
              local current_word="${words[4]}"
              if [[ "$current_word" == */* ]]; then
                # In folder context - use _dr_emit_configs_context to preserve path prefix
                local context_path=$(_dr_get_context_path "$current_word")
                _dr_emit_configs_context "$context_path" "$context_path"
              else
                # Root context - show folders and config files
                _dr_emit_configs_context "" ""
              fi
              ;;
            get|unset)
              # Complete with config keys
              _describe -t config-keys 'config keys' config_keys
              ;;
            list)
              compadd -- --categories --category --keys-only
              ;;
          esac
          ;;
        -col|collections)
          # Collections subcommands don't need additional completion
          return 0
          ;;
      esac
      ;;
    5)
      # Fourth argument (category completion for --category flags)
      case "${words[2]}" in
        -s|scripts)
          # Destination for move/rename operations
          case "${words[3]}" in
            move|rename)
              # Support folder navigation for destination: dr -s move old git/new
              local current_word="${words[5]}"
              if [[ "$current_word" == */* ]]; then
                # In folder context - use _dr_emit_context to preserve path prefix
                local context_path=$(_dr_get_context_path "$current_word")
                _dr_emit_context "$context_path" "$context_path"
              else
                # Root context - show folders for organization
                local -a folders folder_displays
                while IFS= read -r folder; do
                  [[ -n "$folder" ]] && folders+=("$folder") && folder_displays+=("📁 $folder")
                done < <(_dr_get_folders "")
                (( ${#folders[@]} )) && _wanted folders expl 'folders' compadd -Q -S '' -d folder_displays -a -- folders
              fi
              ;;
          esac
          ;;
        -a|aliases)
          case "${words[3]}" in
            list)
              if [[ "${words[4]}" == "--category" ]]; then
                _describe -t alias-categories 'alias categories' alias_categories
              fi
              ;;
          esac
          ;;
        -c|config)
          case "${words[3]}" in
            get)
              if [[ "${words[4]}" == "${config_keys[(r)${words[4]}]}" ]]; then
                compadd -- --show-value
              fi
              ;;
            list)
              if [[ "${words[4]}" == "--category" ]]; then
                _describe -t config-categories 'config categories' config_categories
              fi
              ;;
            set)
              if [[ "${words[4]}" == "--category" ]]; then
                _describe -t config-categories 'config categories' config_categories
              fi
              ;;
          esac
          ;;
      esac
      ;;
    *)
      # For script execution (when first arg is not a command/flag)
      # Don't complete script arguments
      return 0
      ;;
  esac
}

# Register the completion function
# Only run compdef if the completion system is loaded
if (( $+functions[compdef] )); then
  compdef _dr dr
fi
