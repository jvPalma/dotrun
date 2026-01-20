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

# Force menu completion even with 1 match, always show list
zstyle ':completion:*:*:dr:*' menu yes=long select=long
zstyle ':completion:*:*:dr:*' list-prompt ''

# Prevent auto-insertion of ambiguous matches
zstyle ':completion:*:*:dr:*' insert-tab false
zstyle ':completion:*:*:dr:*' insert-unambiguous false

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

# ============================================
# ICON CONSTANTS (SINGLE SOURCE OF TRUTH)
# ============================================
# These icons are used throughout completion display
# Change here to update all decorations consistently
FOLDER_ICON='📁'
SCRIPT_ICON='🚀'
ALIAS_ICON='🎭'
CONFIG_ICON='⚙'

# Main completion function
_dr() {
  # DEBUG: Log every function call
  {
    echo "========================================"
    echo "_dr() called at $(date +%H:%M:%S)"
    echo "CURRENT=$CURRENT"
    echo "words=(${words[@]})"
    echo "========================================"
  } >> /tmp/dr_completion_debug.log

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


  # Helper: Show the gray hint at root
  _dr_show_hint() {
    _message -r $'\e[90m(hint: -s/scripts, -a/aliases, -c/config, -col/collections)\e[0m'
  }

  # Helper: Decorate folder paths with emoji for completion display (SINGLE SOURCE OF TRUTH)
  # Appends decorated folders to the matches and displays arrays via indirect assignment
  #
  # Usage: _dr_decorate_folders <matches_var> <displays_var> <prefix> [mode] folder1 folder2 ...
  #
  # Args:
  #   $1: variable name of array to append matches (for insertion into command line)
  #   $2: variable name of array to append displays (for visual rendering with emoji)
  #   $3: prefix to prepend to matches (e.g., "context/" or "")
  #   $4: display mode (optional, default "simple"):
  #       - "simple": always show "📁 basename/" (for hierarchical navigation)
  #       - "fullpath": show "parent/📁 child/" for nested, "📁 folder/" for root (for search results)
  #   $@: remaining args are folder paths to decorate
  #
  # Example (simple mode - hierarchical navigation):
  #   local -a folder_matches folder_displays
  #   _dr_decorate_folders folder_matches folder_displays "ai/tools/" simple "child1/" "child2/"
  #   # Result: folder_matches=("ai/tools/child1/" "ai/tools/child2/")
  #   #         folder_displays=("📁 child1/" "📁 child2/")
  #
  # Example (fullpath mode - search results):
  #   _dr_decorate_folders folder_matches folder_displays "" fullpath "status/" "ai/tools/"
  #   # Result: folder_matches=("status/" "ai/tools/")
  #   #         folder_displays=("📁 status/" "ai/📁 tools/")
  #
  _dr_decorate_folders() {
    local matches_var="$1" displays_var="$2" prefix="$3" mode="${4:-simple}"
    shift 4

    local item fullpath
    for item; do
      fullpath="${prefix}${item}"
      eval "${matches_var}+=(\"\$fullpath\")"

      if [[ "$mode" == "fullpath" ]]; then
        local path_no_slash="${fullpath%/}"
        if [[ "$path_no_slash" == */* ]]; then
          local parent="${path_no_slash%/*}/"
          local dirname="${path_no_slash##*/}"
          eval "${displays_var}+=(\"${FOLDER_ICON} \${parent} \${dirname}/\")"
        else
          eval "${displays_var}+=(\"${FOLDER_ICON} \$fullpath\")"
        fi
      else
        eval "${displays_var}+=(\"${FOLDER_ICON} \$item\")"
      fi
    done
  }

  # Helper: Decorate file paths with emoji for completion display (SINGLE SOURCE OF TRUTH)
  # Unified function for scripts, aliases, and configs decoration
  # Appends decorated items to the matches and displays arrays via indirect assignment
  #
  # Usage: _dr_decorate_files <type> <matches_var> <displays_var> <prefix> <mode> item1 item2 ...
  #
  # Args:
  #   $1: type - "SCRIPTS", "ALIASES", or "CONFIGS" (determines icon)
  #   $2: variable name of array to append matches (for insertion into command line)
  #   $3: variable name of array to append displays (for visual rendering with emoji)
  #   $4: prefix to prepend to matches (e.g., "ai/tools/" or "")
  #   $5: mode - "simple" or "fullpath"
  #   $@: remaining args are file paths to decorate
  #
  # Example (SCRIPTS, simple mode - hierarchical navigation):
  #   local -a script_matches script_displays
  #   _dr_decorate_files SCRIPTS script_matches script_displays "ai/tools/" simple "deploy" "test"
  #   # Result: script_matches=("ai/tools/deploy" "ai/tools/test")
  #   #         script_displays=("🚀 deploy" "🚀 test")
  #
  # Example (SCRIPTS, fullpath mode - search results):
  #   _dr_decorate_files SCRIPTS script_matches script_displays "" fullpath "status" "git/status/bk"
  #   # Result: script_matches=("status" "git/status/bk")
  #   #         script_displays=("🚀 status" "git/status/🚀 bk")
  #
  # Example (ALIASES, simple mode):
  #   _dr_decorate_files ALIASES alias_matches alias_displays "cd/" simple "git" "docker"
  #   # Result: alias_matches=("cd/git" "cd/docker")
  #   #         alias_displays=("🎭 git" "🎭 docker")
  #
  # Example (CONFIGS, simple mode):
  #   _dr_decorate_files CONFIGS config_matches config_displays "api/" simple "database" "cache"
  #   # Result: config_matches=("api/database" "api/cache")
  #   #         config_displays=("⚙ database" "⚙ cache")
  #
  _dr_decorate_files() {
    local type="$1" matches_var="$2" displays_var="$3" prefix="$4" mode="$5"
    shift 5

    # Determine icon based on type
    local icon
    case "$type" in
      SCRIPTS) icon="$SCRIPT_ICON" ;;
      ALIASES) icon="$ALIAS_ICON" ;;
      CONFIGS) icon="$CONFIG_ICON" ;;
      *) icon="📄" ;;  # Fallback for unknown types
    esac

    local item fullpath
    for item; do
      fullpath="${prefix}${item}"
      eval "${matches_var}+=(\"\$fullpath\")"

      if [[ "$mode" == "fullpath" ]]; then
        if [[ "$fullpath" == */* ]]; then
          local folder="${fullpath%/*}/"
          local filename="${fullpath##*/}"
          eval "${displays_var}+=(\"\${folder} ${icon} \${filename}\")"
        else
          eval "${displays_var}+=(\"${icon} \$fullpath\")"
        fi
      else
        eval "${displays_var}+=(\"${icon} \$item\")"
      fi
    done
  }

  # Helper function: Add folders with emoji display using compadd
  _dr_add_folders() {
    local -a folders folder_matches folder_displays
    while IFS= read -r folder; do
      [[ -n "$folder" ]] && folders+=("$folder")
    done

    # Use centralized decoration function (simple mode - just basename with emoji)
    _dr_decorate_folders folder_matches folder_displays "" simple "${folders[@]}"

    # Only call compset -P '*' if we have folders to add
    # This prevents PREFIX consumption when no completions exist (which causes word deletion)
    if (( ${#folder_matches[@]} )); then
      # This marks the entire typed word as "consumed" before using -U, this means that
      # ZSH will not delete the typed word while still bypassing ZSH filtering
      compset -P '*'
      # this allows us to use -U to bypass ZSH's prefix filtering and show all our pre-filtered results
      # -U: bypass ZSH's prefix filtering
      # -S '': no suffix for folders (they already have trailing slash)
      # -d displays: use our custom display strings with emoji
      # -a folders: add all folder candidates
      compadd -U -S '' -d folder_displays -a folder_matches
    fi
  }
  
  # Helper function: Get folders in context
  # Outputs folders (one per line) without emoji - use dr_add_folders to display with emoji
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

  # Helper: Collect and emit candidates for a context.
  # Arg1: context (e.g., "ai/tools/" or ""), Arg2: prefix to insert (usually same as context)
  _dr_emit_context() {
    local context="$1"
    local prefix="$2"
    local -a folders scripts folder_matches folder_displays script_matches script_displays
    local item

    # Collect raw folder/script names
    while IFS= read -r item; do [[ -n "$item" ]] && folders+=("$item"); done < <(_dr_get_folders "$context")
    while IFS= read -r item; do [[ -n "$item" ]] && scripts+=("$item");  done < <(_dr_get_scripts  "$context")

    # Decorate folders using centralized function (simple mode)
    _dr_decorate_folders folder_matches folder_displays "$prefix" simple "${folders[@]}"

    # Decorate scripts using centralized function (simple mode)
    _dr_decorate_files SCRIPTS script_matches script_displays "$prefix" simple "${scripts[@]}"

    # Emit with tags so group-order (folders → scripts) applies; keep -S '' for folders
    (( ${#folder_matches[@]} )) && _wanted folders expl 'folders' compadd -S '' -d folder_displays -a -- folder_matches
    (( ${#script_matches[@]} )) && _wanted scripts  expl 'scripts'  compadd      -d script_displays -a -- script_matches
  }


  # Helper function: Get scripts in context (strip .sh extension)
  # Outputs scripts (one per line) without emoji
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

  # Helper function: Search all scripts AND folders recursively by pattern
  # Supports case-insensitive substring matching with priority sorting:
  #   Priority 1: Basename prefix match (best)
  #   Priority 2: Basename substring match
  #   Priority 3: Full path substring match (parent dirs contain pattern)
  # Returns: "type:fullpath" where type is 'f' (file) or 'd' (directory)
  _dr_search_recursive() {
    local pattern="$1"
    echo "DEBUG[START]: _dr_search_recursive called with pattern='$pattern', BIN_DIR='$BIN_DIR'" >> /tmp/dr_completion_debug.log

    if [[ ! -d "$BIN_DIR" ]]; then
      echo "DEBUG: BIN_DIR does not exist: '$BIN_DIR'" >> /tmp/dr_completion_debug.log
      return
    fi

    # Convert pattern to lowercase for case-insensitive matching
    local pattern_lower="${(L)pattern}"
    local -a results

    echo "DEBUG: About to run: find \"$BIN_DIR\" -type f -name \"*.sh\" -ipath \"*${pattern}*\" -print0" >> /tmp/dr_completion_debug.log

    # Search for matching scripts (case-insensitive, excluding hidden files)
    while IFS= read -r -d '' file; do
      local fullpath="${file#${BIN_DIR}/}"
      fullpath="${fullpath%.sh}"  # Strip .sh extension for display

      echo "DEBUG[1]: Checking file '$fullpath'" >> /tmp/dr_completion_debug.log

      local basename="${fullpath##*/}"
      local basename_lower="${(L)basename}"
      local fullpath_lower="${(L)fullpath}"

      local priority depth
      # Count depth (number of slashes)
      depth="${fullpath//[^\/]}"
      depth="${#depth}"

      # Determine match priority (check basename first, then full path)
      if [[ "$basename_lower" == "$pattern_lower"* ]]; then
        priority=1  # Basename prefix match (best)
      elif [[ "$basename_lower" == *"$pattern_lower"* ]]; then
        priority=2  # Basename substring match
      elif [[ "$fullpath_lower" == *"$pattern_lower"* ]]; then
        priority=3  # Full path substring match (e.g., parent dir contains pattern)
      else
        continue  # No match, skip
      fi

      # Store as "priority:depth:type:fullpath" for sorting
      results+=("$priority:$depth:f:$fullpath")
    done < <(find "$BIN_DIR" -type f -name "*.sh" -ipath "*${pattern}*" -print0 2>/dev/null)

    # Search for matching folders (case-insensitive, excluding hidden folders)
    while IFS= read -r -d '' dir; do
      local fullpath="${dir#${BIN_DIR}/}"
      fullpath="${fullpath%/}"  # Remove trailing slash

      echo "DEBUG[2]: Checking file '$fullpath'" >> /tmp/dr_completion_debug.log

      # Skip the root BIN_DIR itself
      [[ -z "$fullpath" ]] && continue

      local basename="${fullpath##*/}"
      local basename_lower="${(L)basename}"
      local fullpath_lower="${(L)fullpath}"

      local priority depth
      depth="${fullpath//[^\/]}"
      depth="${#depth}"

      # Determine match priority (check basename first, then full path)
      if [[ "$basename_lower" == "$pattern_lower"* ]]; then
        priority=1  # Basename prefix match
      elif [[ "$basename_lower" == *"$pattern_lower"* ]]; then
        priority=2  # Basename substring match
      elif [[ "$fullpath_lower" == *"$pattern_lower"* ]]; then
        priority=3  # Full path substring match
      else
        continue
      fi

      # Add trailing slash for folders
      results+=("$priority:$depth:d:$fullpath/")
      
      # Also find all .sh files inside matched directories
      while IFS= read -r -d '' nested_file; do
        local nested_fullpath="${nested_file#${BIN_DIR}/}"

      echo "DEBUG[3]: Checking file '$nested_fullpath'" >> /tmp/dr_completion_debug.log
        nested_fullpath="${nested_fullpath%.sh}"
        local nested_depth="${nested_fullpath//[^\/]}"
        nested_depth="${#nested_depth}"
        # Use priority 4 for nested files so they appear after direct matches
        results+=("4:$nested_depth:f:$nested_fullpath")
      done < <(find "${BIN_DIR}/${fullpath}" -type f -name "*.sh" -print0 2>/dev/null)
    done < <(find "$BIN_DIR" -type d -ipath "*${pattern}*" -print0 2>/dev/null)

    # Sort by: priority (lower first), depth (shallower first), name (alphabetically)
    # Output format: "type:fullpath"
    printf '%s\n' "${results[@]}" | sort -t: -k1,1n -k2,2n -k4 | while IFS=: read -r priority depth type fullpath; do
      echo "$type:$fullpath"
    done
  }

  # Helper: Emit recursive search results with colored path display
  # Handles both files (scripts) and directories
  # Uses _wanted for proper tag registration (enables zstyle menu/colors)
  _dr_emit_recursive_search() {
    local pattern="$1"
    echo "DEBUG[EMIT-START]: _dr_emit_recursive_search called with pattern='$pattern'" >> /tmp/dr_completion_debug.log

    local -a folders scripts folder_matches folder_displays script_matches script_displays
    local type fullpath

    echo "DEBUG[EMIT]: About to call _dr_search_recursive" >> /tmp/dr_completion_debug.log
    # Collect folders and scripts separately from search results
    while IFS=: read -r type fullpath; do
      echo "DEBUG[EMIT-LOOP]: Read type='$type' fullpath='$fullpath'" >> /tmp/dr_completion_debug.log
      [[ -z "$type" || -z "$fullpath" ]] && continue

      if [[ "$type" == "d" ]]; then
        folders+=("$fullpath")
      else
        scripts+=("$fullpath")
      fi
    done < <(_dr_search_recursive "$pattern")

    # Decorate folders using centralized function (fullpath mode for search results)
    # Shows "parent/${FOLDER_ICON} child/" for nested, "${FOLDER_ICON} folder/" for root
    _dr_decorate_folders folder_matches folder_displays "" fullpath "${folders[@]}"

    # Decorate scripts using centralized function (fullpath mode for search results)
    # Shows "parent/${SCRIPT_ICON} script" for nested, "${SCRIPT_ICON} script" for root
    _dr_decorate_files SCRIPTS script_matches script_displays "" fullpath "${scripts[@]}"

    echo "DEBUG[EMIT]: After loop: folder_matches=${#folder_matches[@]}, script_matches=${#script_matches[@]}" >> /tmp/dr_completion_debug.log

    local has_matches=0

    # Use -i flag to preserve PREFIX while bypassing ZSH filtering
    # -i "$PREFIX": sets ignored prefix to user's typed text (preserved in command line)
    # -U: bypass ZSH's prefix filtering, show ALL our pre-filtered results
    # This approach is cleaner than compset -P '*' because it doesn't modify PREFIX/IPREFIX
    if (( ${#folder_matches[@]} || ${#script_matches[@]} )); then
      # -U with -i: "only the string from the -i option is used" (not IPREFIX)
      # -S '': no suffix for folders (they already have trailing slash)
      if (( ${#folder_matches[@]} )); then
        compadd -U -i "$PREFIX" -S '' -d folder_displays -a folder_matches
        has_matches=1
      fi
      if (( ${#script_matches[@]} )); then
        compadd -U -i "$PREFIX" -d script_displays -a script_matches
        has_matches=1
      fi
    fi

    (( has_matches )) && return 0 || return 1
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

    # Collect raw folder/file names
    while IFS= read -r item; do [[ -n "$item" ]] && folders+=("$item"); done < <(_dr_get_alias_folders "$context")
    while IFS= read -r item; do [[ -n "$item" ]] && alias_files+=("$item");  done < <(_dr_get_alias_files  "$context")

    # Decorate folders using centralized function (simple mode)
    _dr_decorate_folders folder_matches folder_displays "$prefix" simple "${folders[@]}"

    # Decorate alias files using centralized function
    _dr_decorate_files ALIASES alias_matches alias_displays "$prefix" simple "${alias_files[@]}"

    # Emit with tags so group-order (folders → alias files) applies; keep -S '' for folders
    (( ${#folder_matches[@]} )) && _wanted folders expl 'folders' compadd -S '' -d folder_displays -a -- folder_matches
    (( ${#alias_matches[@]} )) && _wanted aliases  expl 'aliases'  compadd      -d alias_displays -a -- alias_matches
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

    # Collect raw folder/file names
    while IFS= read -r item; do [[ -n "$item" ]] && folders+=("$item"); done < <(_dr_get_config_folders "$context")
    while IFS= read -r item; do [[ -n "$item" ]] && config_files+=("$item");  done < <(_dr_get_config_files  "$context")

    # Decorate folders using centralized function (simple mode)
    _dr_decorate_folders folder_matches folder_displays "$prefix" simple "${folders[@]}"

    # Decorate config files using centralized function
    _dr_decorate_files CONFIGS config_matches config_displays "$prefix" simple "${config_files[@]}"

    # Emit with tags so group-order (folders → config files) applies; keep -S '' for folders
    (( ${#folder_matches[@]} )) && _wanted folders expl 'folders' compadd -S '' -d folder_displays -a -- folder_matches
    (( ${#config_matches[@]} )) && _wanted configs  expl 'configs'  compadd      -d config_displays -a -- config_matches
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

      # DEBUG
      {
        echo "=== POSITION 2 DEBUG ==="
        echo "current_word='$current_word'"
        echo "is slash? $([[ "$current_word" == */* ]] && echo YES || echo NO)"
        echo "is empty? $([[ -z "$current_word" ]] && echo YES || echo NO)"
        echo "starts with dash? $([[ "$current_word" == -* ]] && echo YES || echo NO)"
      } >> /tmp/dr_completion_debug.log

      # Check for folder context
      if [[ "$current_word" == */* ]]; then
        echo "BRANCH: folder context" >> /tmp/dr_completion_debug.log
        # In folder context - show folder contents only (no commands, no hint)
        local context_path=$(_dr_get_context_path "$current_word")

        # Collect and emit in one go (prefix equals the context)
        _dr_emit_context "$context_path" "$context_path"

        return 0
      else
        # Root context - check if user has typed a search pattern
        if [[ -n "$current_word" && "$current_word" != -* ]]; then
          echo "BRANCH: recursive search for pattern='$current_word'" >> /tmp/dr_completion_debug.log
          # User has typed a pattern (like "pr") - do recursive search ONLY
          # COMPLETELY BLOCK default context - do NOT call _dr_emit_context
          _dr_emit_recursive_search "$current_word"
          # Return immediately - no other completions allowed
          echo "RETURNED from recursive search" >> /tmp/dr_completion_debug.log
          return
        else
          echo "BRANCH: default context (hint + folders + scripts)" >> /tmp/dr_completion_debug.log
          # Empty or starts with dash - show ONLY hint, folders, and scripts (NO special commands)
          # Do NOT show namespace flags (-s, -a, -c, -col) or subcommands (scripts, aliases, config, collections)

          # Show hint as non-selectable message
          _message -r $'\e[90m(hint: -s/scripts, -a/aliases, -c/config, -col/collections)\e[0m'

          # Hint + collect + emit via helpers
          _dr_show_hint
          _dr_emit_context "" ""

          return 0
        fi
      fi
      ;;
    3)
      # Second argument - context depends on first argument
      case "${words[2]}" in
        -s|scripts)
          # Script management context
          local current_word="${words[3]}"

          # DEBUG
          {
            echo "=== POSITION 3 (-s/scripts) DEBUG ==="
            echo "words[2]='${words[2]}'"
            echo "words[3]='${words[3]}'"
            echo "current_word='$current_word'"
            echo "is empty? $([[ -z "$current_word" ]] && echo YES || echo NO)"
            echo "starts with dash? $([[ "$current_word" == -* ]] && echo YES || echo NO)"
          } >> /tmp/dr_completion_debug.log

          # If user has typed a pattern (not a flag), show matching scripts recursively
          if [[ -n "$current_word" && "$current_word" != -* ]]; then
            echo "Pattern detected - calling recursive search" >> /tmp/dr_completion_debug.log
            # Show recursive search results for scripts matching the pattern
            _dr_emit_recursive_search "$current_word"
          fi

          # Always show subcommands for discoverability (unless searching)
          # This allows users to see both search results AND available commands
          if [[ -z "$current_word" || "$current_word" == -* ]]; then
            echo "Showing subcommands" >> /tmp/dr_completion_debug.log
            _dr_add_commands_with_tag 'script-commands' "${script_commands[@]}"
          fi

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
            local -a folders folder_matches folder_displays
            while IFS= read -r folder; do
              [[ -n "$folder" ]] && folders+=("$folder")
            done < <(_dr_get_folders "")
            _dr_decorate_folders folder_matches folder_displays "" simple "${folders[@]}"
            (( ${#folder_matches[@]} )) && _wanted folders expl 'folders' compadd -S '' -d folder_displays -a -- folder_matches
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
                local -a folders folder_matches folder_displays
                while IFS= read -r folder; do
                  [[ -n "$folder" ]] && folders+=("$folder")
                done < <(_dr_get_folders "")
                _dr_decorate_folders folder_matches folder_displays "" simple "${folders[@]}"
                (( ${#folder_matches[@]} )) && _wanted folders expl 'folders' compadd -S '' -d folder_displays -a -- folder_matches
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
                local -a folders folder_matches folder_displays
                while IFS= read -r folder; do
                  [[ -n "$folder" ]] && folders+=("$folder")
                done < <(_dr_get_folders "")
                _dr_decorate_folders folder_matches folder_displays "" simple "${folders[@]}"
                (( ${#folder_matches[@]} )) && _wanted folders expl 'folders' compadd -S '' -d folder_displays -a -- folder_matches
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
