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