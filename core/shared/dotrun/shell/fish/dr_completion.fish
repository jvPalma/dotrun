#!/usr/bin/env fish
# Fish completion for dr — mirrors zsh reference behavior
# Note: Fish's declarative completion API has limitations vs zsh's imperative model:
#   - No per-item colors in completion candidates
#   - No non-selectable hint messages
#   - Descriptions are per-registration, not per-candidate
# We work within these constraints while matching zsh behavior as closely as possible.

# ============================================================================
# CONFIGURATION
# ============================================================================

function __dr_bin_dir
    if set -q DR_CONFIG
        echo "$DR_CONFIG/scripts"
    else
        echo "$HOME/.config/dotrun/scripts"
    end
end

function __dr_aliases_dir
    if set -q DR_CONFIG
        echo "$DR_CONFIG/aliases"
    else
        echo "$HOME/.config/dotrun/aliases"
    end
end

function __dr_config_dir
    if set -q DR_CONFIG
        echo "$DR_CONFIG/configs"
    else
        echo "$HOME/.config/dotrun/configs"
    end
end

# ============================================================================
# UNIFIED FILESYSTEM FINDER (mirrors zsh _dr_global_filesystem_find)
# ============================================================================
# __dr_filesystem_find <context> <type> <depth> [subcontext] [pattern]
#
# Args:
#   context:    'scripts' | 'aliases' | 'configs'
#   type:       'file' | 'directory'
#   depth:      'single' | 'all'
#   subcontext: Optional relative path within context
#   pattern:    Optional filter pattern for case-insensitive matching
#
# Output: One result per line
#   - Directories: "dirname/" (with trailing slash)
#   - Files: "filename" (extension stripped)
function __dr_filesystem_find
    set -l context $argv[1]
    set -l type $argv[2]
    set -l depth $argv[3]
    set -l subcontext ""
    set -l pattern ""

    if test (count $argv) -ge 4
        set subcontext $argv[4]
    end
    if test (count $argv) -ge 5
        set pattern $argv[5]
    end

    # Map context to base directory and file extension
    set -l base_dir
    set -l ext
    switch $context
        case scripts
            set base_dir (__dr_bin_dir)
            set ext ".sh"
        case aliases
            set base_dir (__dr_aliases_dir)
            set ext ".aliases"
        case configs
            set base_dir (__dr_config_dir)
            set ext ".config"
        case '*'
            return 1
    end

    # Build search directory
    set -l search_dir "$base_dir"
    if test -n "$subcontext"
        set search_dir "$base_dir/"(string trim -r -c "/" "$subcontext")
    end

    if not test -d "$search_dir"
        return 0
    end

    # Build find command
    set -l find_args "$search_dir" -mindepth 1

    if test "$depth" = single
        set find_args $find_args -maxdepth 1
    end

    # Prune hidden directories
    set find_args $find_args -name '.*' -prune -o

    switch $type
        case file
            set find_args $find_args -type f
        case directory
            set find_args $find_args -type d
    end

    if test "$type" = file; and test -n "$ext"
        set find_args $find_args -name "*$ext"
    end

    if test -n "$pattern"
        set find_args $find_args -ipath "*$pattern*"
    end

    set find_args $find_args -print

    set -l strip_prefix (string trim -r -c "/" "$search_dir")"/"

    for item in (find $find_args 2>/dev/null | sort)
        set -l rel_path (string replace "$strip_prefix" "" "$item")
        if test -z "$rel_path"
            continue
        end

        if test -d "$item"
            echo (string trim -r -c "/" "$rel_path")"/"
        else
            if test -n "$ext"
                set rel_path (string replace -r (string escape --style=regex "$ext")'$' '' "$rel_path")
            end
            echo "$rel_path"
        end
    end
end

# ============================================================================
# COMPLETION GENERATORS
# ============================================================================
# All generators use tab-separated "value\tdescription" output for per-item
# descriptions, and rely on `complete -k` to preserve folders-first ordering.

# Helper: extract folder context from current token
function __dr_extract_context
    set -l token (commandline -ct)
    if string match -q "*/*" -- "$token"
        set -l parts (string split "/" -- "$token")
        if test (count $parts) -gt 1
            set -e parts[-1]
            echo (string join "/" $parts)"/"
            return
        end
    end
    echo ""
end

# Helper: map feature name to file emoji+label
function __dr_feature_label
    switch $argv[1]
        case scripts
            echo "🚀 Script"
        case aliases
            echo "📝 Alias file"
        case configs
            echo "⚙️  Config"
    end
end

# Complete feature context: folders first (A-Z), then files (A-Z)
# Uses tab-separated output for per-item descriptions
# Args: feature
function __dr_complete_feature
    set -l feature $argv[1]
    set -l context (__dr_extract_context)
    set -l file_label (__dr_feature_label "$feature")

    # Folders first (already sorted by __dr_filesystem_find)
    for folder in (__dr_filesystem_find "$feature" directory single "$context")
        printf '%s\t%s\n' "$context$folder" "📁 Folder"
    end

    # Then files (already sorted by __dr_filesystem_find)
    for file in (__dr_filesystem_find "$feature" file single "$context")
        printf '%s\t%s\n' "$context$file" "$file_label"
    end
end

# Recursive search: folders first (A-Z), then files (A-Z)
# Args: feature
function __dr_complete_recursive
    set -l feature $argv[1]
    set -l token (commandline -ct)

    # Skip if token is empty, starts with dash, or contains /
    if test -z "$token"; or string match -q -- "-*" "$token"; or string match -q -- "*/*" "$token"
        return
    end

    set -l file_label (__dr_feature_label "$feature")

    for item in (__dr_filesystem_find "$feature" directory all "" "$token")
        printf '%s\t%s\n' "$item" "📁 Folder"
    end

    for item in (__dr_filesystem_find "$feature" file all "" "$token")
        printf '%s\t%s\n' "$item" "$file_label"
    end
end

# Complete folders only (for -l/-L list filter)
# Args: feature
function __dr_complete_folders_only
    set -l feature $argv[1]
    set -l context (__dr_extract_context)

    for folder in (__dr_filesystem_find "$feature" directory single "$context")
        printf '%s\t%s\n' "$context$folder" "📁 Folder"
    end
end

# ============================================================================
# CONDITION PREDICATES
# ============================================================================

function __dr_needs_first_arg
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 1
end

function __dr_first_arg_is
    set -l value $argv[1]
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 2; and test "$cmd[2]" = "$value"
end

function __dr_needs_second_arg
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 2
end

function __dr_second_arg_is
    set -l value $argv[1]
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 3; and test "$cmd[3]" = "$value"
end

function __dr_needs_third_arg
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 3
end

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

# Check if token looks like a search pattern (not empty, not flag, not path)
function __dr_is_search_pattern
    set -l token (commandline -ct)
    test -n "$token"; and not string match -q -- "-*" "$token"; and not string match -q -- "*/*" "$token"
end

# ============================================================================
# COMPLETION REGISTRATION
# ============================================================================

# Disable file completion by default
complete -c dr -f

# ============================================================================
# POSITION 1: Root level — folders + scripts (NO namespace flags on empty TAB)
# Mirrors zsh: empty TAB shows only folders and scripts, no commands
# -k preserves our folders-first ordering
# ============================================================================

# Hierarchical navigation (folders first, then scripts)
complete -c dr -k -n __dr_needs_first_arg -a "(__dr_complete_feature scripts)"

# Recursive search when typing a pattern
complete -c dr -k -n "__dr_needs_first_arg; and __dr_is_search_pattern" -a "(__dr_complete_recursive scripts)"

# ============================================================================
# POSITION 2: After namespace flag
# ============================================================================

# Scripts namespace
complete -c dr -k -n "__dr_in_scripts_namespace; and __dr_needs_second_arg" -a "(__dr_complete_feature scripts)"
complete -c dr -k -n "__dr_in_scripts_namespace; and __dr_needs_second_arg; and __dr_is_search_pattern" -a "(__dr_complete_recursive scripts)"

# Aliases namespace
complete -c dr -k -n "__dr_in_aliases_namespace; and __dr_needs_second_arg" -a "(__dr_complete_feature aliases)"
complete -c dr -k -n "__dr_in_aliases_namespace; and __dr_needs_second_arg; and __dr_is_search_pattern" -a "(__dr_complete_recursive aliases)"

# Config namespace
complete -c dr -k -n "__dr_in_config_namespace; and __dr_needs_second_arg" -a "(__dr_complete_feature configs)"
complete -c dr -k -n "__dr_in_config_namespace; and __dr_needs_second_arg; and __dr_is_search_pattern" -a "(__dr_complete_recursive configs)"

# Collections namespace — show subcommands (only namespace that shows commands)
complete -c dr -k -n "__dr_in_collections_namespace; and __dr_needs_second_arg" -a "set" -d "➕ Add a new collection"
complete -c dr -k -n "__dr_in_collections_namespace; and __dr_needs_second_arg" -a "list" -d "📋 List installed collections"
complete -c dr -k -n "__dr_in_collections_namespace; and __dr_needs_second_arg" -a "sync" -d "🔄 Sync installed collections"
complete -c dr -k -n "__dr_in_collections_namespace; and __dr_needs_second_arg" -a "update" -d "⬆️  Update collection by name"
complete -c dr -k -n "__dr_in_collections_namespace; and __dr_needs_second_arg" -a "list:details" -d "📋 List with details"
complete -c dr -k -n "__dr_in_collections_namespace; and __dr_needs_second_arg" -a "remove" -d "🗑️  Remove a collection"

# ============================================================================
# DIRECT COMMANDS: set, edit, help, move, rm, -l, -L (backwards compat)
# ============================================================================

complete -c dr -k -n "__dr_first_arg_is set" -a "(__dr_complete_feature scripts)"
complete -c dr -k -n "__dr_first_arg_is edit" -a "(__dr_complete_feature scripts)"
complete -c dr -k -n "__dr_first_arg_is help" -a "(__dr_complete_feature scripts)"
complete -c dr -k -n "__dr_first_arg_is move" -a "(__dr_complete_feature scripts)"
complete -c dr -k -n "__dr_first_arg_is rm" -a "(__dr_complete_feature scripts)"

# List command folder filter
complete -c dr -k -n "__dr_first_arg_is -l" -a "(__dr_complete_folders_only scripts)"
complete -c dr -k -n "__dr_first_arg_is -L" -a "(__dr_complete_folders_only scripts)"

# ============================================================================
# POSITION 3: After namespace + command
# ============================================================================

# Script namespace operations
complete -c dr -k -n "__dr_in_scripts_namespace; and __dr_second_arg_is set" -a "(__dr_complete_feature scripts)"
complete -c dr -k -n "__dr_in_scripts_namespace; and __dr_second_arg_is move" -a "(__dr_complete_feature scripts)"
complete -c dr -k -n "__dr_in_scripts_namespace; and __dr_second_arg_is rm" -a "(__dr_complete_feature scripts)"
complete -c dr -k -n "__dr_in_scripts_namespace; and __dr_second_arg_is help" -a "(__dr_complete_feature scripts)"
complete -c dr -k -n "__dr_in_scripts_namespace; and __dr_second_arg_is -l" -a "(__dr_complete_folders_only scripts)"
complete -c dr -k -n "__dr_in_scripts_namespace; and __dr_second_arg_is -L" -a "(__dr_complete_folders_only scripts)"

# Aliases namespace operations
complete -c dr -k -n "__dr_in_aliases_namespace; and __dr_second_arg_is move" -a "(__dr_complete_feature aliases)"
complete -c dr -k -n "__dr_in_aliases_namespace; and __dr_second_arg_is rm" -a "(__dr_complete_feature aliases)"
complete -c dr -k -n "__dr_in_aliases_namespace; and __dr_second_arg_is help" -a "(__dr_complete_feature aliases)"
complete -c dr -k -n "__dr_in_aliases_namespace; and __dr_second_arg_is -l" -a "(__dr_complete_folders_only aliases)"
complete -c dr -k -n "__dr_in_aliases_namespace; and __dr_second_arg_is -L" -a "(__dr_complete_folders_only aliases)"

# Config namespace operations
complete -c dr -k -n "__dr_in_config_namespace; and __dr_second_arg_is set" -a "(__dr_complete_feature configs)"
complete -c dr -k -n "__dr_in_config_namespace; and __dr_second_arg_is move" -a "(__dr_complete_feature configs)"
complete -c dr -k -n "__dr_in_config_namespace; and __dr_second_arg_is rm" -a "(__dr_complete_feature configs)"
complete -c dr -k -n "__dr_in_config_namespace; and __dr_second_arg_is help" -a "(__dr_complete_feature configs)"
complete -c dr -k -n "__dr_in_config_namespace; and __dr_second_arg_is -l" -a "(__dr_complete_folders_only configs)"
complete -c dr -k -n "__dr_in_config_namespace; and __dr_second_arg_is -L" -a "(__dr_complete_folders_only configs)"
complete -c dr -k -n "__dr_in_config_namespace; and __dr_second_arg_is list" -a "--categories --category --keys-only" -d "List option"

# ============================================================================
# POSITION 4: Move/rename destinations
# ============================================================================

function __dr_needs_move_dest
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 3; and contains -- "$cmd[2]" move rename mv
end

function __dr_needs_scripts_move_dest
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 4
        if contains -- "$cmd[2]" -s scripts
            contains -- "$cmd[3]" move rename; and return 0
        end
    end
    return 1
end

function __dr_needs_aliases_move_dest
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 4
        if contains -- "$cmd[2]" -a aliases
            contains -- "$cmd[3]" move; and return 0
        end
    end
    return 1
end

function __dr_needs_configs_move_dest
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 4
        if contains -- "$cmd[2]" -c config
            contains -- "$cmd[3]" move; and return 0
        end
    end
    return 1
end

complete -c dr -k -n __dr_needs_move_dest -a "(__dr_complete_feature scripts)"
complete -c dr -k -n __dr_needs_scripts_move_dest -a "(__dr_complete_feature scripts)"
complete -c dr -k -n __dr_needs_aliases_move_dest -a "(__dr_complete_feature aliases)"
complete -c dr -k -n __dr_needs_configs_move_dest -a "(__dr_complete_feature configs)"

# ============================================================================
# CATEGORY COMPLETIONS
# ============================================================================

complete -c dr -n "contains -- --category (commandline -opc)" -n __dr_in_config_namespace -a "(__dr_filesystem_find configs file all | string replace -r '/[^/]*\$' '' | sort -u)" -d "Category"

# ============================================================================
# ENABLE FILE COMPLETION FOR NEW NAMES
# ============================================================================

complete -c dr -n "__dr_first_arg_is set" -F
complete -c dr -n __dr_in_scripts_namespace -n "__dr_second_arg_is set" -F
complete -c dr -n __dr_in_config_namespace -n "__dr_second_arg_is set" -F
complete -c dr -n __dr_needs_move_dest -F
complete -c dr -n __dr_needs_scripts_move_dest -F
complete -c dr -n __dr_needs_aliases_move_dest -F
