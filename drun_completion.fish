# Fish completion for drun

# Get the bin directory
function __drun_bin_dir
    if set -q DRUN_CONFIG
        echo "$DRUN_CONFIG/bin"
    else
        echo "$HOME/.config/dotrun/bin"
    end
end

# Get all available scripts
function __drun_scripts
    set -l bin_dir (__drun_bin_dir)
    if test -d $bin_dir
        find $bin_dir -type f -name "*.sh" 2>/dev/null | sed "s|^$bin_dir/||; s/\.sh\$//" 2>/dev/null | sort 2>/dev/null
    end
end

# Get all folders for -l and -L
function __drun_folders
    set -l bin_dir (__drun_bin_dir)
    if test -d $bin_dir
        find $bin_dir -type d 2>/dev/null | sed "s|^$bin_dir||; s|^/||" 2>/dev/null | grep -v '^$' 2>/dev/null | sed 's|$|/|' 2>/dev/null | sort 2>/dev/null
    end
end

# Get available collections
function __drun_collections
    set -l collections_dir
    if set -q DRUN_CONFIG
        set collections_dir "$DRUN_CONFIG/collections"
    else
        set collections_dir "$HOME/.config/dotrun/collections"
    end
    if test -d $collections_dir 2>/dev/null
        ls -1 $collections_dir 2>/dev/null | sort 2>/dev/null
    end
end

# Get available aliases
function __drun_aliases
    set -l aliases_dir
    if set -q DRUN_CONFIG
        set aliases_dir "$DRUN_CONFIG/aliases"
    else
        set aliases_dir "$HOME/.config/dotrun/aliases"
    end
    
    # Get aliases from main file
    if test -f "$aliases_dir/.aliases" 2>/dev/null
        grep -E "^alias " "$aliases_dir/.aliases" 2>/dev/null | sed 's/^alias \([^=]*\)=.*/\1/' | sort 2>/dev/null
    end
    
    # Get aliases from category files
    if test -d "$aliases_dir/.aliases.d" 2>/dev/null
        for category_file in "$aliases_dir/.aliases.d"/*.aliases
            if test -f "$category_file" 2>/dev/null
                grep -E "^alias " "$category_file" 2>/dev/null | sed 's/^alias \([^=]*\)=.*/\1/' | sort 2>/dev/null
            end
        end
    end
end

# Get available config keys
function __drun_config_keys
    set -l config_dir
    if set -q DRUN_CONFIG
        set config_dir "$DRUN_CONFIG/config"
    else
        set config_dir "$HOME/.config/dotrun/config"
    end
    
    # Get config keys from main file
    if test -f "$config_dir/.dotrun_config" 2>/dev/null
        grep -E "^export " "$config_dir/.dotrun_config" 2>/dev/null | sed 's/^export \([^=]*\)=.*/\1/' | sort 2>/dev/null
    end
    
    # Get config keys from category files
    if test -d "$config_dir/.dotrun_config.d" 2>/dev/null
        for category_file in "$config_dir/.dotrun_config.d"/*.config
            if test -f "$category_file" 2>/dev/null
                grep -E "^export " "$category_file" 2>/dev/null | sed 's/^export \([^=]*\)=.*/\1/' | sort 2>/dev/null
            end
        end
    end
end

# Get alias categories
function __drun_alias_categories
    set -l aliases_dir
    if set -q DRUN_CONFIG
        set aliases_dir "$DRUN_CONFIG/aliases"
    else
        set aliases_dir "$HOME/.config/dotrun/aliases"
    end
    
    if test -d "$aliases_dir/.aliases.d" 2>/dev/null
        for category_file in "$aliases_dir/.aliases.d"/*.aliases
            if test -f "$category_file" 2>/dev/null
                basename "$category_file" .aliases 2>/dev/null
            end
        end | sort 2>/dev/null
    end
end

# Get config categories
function __drun_config_categories
    set -l config_dir
    if set -q DRUN_CONFIG
        set config_dir "$DRUN_CONFIG/config"
    else
        set config_dir "$HOME/.config/dotrun/config"
    end
    
    if test -d "$config_dir/.dotrun_config.d" 2>/dev/null
        for category_file in "$config_dir/.dotrun_config.d"/*.config
            if test -f "$category_file" 2>/dev/null
                basename "$category_file" .config 2>/dev/null
            end
        end | sort 2>/dev/null
    end
end

# Check if we should complete scripts
function __drun_needs_script
    set -l cmd (commandline -opc 2>/dev/null)
    set -l subcmds edit edit:docs help docs details move rename mv
    if test (count $cmd) -eq 2 2>/dev/null
        and contains $cmd[2] $subcmds 2>/dev/null
        return 0
    end
    return 1
end

# Check if we should complete folders
function __drun_needs_folder
    set -l cmd (commandline -opc 2>/dev/null)
    if test (count $cmd) -eq 2 2>/dev/null
        and contains $cmd[2] -l -L 2>/dev/null
        return 0
    end
    return 1
end

# Check if we're completing the first argument
function __drun_needs_command
    set -l cmd (commandline -opc 2>/dev/null)
    test (count $cmd) -eq 1 2>/dev/null
end

# Disable file completion by default
complete -c drun -f

# Commands
complete -c drun -n __drun_needs_command -a add -d "Create and open new script in editor"
complete -c drun -n __drun_needs_command -a edit -d "Open existing script in editor"
complete -c drun -n __drun_needs_command -a edit:docs -d "Edit documentation for script"
complete -c drun -n __drun_needs_command -a help -d "Show embedded docs for script"
complete -c drun -n __drun_needs_command -a docs -d "Show full markdown documentation"
complete -c drun -n __drun_needs_command -a details -d "Alias for docs command"
complete -c drun -n __drun_needs_command -a move -d "Move/rename a script"
complete -c drun -n __drun_needs_command -a rename -d "Move/rename a script (alias for move)"
complete -c drun -n __drun_needs_command -a mv -d "Move/rename a script (alias for move)"
complete -c drun -n __drun_needs_command -a aliases -d "Manage shell aliases"
complete -c drun -n __drun_needs_command -a config -d "Manage configuration variables"

# Import command options
complete -c drun -n "__drun_second_arg_is import" -l preview -d "Show collection contents without importing"
complete -c drun -n "__drun_second_arg_is import" -l pick -d "Import only specified script" -r

# Flags
complete -c drun -n __drun_needs_command -s l -d "List all scripts (names only)"
complete -c drun -n __drun_needs_command -s L -d "List scripts with docs"
complete -c drun -n __drun_needs_command -s h -d "Show help"
complete -c drun -n __drun_needs_command -l help -d "Show help"

# Scripts (for both execution and as arguments to commands)
complete -c drun -n __drun_needs_command -a "(__drun_scripts)" -d Script
complete -c drun -n __drun_needs_script -a "(__drun_scripts)" -d Script

# Folders for -l and -L
complete -c drun -n __drun_needs_folder -a "(__drun_folders)" -d Folder

# Helper function to check if argument at index exists and matches value
function __drun_arg_matches
    set -l index $argv[1]
    set -l value $argv[2]
    set -l cmd (commandline -opc 2>/dev/null)
    test (count $cmd) -ge $index 2>/dev/null; and test "$cmd[$index]" = "$value" 2>/dev/null
end

# Helper function to check if we have exactly two arguments and second matches value
function __drun_second_arg_is
    set -l value $argv[1]
    set -l cmd (commandline -opc 2>/dev/null)
    test (count $cmd) -eq 2 2>/dev/null; and test "$cmd[2]" = "$value" 2>/dev/null
end

# Helper function to check if we have exactly three arguments with specific second and third values
function __drun_third_arg_after
    set -l second_arg $argv[1]
    set -l third_arg $argv[2]
    set -l cmd (commandline -opc 2>/dev/null)
    test (count $cmd) -eq 3 2>/dev/null; and test "$cmd[2]" = "$second_arg" 2>/dev/null; and test "$cmd[3]" = "$third_arg" 2>/dev/null
end

# Helper function to check if third argument matches a value
function __drun_third_arg_is
    set -l value $argv[1]
    set -l cmd (commandline -opc 2>/dev/null)
    test (count $cmd) -ge 3 2>/dev/null; and test "$cmd[3]" = "$value" 2>/dev/null
end

# Check if we need destination for move/rename commands
function __drun_needs_move_destination
    set -l cmd (commandline -opc 2>/dev/null)
    test (count $cmd) -eq 3 2>/dev/null; and contains $cmd[2] move rename mv 2>/dev/null
end

# Special handling for 'add' command - allow both existing scripts and new names
complete -c drun -n "__drun_second_arg_is add" -a "(__drun_scripts)" -d "Existing script"
# Re-enable file completion for 'add' to allow new names
complete -c drun -n "__drun_second_arg_is add" -F

# Collections subcommands
complete -c drun -n "__drun_second_arg_is collections" -a list -d "List installed collections"
complete -c drun -n "__drun_second_arg_is collections" -a "list:details" -d "List collections with detailed information"
complete -c drun -n "__drun_second_arg_is collections" -a remove -d "Remove a collection"

# Team subcommands
complete -c drun -n "__drun_second_arg_is team" -a init -d "Setup team collection from repository"
complete -c drun -n "__drun_second_arg_is team" -a sync -d "Sync team collections"

# Aliases subcommands
complete -c drun -n "__drun_second_arg_is aliases" -a init -d "Initialize aliases system"
complete -c drun -n "__drun_second_arg_is aliases" -a add -d "Add new alias"
complete -c drun -n "__drun_second_arg_is aliases" -a list -d "List all aliases"
complete -c drun -n "__drun_second_arg_is aliases" -a edit -d "Edit existing alias"
complete -c drun -n "__drun_second_arg_is aliases" -a remove -d "Remove alias"
complete -c drun -n "__drun_second_arg_is aliases" -a reload -d "Reload aliases in current shell"

# Config subcommands
complete -c drun -n "__drun_second_arg_is config" -a init -d "Initialize configuration system"
complete -c drun -n "__drun_second_arg_is config" -a set -d "Set configuration value"
complete -c drun -n "__drun_second_arg_is config" -a get -d "Get configuration value"
complete -c drun -n "__drun_second_arg_is config" -a list -d "List all configuration"
complete -c drun -n "__drun_second_arg_is config" -a edit -d "Edit existing configuration"
complete -c drun -n "__drun_second_arg_is config" -a unset -d "Remove configuration"
complete -c drun -n "__drun_second_arg_is config" -a reload -d "Reload config in current shell"

# Export completion - collections
complete -c drun -n "__drun_second_arg_is export" -a "(__drun_collections)" -d Collection

# Import completion - files and directories
complete -c drun -n "__drun_second_arg_is import" -F

# Collections remove completion - available collections
complete -c drun -n "__drun_third_arg_after collections remove" -a "(__drun_collections)" -d "Collection to remove"

# Move/rename destination completion - suggest scripts and folders, enable file completion for custom names
complete -c drun -n __drun_needs_move_destination -a "(__drun_scripts)" -d "Existing script"
complete -c drun -n __drun_needs_move_destination -a "(__drun_folders)" -d "Folder"
complete -c drun -n __drun_needs_move_destination -F

# Aliases third argument completions
complete -c drun -n "__drun_third_arg_after aliases edit" -a "(__drun_aliases)" -d "Alias to edit"
complete -c drun -n "__drun_third_arg_after aliases remove" -a "(__drun_aliases)" -d "Alias to remove"
complete -c drun -n "__drun_second_arg_is aliases" -n "__drun_third_arg_is list" -l categories -d "Show categories"
complete -c drun -n "__drun_second_arg_is aliases" -n "__drun_third_arg_is list" -l category -d "Filter by category" -r
complete -c drun -n "__drun_second_arg_is aliases" -n "__drun_third_arg_is add" -l category -d "Add to category" -r

# Config third argument completions
complete -c drun -n "__drun_third_arg_after config get" -a "(__drun_config_keys)" -d "Config key to get"
complete -c drun -n "__drun_third_arg_after config edit" -a "(__drun_config_keys)" -d "Config key to edit"
complete -c drun -n "__drun_third_arg_after config unset" -a "(__drun_config_keys)" -d "Config key to unset"
complete -c drun -n "__drun_second_arg_is config" -n "__drun_third_arg_is list" -l categories -d "Show categories"
complete -c drun -n "__drun_second_arg_is config" -n "__drun_third_arg_is list" -l category -d "Filter by category" -r
complete -c drun -n "__drun_second_arg_is config" -n "__drun_third_arg_is list" -l keys-only -d "Show keys only"
complete -c drun -n "__drun_second_arg_is config" -n "__drun_third_arg_is set" -l category -d "Set in category" -r
complete -c drun -n "__drun_second_arg_is config" -n "__drun_third_arg_is set" -l secure -d "Mark as secure"
complete -c drun -n "__drun_second_arg_is config" -n "__drun_third_arg_is get" -l show-value -d "Show actual value"

# Category name completions for --category flags
complete -c drun -n "__drun_second_arg_is aliases" -n "contains -- --category (commandline -opc)" -a "(__drun_alias_categories)" -d "Alias category"
complete -c drun -n "__drun_second_arg_is config" -n "contains -- --category (commandline -opc)" -a "(__drun_config_categories)" -d "Config category"
