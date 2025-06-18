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
        find $bin_dir -type f -name "*.sh" 2>/dev/null | sed "s|^$bin_dir/||; s/\.sh\$//" | sort
    end
end

# Get all folders for -l and -L
function __drun_folders
    set -l bin_dir (__drun_bin_dir)
    if test -d $bin_dir
        find $bin_dir -type d 2>/dev/null | sed "s|^$bin_dir||; s|^/||" | grep -v '^$' | sed 's|$|/|' | sort
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
    if test -d $collections_dir
        ls -1 $collections_dir 2>/dev/null
    end
end

# Check if we should complete scripts
function __drun_needs_script
    set -l cmd (commandline -opc)
    set -l subcmds edit edit:docs help docs details
    if test (count $cmd) -eq 2
        and contains $cmd[2] $subcmds
        return 0
    end
    return 1
end

# Check if we should complete folders
function __drun_needs_folder
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 2
        and contains $cmd[2] -l -L
        return 0
    end
    return 1
end

# Check if we're completing the first argument
function __drun_needs_command
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 1
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
complete -c drun -n __drun_needs_command -a yadm-init -d "Setup DotRun to work with existing yadm repository"
complete -c drun -n __drun_needs_command -a import -d "Import script collection from git repo or local path"
complete -c drun -n __drun_needs_command -a export -d "Export collection to directory"
complete -c drun -n __drun_needs_command -a collections -d "Manage installed collections"
complete -c drun -n __drun_needs_command -a team -d "Team collaboration commands"

# Flags
complete -c drun -n __drun_needs_command -s l -d "List all scripts (names only)"
complete -c drun -n __drun_needs_command -s L -d "List scripts with docs"
complete -c drun -n __drun_needs_command -s h -d "Show help"
complete -c drun -n __drun_needs_command -l help -d "Show help"

# Scripts (for both execution and as arguments to commands)
complete -c drun -n __drun_needs_command -a "(__drun_scripts)" -d "Script"
complete -c drun -n __drun_needs_script -a "(__drun_scripts)" -d "Script"

# Folders for -l and -L
complete -c drun -n __drun_needs_folder -a "(__drun_folders)" -d "Folder"

# Special handling for 'add' command - allow both existing scripts and new names
complete -c drun -n "test (commandline -opc)[2] = 'add'" -a "(__drun_scripts)" -d "Existing script"
# Re-enable file completion for 'add' to allow new names
complete -c drun -n "test (commandline -opc)[2] = 'add'" -F

# Collections subcommands
complete -c drun -n "test (commandline -opc)[2] = 'collections'" -a "list" -d "List installed collections"
complete -c drun -n "test (commandline -opc)[2] = 'collections'" -a "list:details" -d "List collections with detailed information"
complete -c drun -n "test (commandline -opc)[2] = 'collections'" -a "remove" -d "Remove a collection"

# Team subcommands
complete -c drun -n "test (commandline -opc)[2] = 'team'" -a "init" -d "Setup team collection from repository"
complete -c drun -n "test (commandline -opc)[2] = 'team'" -a "sync" -d "Sync team collections"

# Export completion - collections
complete -c drun -n "test (commandline -opc)[2] = 'export'" -a "(__drun_collections)" -d "Collection"

# Import completion - files and directories
complete -c drun -n "test (commandline -opc)[2] = 'import'" -F

# Collections remove completion - available collections
complete -c drun -n "test (commandline -opc)[2] = 'collections' -a (commandline -opc)[3] = 'remove'" -a "(__drun_collections)" -d "Collection to remove"