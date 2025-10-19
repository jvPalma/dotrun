# Fish completion for dr

# Get the bin directory
function __dr_bin_dir
    if set -q DR_CONFIG
        echo "$DR_CONFIG/bin"
    else
        echo "$HOME/.config/dotrun/bin"
    end
end

# Get all available scripts
function __dr_scripts
    set -l bin_dir (__dr_bin_dir)
    if test -d $bin_dir
        find $bin_dir -type f -name "*.sh" 2>/dev/null | sed "s|^$bin_dir/||; s/\.sh\$//" 2>/dev/null | sort 2>/dev/null
    end
end

# Get all folders for -l and -L
function __dr_folders
    set -l bin_dir (__dr_bin_dir)
    if test -d $bin_dir
        find $bin_dir -type d 2>/dev/null | sed "s|^$bin_dir||; s|^/||" 2>/dev/null | grep -v '^$' 2>/dev/null | sed 's|$|/|' 2>/dev/null | sort 2>/dev/null
    end
end

# Get available aliases
function __dr_aliases
    set -l aliases_dir
    if set -q DR_CONFIG
        set aliases_dir "$DR_CONFIG/aliases"
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
function __dr_config_keys
    set -l config_dir
    if set -q DR_CONFIG
        set config_dir "$DR_CONFIG/config"
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
function __dr_alias_categories
    set -l aliases_dir
    if set -q DR_CONFIG
        set aliases_dir "$DR_CONFIG/aliases"
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
function __dr_config_categories
    set -l config_dir
    if set -q DR_CONFIG
        set config_dir "$DR_CONFIG/config"
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
function __dr_needs_script
    set -l cmd (commandline -opc 2>/dev/null)
    set -l subcmds edit help move rename mv
    if test (count $cmd) -eq 2 2>/dev/null
        and contains $cmd[2] $subcmds 2>/dev/null
        return 0
    end
    return 1
end

# Check if we should complete folders
function __dr_needs_folder
    set -l cmd (commandline -opc 2>/dev/null)
    if test (count $cmd) -eq 2 2>/dev/null
        and contains $cmd[2] -l -L 2>/dev/null
        return 0
    end
    return 1
end

# Check if we're completing the first argument
function __dr_needs_command
    set -l cmd (commandline -opc 2>/dev/null)
    test (count $cmd) -eq 1 2>/dev/null
end

# Disable file completion by default
complete -c dr -f

# Commands
complete -c dr -n __dr_needs_command -a add -d "Create and open new script in editor"
complete -c dr -n __dr_needs_command -a edit -d "Open existing script in editor"
complete -c dr -n __dr_needs_command -a help -d "Show embedded docs for script"
complete -c dr -n __dr_needs_command -a move -d "Move/rename a script"
complete -c dr -n __dr_needs_command -a rename -d "Move/rename a script (alias for move)"
complete -c dr -n __dr_needs_command -a mv -d "Move/rename a script (alias for move)"
complete -c dr -n __dr_needs_command -a aliases -d "Manage shell aliases"
complete -c dr -n __dr_needs_command -a config -d "Manage configuration variables"
complete -c dr -n __dr_needs_command -a collections -d "Manage script collections from GitHub"

# Flags
complete -c dr -n __dr_needs_command -s l -d "List all scripts (names only)"
complete -c dr -n __dr_needs_command -s L -d "List scripts with docs"
complete -c dr -n __dr_needs_command -s h -d "Show help"
complete -c dr -n __dr_needs_command -l help -d "Show help"

# Scripts (for both execution and as arguments to commands)
complete -c dr -n __dr_needs_command -a "(__dr_scripts)" -d Script
complete -c dr -n __dr_needs_script -a "(__dr_scripts)" -d Script

# Folders for -l and -L
complete -c dr -n __dr_needs_folder -a "(__dr_folders)" -d Folder

# Helper function to check if argument at index exists and matches value
function __dr_arg_matches
    set -l index $argv[1]
    set -l value $argv[2]
    set -l cmd (commandline -opc 2>/dev/null)
    test (count $cmd) -ge $index 2>/dev/null; and test "$cmd[$index]" = "$value" 2>/dev/null
end

# Helper function to check if we have exactly two arguments and second matches value
function __dr_second_arg_is
    set -l value $argv[1]
    set -l cmd (commandline -opc 2>/dev/null)
    test (count $cmd) -eq 2 2>/dev/null; and test "$cmd[2]" = "$value" 2>/dev/null
end

# Helper function to check if we have exactly three arguments with specific second and third values
function __dr_third_arg_after
    set -l second_arg $argv[1]
    set -l third_arg $argv[2]
    set -l cmd (commandline -opc 2>/dev/null)
    test (count $cmd) -eq 3 2>/dev/null; and test "$cmd[2]" = "$second_arg" 2>/dev/null; and test "$cmd[3]" = "$third_arg" 2>/dev/null
end

# Helper function to check if third argument matches a value
function __dr_third_arg_is
    set -l value $argv[1]
    set -l cmd (commandline -opc 2>/dev/null)
    test (count $cmd) -ge 3 2>/dev/null; and test "$cmd[3]" = "$value" 2>/dev/null
end

# Check if we need destination for move/rename commands
function __dr_needs_move_destination
    set -l cmd (commandline -opc 2>/dev/null)
    test (count $cmd) -eq 3 2>/dev/null; and contains $cmd[2] move rename mv 2>/dev/null
end

# Special handling for 'add' command - allow both existing scripts and new names
complete -c dr -n "__dr_second_arg_is add" -a "(__dr_scripts)" -d "Existing script"
# Re-enable file completion for 'add' to allow new names
complete -c dr -n "__dr_second_arg_is add" -F

# Collections subcommands
complete -c dr -n "__dr_second_arg_is collections" -a list -d "List installed collections"
complete -c dr -n "__dr_second_arg_is collections" -a "list:details" -d "List collections with detailed information"
complete -c dr -n "__dr_second_arg_is collections" -a remove -d "Remove a collection"

# Aliases subcommands
complete -c dr -n "__dr_second_arg_is aliases" -a init -d "Initialize aliases system"
complete -c dr -n "__dr_second_arg_is aliases" -a add -d "Add new alias"
complete -c dr -n "__dr_second_arg_is aliases" -a list -d "List all aliases"
complete -c dr -n "__dr_second_arg_is aliases" -a edit -d "Edit existing alias"
complete -c dr -n "__dr_second_arg_is aliases" -a remove -d "Remove alias"
complete -c dr -n "__dr_second_arg_is aliases" -a reload -d "Reload aliases in current shell"

# Config subcommands
complete -c dr -n "__dr_second_arg_is config" -a init -d "Initialize configuration system"
complete -c dr -n "__dr_second_arg_is config" -a set -d "Set configuration value"
complete -c dr -n "__dr_second_arg_is config" -a get -d "Get configuration value"
complete -c dr -n "__dr_second_arg_is config" -a list -d "List all configuration"
complete -c dr -n "__dr_second_arg_is config" -a edit -d "Edit existing configuration"
complete -c dr -n "__dr_second_arg_is config" -a unset -d "Remove configuration"
complete -c dr -n "__dr_second_arg_is config" -a reload -d "Reload config in current shell"

# Collections subcommands
complete -c dr -n "__dr_second_arg_is collections" -a add -d "Add GitHub repository URL to collections"
complete -c dr -n "__dr_second_arg_is collections" -a list -d "List configured collection URLs"
complete -c dr -n "__dr_second_arg_is collections" -a remove -d "Remove collection URL by number"

# Move/rename destination completion - suggest scripts and folders, enable file completion for custom names
complete -c dr -n __dr_needs_move_destination -a "(__dr_scripts)" -d "Existing script"
complete -c dr -n __dr_needs_move_destination -a "(__dr_folders)" -d "Folder"
complete -c dr -n __dr_needs_move_destination -F

# Aliases third argument completions
complete -c dr -n "__dr_third_arg_after aliases edit" -a "(__dr_aliases)" -d "Alias to edit"
complete -c dr -n "__dr_third_arg_after aliases remove" -a "(__dr_aliases)" -d "Alias to remove"
complete -c dr -n "__dr_second_arg_is aliases" -n "__dr_third_arg_is list" -l categories -d "Show categories"
complete -c dr -n "__dr_second_arg_is aliases" -n "__dr_third_arg_is list" -l category -d "Filter by category" -r
complete -c dr -n "__dr_second_arg_is aliases" -n "__dr_third_arg_is add" -l category -d "Add to category" -r

# Config third argument completions
complete -c dr -n "__dr_third_arg_after config get" -a "(__dr_config_keys)" -d "Config key to get"
complete -c dr -n "__dr_third_arg_after config edit" -a "(__dr_config_keys)" -d "Config key to edit"
complete -c dr -n "__dr_third_arg_after config unset" -a "(__dr_config_keys)" -d "Config key to unset"
complete -c dr -n "__dr_second_arg_is config" -n "__dr_third_arg_is list" -l categories -d "Show categories"
complete -c dr -n "__dr_second_arg_is config" -n "__dr_third_arg_is list" -l category -d "Filter by category" -r
complete -c dr -n "__dr_second_arg_is config" -n "__dr_third_arg_is list" -l keys-only -d "Show keys only"
complete -c dr -n "__dr_second_arg_is config" -n "__dr_third_arg_is set" -l category -d "Set in category" -r
complete -c dr -n "__dr_second_arg_is config" -n "__dr_third_arg_is set" -l secure -d "Mark as secure"
complete -c dr -n "__dr_second_arg_is config" -n "__dr_third_arg_is get" -l show-value -d "Show actual value"

# Category name completions for --category flags
complete -c dr -n "__dr_second_arg_is aliases" -n "contains -- --category (commandline -opc)" -a "(__dr_alias_categories)" -d "Alias category"
complete -c dr -n "__dr_second_arg_is config" -n "contains -- --category (commandline -opc)" -a "(__dr_config_categories)" -d "Config category"
