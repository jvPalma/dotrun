#!/usr/bin/env fish
# Fish completion for dr with namespace-based UX, hierarchical navigation

# ============================================================================
# CONFIGURATION
# ============================================================================

# Get the scripts directory
function __dr_bin_dir
    if set -q DR_CONFIG
        echo "$DR_CONFIG/scripts"
    else
        echo "$HOME/.config/dotrun/scripts"
    end
end

# Get the aliases directory
function __dr_aliases_dir
    if set -q DR_CONFIG
        echo "$DR_CONFIG/aliases"
    else
        echo "$HOME/.config/dotrun/aliases"
    end
end

# Get the config directory
function __dr_config_dir
    if set -q DR_CONFIG
        echo "$DR_CONFIG/configs"
    else
        echo "$HOME/.config/dotrun/configs"
    end
end

# ============================================================================
# CONTEXT HELPERS
# ============================================================================

# Extract folder context from current token
# Input: "ai/tools/" or "git/branch/script"
# Output: "ai/tools/" or "git/branch/"
function __dr_get_context_path
    set -l token (commandline -ct)
    if string match -q "*/*" -- "$token"
        # Extract everything before last /
        set -l parts (string split "/" -- "$token")
        if test (count $parts) -gt 1
            # Remove last element and rejoin with /
            set -e parts[-1]
            string join "/" $parts
            echo -n "/"
        end
    end
end

# Get folders in a specific context
# Args: context path (e.g., "ai/tools/" or "")
function __dr_get_folders
    set -l context $argv[1]
    set -l search_dir (__dr_bin_dir)

    if test -n "$context"
        set search_dir "$search_dir/$context"
    end

    if not test -d "$search_dir"
        return
    end

    # Get immediate subdirectories only, exclude hidden folders
    for dir in $search_dir/*/
        if test -d "$dir"
            set -l dirname (basename "$dir")
            # Skip hidden folders
            if not string match -q ".*" -- "$dirname"
                echo "$dirname/"
            end
        end
    end | sort
end

# Get scripts in a specific context
# Args: context path (e.g., "ai/tools/" or "")
function __dr_get_scripts
    set -l context $argv[1]
    set -l search_dir (__dr_bin_dir)

    if test -n "$context"
        set search_dir "$search_dir/$context"
    end

    if not test -d "$search_dir"
        return
    end

    # Get immediate .sh files only
    for file in $search_dir/*.sh
        if test -f "$file"
            set -l filename (basename "$file" .sh)
            echo "$filename"
        end
    end 2>/dev/null | sort
end

# Get all scripts recursively (for edit/move/rename/remove)
function __dr_get_all_scripts
    set -l bin_dir (__dr_bin_dir)
    if not test -d "$bin_dir"
        return
    end

    # Find all .sh files, excluding hidden folders
    for file in (find "$bin_dir" -type f -name "*.sh" 2>/dev/null | sort)
        set -l relpath (string replace "$bin_dir/" "" "$file")
        # Skip scripts in hidden folders
        if not string match -q "*/*.*" -- "$relpath"; and not string match -q ".*" -- "$relpath"
            echo (string replace -r '\.sh$' '' "$relpath")
        end
    end
end

# Get folders in aliases directory
# Args: context path (e.g., "cd/" or "")
function __dr_get_alias_folders
    set -l context $argv[1]
    set -l search_dir (__dr_aliases_dir)

    if test -n "$context"
        set search_dir "$search_dir/$context"
    end

    if not test -d "$search_dir"
        return
    end

    # Get immediate subdirectories only, exclude hidden folders
    for dir in $search_dir/*/
        if test -d "$dir"
            set -l dirname (basename "$dir")
            # Skip hidden folders
            if not string match -q ".*" -- "$dirname"
                echo "$dirname/"
            end
        end
    end | sort
end

# Get alias files in a specific context
# Args: context path (e.g., "cd/" or "")
function __dr_get_alias_files
    set -l context $argv[1]
    set -l search_dir (__dr_aliases_dir)

    if test -n "$context"
        set search_dir "$search_dir/$context"
    end

    if not test -d "$search_dir"
        return
    end

    # Get immediate .aliases files only
    for file in $search_dir/*.aliases
        if test -f "$file"
            set -l filename (basename "$file" .aliases)
            echo "$filename"
        end
    end 2>/dev/null | sort
end

# ============================================================================
# HIERARCHICAL COMPLETION FUNCTIONS
# ============================================================================

# Complete items in current context (folders + scripts)
function __dr_complete_context
    set -l token (commandline -ct)
    set -l context ""

    # Extract context from token if it contains /
    if string match -q "*/*" -- "$token"
        set -l parts (string split "/" -- "$token")
        if test (count $parts) -gt 1
            set -e parts[-1]
            set context (string join "/" $parts)"/"
        end
    end

    # Get folders and scripts in context
    set -l folders (__dr_get_folders "$context")
    set -l scripts (__dr_get_scripts "$context")

    # Output with proper prefixes
    for folder in $folders
        echo "$context$folder"
    end

    for script in $scripts
        echo "$context$script"
    end
end

# Complete items in alias context (folders + alias files)
function __dr_complete_alias_context
    set -l token (commandline -ct)
    set -l context ""

    # Extract context from token if it contains /
    if string match -q "*/*" -- "$token"
        set -l parts (string split "/" -- "$token")
        if test (count $parts) -gt 1
            set -e parts[-1]
            set context (string join "/" $parts)"/"
        end
    end

    # Get folders and alias files in context
    set -l folders (__dr_get_alias_folders "$context")
    set -l alias_files (__dr_get_alias_files "$context")

    # Output with proper prefixes
    for folder in $folders
        echo "$context$folder"
    end

    for alias_file in $alias_files
        echo "$context$alias_file"
    end
end

# Get folders in configs directory
# Args: context path (e.g., "api/" or "")
function __dr_get_config_folders
    set -l context $argv[1]
    set -l search_dir (__dr_config_dir)

    if test -n "$context"
        set search_dir "$search_dir/$context"
    end

    if not test -d "$search_dir"
        return
    end

    # Get immediate subdirectories only, exclude hidden folders
    for dir in $search_dir/*/
        if test -d "$dir"
            set -l dirname (basename "$dir")
            # Skip hidden folders
            if not string match -q ".*" -- "$dirname"
                echo "$dirname/"
            end
        end
    end | sort
end

# Get config files in a specific context
# Args: context path (e.g., "api/" or "")
function __dr_get_config_files
    set -l context $argv[1]
    set -l search_dir (__dr_config_dir)

    if test -n "$context"
        set search_dir "$search_dir/$context"
    end

    if not test -d "$search_dir"
        return
    end

    # Get immediate .config files only
    for file in $search_dir/*.config
        if test -f "$file"
            set -l filename (basename "$file" .config)
            echo "$filename"
        end
    end 2>/dev/null | sort
end

# Complete items in config context (folders + config files)
function __dr_complete_config_context
    set -l token (commandline -ct)
    set -l context ""

    # Extract context from token if it contains /
    if string match -q "*/*" -- "$token"
        set -l parts (string split "/" -- "$token")
        if test (count $parts) -gt 1
            set -e parts[-1]
            set context (string join "/" $parts)"/"
        end
    end

    # Get folders and config files in context
    set -l folders (__dr_get_config_folders "$context")
    set -l config_files (__dr_get_config_files "$context")

    # Output with proper prefixes
    for folder in $folders
        echo "$context$folder"
    end

    for config_file in $config_files
        echo "$context$config_file"
    end
end

# ============================================================================
# CONDITION PREDICATES
# ============================================================================

# Check if we're completing the first argument
function __dr_needs_first_arg
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 1
end

# Check if first arg matches a value
function __dr_first_arg_is
    set -l value $argv[1]
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 2; and test "$cmd[2]" = "$value"
end

# Check if we're at second position
function __dr_needs_second_arg
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 2
end

# Check if second arg matches a value
function __dr_second_arg_is
    set -l value $argv[1]
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 3; and test "$cmd[3]" = "$value"
end

# Check if we're at third position
function __dr_needs_third_arg
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 3
end

# Check if third arg matches a value
function __dr_third_arg_is
    set -l value $argv[1]
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 4; and test "$cmd[4]" = "$value"
end

# Check for namespace flag or word
function __dr_in_scripts_namespace
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 2; and contains -- "$cmd[2]" -s scripts
end

function __dr_in_aliases_namespace
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 2; and contains -- "$cmd[2]" -a aliases
end

function __dr_in_config_namespace
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 2; and contains -- "$cmd[2]" -c config
end

function __dr_in_collections_namespace
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 2; and contains -- "$cmd[2]" -col collections
end

# ============================================================================
# ALIAS AND CONFIG HELPERS
# ============================================================================

# Get alias file names (for remove command completion)
function __dr_alias_files
    set -l aliases_dir (__dr_aliases_dir)
    if test -d "$aliases_dir"
        for alias_file in (find "$aliases_dir" -name "*.aliases" -type f 2>/dev/null | sort)
            if test -f "$alias_file"
                set -l rel_path (string replace "$aliases_dir/" "" "$alias_file")
                string replace -r '\.aliases$' '' "$rel_path"
            end
        end
    end
end

# Get available config keys
function __dr_config_keys
    set -l config_dir (__dr_config_dir)
    if test -d "$config_dir"
        for config_file in (find "$config_dir" -name "*.config" -type f 2>/dev/null | sort)
            if test -f "$config_file"
                grep -E "^export " "$config_file" 2>/dev/null | sed 's/^export \([^=]*\)=.*/\1/'
            end
        end | sort -u
    end
end

# Get alias categories
function __dr_alias_categories
    set -l aliases_dir (__dr_aliases_dir)
    if test -d "$aliases_dir"
        for alias_file in (find "$aliases_dir" -name "*.aliases" -type f 2>/dev/null)
            set -l rel_path (string replace "$aliases_dir/" "" "$alias_file")
            string replace -r '\.aliases$' '' "$rel_path"
        end | sort -u
    end
end

# Get config categories
function __dr_config_categories
    set -l config_dir (__dr_config_dir)
    if test -d "$config_dir"
        for config_file in (find "$config_dir" -name "*.config" -type f 2>/dev/null)
            set -l rel_path (string replace "$config_dir/" "" "$config_file")
            string replace -r '\.config$' '' "$rel_path"
        end | sort -u
    end
end

# ============================================================================
# COMPLETION REGISTRATION
# ============================================================================

# Disable file completion by default
complete -c dr -f

# ============================================================================
# POSITION 1: Root level (folders, scripts, special commands)
# ============================================================================

# Folders and scripts with hierarchical navigation
complete -c dr -n __dr_needs_first_arg -a "(__dr_complete_context)" -d "📁 Folder / 🚀 Script"

# Special commands (green in zsh equivalent)
complete -c dr -n __dr_needs_first_arg -a "help" -d "Show embedded documentation"
# NOTE: reload is a global command but not shown in root completion per standardize-feature-commands spec
complete -c dr -n __dr_needs_first_arg -s l -d "List scripts (names only)"
complete -c dr -n __dr_needs_first_arg -s L -d "List scripts with documentation"
complete -c dr -n __dr_needs_first_arg -s h -d "Show help"
complete -c dr -n __dr_needs_first_arg -l help -d "Show help"

# Direct script management commands (backwards compatibility, but not shown in tab)
# These work when typed but don't clutter the completion

# ============================================================================
# NAMESPACE FLAGS (for organization, not shown at root)
# ============================================================================

# Script namespace
complete -c dr -n __dr_needs_first_arg -s s -d "Script management namespace"
complete -c dr -n __dr_needs_first_arg -a "scripts" -d "Script management namespace"

# Aliases namespace
complete -c dr -n __dr_needs_first_arg -s a -d "Aliases management namespace"
complete -c dr -n __dr_needs_first_arg -a "aliases" -d "Aliases management namespace"

# Config namespace
complete -c dr -n __dr_needs_first_arg -s c -d "Config management namespace"
complete -c dr -n __dr_needs_first_arg -a "config" -d "Config management namespace"

# Collections namespace
complete -c dr -n __dr_needs_first_arg -o col -d "Collections management namespace"
complete -c dr -n __dr_needs_first_arg -a "collections" -d "Collections management namespace"

# ============================================================================
# POSITION 2: After namespace or direct command
# ============================================================================

# Script management commands (after -s or scripts)
complete -c dr -n __dr_in_scripts_namespace -n __dr_needs_second_arg -a "set" -d "Create or open script (idempotent)"
complete -c dr -n __dr_in_scripts_namespace -n __dr_needs_second_arg -a "move" -d "Move/rename script"
complete -c dr -n __dr_in_scripts_namespace -n __dr_needs_second_arg -a "rm" -d "Remove script"
complete -c dr -n __dr_in_scripts_namespace -n __dr_needs_second_arg -a "help" -d "Show script documentation"

# Aliases management commands (after -a or aliases)
complete -c dr -n __dr_in_aliases_namespace -n __dr_needs_second_arg -a "move" -d "Move/rename an alias file"
complete -c dr -n __dr_in_aliases_namespace -n __dr_needs_second_arg -a "rm" -d "Remove an alias file"
complete -c dr -n __dr_in_aliases_namespace -n __dr_needs_second_arg -a "help" -d "Show alias file documentation"
complete -c dr -n __dr_in_aliases_namespace -n __dr_needs_second_arg -a "init" -d "Initialize aliases folder structure"
complete -c dr -n __dr_in_aliases_namespace -n __dr_needs_second_arg -a "-l" -d "List aliases (short format)"
complete -c dr -n __dr_in_aliases_namespace -n __dr_needs_second_arg -a "-L" -d "List aliases with documentation (long format)"

# Config management commands (after -c or config)
complete -c dr -n __dr_in_config_namespace -n __dr_needs_second_arg -a "move" -d "Move/rename a config file"
complete -c dr -n __dr_in_config_namespace -n __dr_needs_second_arg -a "rm" -d "Remove a config file"
complete -c dr -n __dr_in_config_namespace -n __dr_needs_second_arg -a "help" -d "Show config file documentation"
complete -c dr -n __dr_in_config_namespace -n __dr_needs_second_arg -a "init" -d "Initialize configs folder structure"
complete -c dr -n __dr_in_config_namespace -n __dr_needs_second_arg -a "-l" -d "List configs (short format)"
complete -c dr -n __dr_in_config_namespace -n __dr_needs_second_arg -a "-L" -d "List configs with documentation (long format)"
# Also show config files for default add/edit behavior
complete -c dr -n __dr_in_config_namespace -n __dr_needs_second_arg -a "(__dr_complete_config_context)" -d "📁 Folder / ⚙ Config file"

# Collections management commands (after -col or collections)
complete -c dr -n __dr_in_collections_namespace -n __dr_needs_second_arg -a "list" -d "List collections"
complete -c dr -n __dr_in_collections_namespace -n __dr_needs_second_arg -a "list:details" -d "List with details"
complete -c dr -n __dr_in_collections_namespace -n __dr_needs_second_arg -a "remove" -d "Remove collection"

# Direct commands (backwards compatibility)
complete -c dr -n "__dr_first_arg_is set" -a "(__dr_complete_context)" -d "📁 Navigate folders"
complete -c dr -n "__dr_first_arg_is move" -a "(__dr_complete_context)" -d "📁 Folder / 🚀 Script"
complete -c dr -n "__dr_first_arg_is rm" -a "(__dr_complete_context)" -d "📁 Folder / 🚀 Script"
complete -c dr -n "__dr_first_arg_is help" -a "(__dr_complete_context)" -d "📁 Folder / 🚀 Script"

# List command folder filter
complete -c dr -n "__dr_first_arg_is -l" -a "(__dr_get_folders '')" -d "📁 Filter by folder"
complete -c dr -n "__dr_first_arg_is -L" -a "(__dr_get_folders '')" -d "📁 Filter by folder"

# ============================================================================
# POSITION 3: After namespace and command
# ============================================================================

# Script namespace operations
complete -c dr -n __dr_in_scripts_namespace -n "__dr_second_arg_is set" -a "(__dr_complete_context)" -d "📁 Navigate folders"
complete -c dr -n __dr_in_scripts_namespace -n "__dr_second_arg_is move" -a "(__dr_complete_context)" -d "📁 Folder / 🚀 Script"
complete -c dr -n __dr_in_scripts_namespace -n "__dr_second_arg_is rm" -a "(__dr_complete_context)" -d "📁 Folder / 🚀 Script"
complete -c dr -n __dr_in_scripts_namespace -n "__dr_second_arg_is help" -a "(__dr_complete_context)" -d "📁 Folder / 🚀 Script"

# Aliases namespace operations
complete -c dr -n __dr_in_aliases_namespace -n "__dr_second_arg_is move" -a "(__dr_complete_alias_context)" -d "📁 Folder / 🎭 Alias file"
complete -c dr -n __dr_in_aliases_namespace -n "__dr_second_arg_is rm" -a "(__dr_complete_alias_context)" -d "📁 Folder / 🎭 Alias file"
complete -c dr -n __dr_in_aliases_namespace -n "__dr_second_arg_is help" -a "(__dr_complete_alias_context)" -d "📁 Folder / 🎭 Alias file"
complete -c dr -n __dr_in_aliases_namespace -n "__dr_second_arg_is -l" -a "(__dr_get_alias_folders '')" -d "📁 Filter by folder"
complete -c dr -n __dr_in_aliases_namespace -n "__dr_second_arg_is -L" -a "(__dr_get_alias_folders '')" -d "📁 Filter by folder"

# Config namespace operations
complete -c dr -n __dr_in_config_namespace -n "__dr_second_arg_is set" -a "(__dr_complete_config_context)" -d "📁 Folder / ⚙ Config file"
complete -c dr -n __dr_in_config_namespace -n "__dr_second_arg_is move" -a "(__dr_complete_config_context)" -d "📁 Folder / ⚙ Config file"
complete -c dr -n __dr_in_config_namespace -n "__dr_second_arg_is rm" -a "(__dr_complete_config_context)" -d "📁 Folder / ⚙ Config file"
complete -c dr -n __dr_in_config_namespace -n "__dr_second_arg_is help" -a "(__dr_complete_config_context)" -d "📁 Folder / ⚙ Config file"
complete -c dr -n __dr_in_config_namespace -n "__dr_second_arg_is -l" -a "(__dr_get_config_folders '')" -d "📁 Filter by folder"
complete -c dr -n __dr_in_config_namespace -n "__dr_second_arg_is -L" -a "(__dr_get_config_folders '')" -d "📁 Filter by folder"

# ============================================================================
# POSITION 4: Move/rename destinations
# ============================================================================

# Move/rename destination for direct commands
function __dr_needs_move_dest
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 3; and contains -- "$cmd[2]" move rename mv
end

complete -c dr -n __dr_needs_move_dest -a "(__dr_complete_context)" -d "📁 Destination folder"

# Move/rename destination for namespace commands
function __dr_needs_namespace_move_dest
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 4
        if contains -- "$cmd[2]" -s scripts
            return (contains -- "$cmd[3]" move rename)
        end
        if contains -- "$cmd[2]" -a aliases
            return (contains -- "$cmd[3]" move)
        end
        if contains -- "$cmd[2]" -c config
            return (contains -- "$cmd[3]" move)
        end
    end
    return 1
end

# Scripts move destination
function __dr_needs_scripts_move_dest
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 4
        if contains -- "$cmd[2]" -s scripts
            return (contains -- "$cmd[3]" move rename)
        end
    end
    return 1
end

# Aliases move destination
function __dr_needs_aliases_move_dest
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 4
        if contains -- "$cmd[2]" -a aliases
            return (contains -- "$cmd[3]" move)
        end
    end
    return 1
end

complete -c dr -n __dr_needs_scripts_move_dest -a "(__dr_complete_context)" -d "📁 Destination folder"
complete -c dr -n __dr_needs_aliases_move_dest -a "(__dr_complete_alias_context)" -d "📁 Destination folder"

# Configs move destination
function __dr_needs_configs_move_dest
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 4
        if contains -- "$cmd[2]" -c config
            return (contains -- "$cmd[3]" move)
        end
    end
    return 1
end

complete -c dr -n __dr_needs_configs_move_dest -a "(__dr_complete_config_context)" -d "📁 Destination folder"

# ============================================================================
# CATEGORY COMPLETIONS
# ============================================================================

# Complete category names after --category flag (config only - aliases uses path syntax)
complete -c dr -n "contains -- --category (commandline -opc)" -n __dr_in_config_namespace -a "(__dr_config_categories)" -d "Category"

# ============================================================================
# ENABLE FILE COMPLETION FOR NEW NAMES
# ============================================================================

# Re-enable file completion for 'set' to allow new script/config names
complete -c dr -n "__dr_first_arg_is set" -F
complete -c dr -n __dr_in_scripts_namespace -n "__dr_second_arg_is set" -F
complete -c dr -n __dr_in_config_namespace -n "__dr_second_arg_is set" -F

# Re-enable for move/rename destinations to allow new names
complete -c dr -n __dr_needs_move_dest -F
complete -c dr -n __dr_needs_scripts_move_dest -F
complete -c dr -n __dr_needs_aliases_move_dest -F