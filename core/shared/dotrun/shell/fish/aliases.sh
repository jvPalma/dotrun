#!/usr/bin/env fish
# DotRun Aliases - Fish Integration
# This file is auto-generated. Do not edit manually.

# Function to load aliases from a file
function _load_aliases_from_file
    set -l file $argv[1]
    if test -f "$file"
        while read -l line
            # Skip comments and empty lines
            if string match -q "#*" "$line"; or test -z "$line"
                continue
            end
            # Parse alias format: alias name='command'
            if string match -qr "^alias\s+([^=]+)='(.*)'\$" "$line"
                set -l alias_name (string match -r "^alias\s+([^=]+)=" "$line" | string split "=" | head -n 1 | string trim | string sub -s 7)
                set -l alias_cmd (string match -r "'(.*)'\$" "$line" | string sub -s 2 -e -1)
                alias $alias_name="$alias_cmd"
            end
        end <"$file"
    end
end

# Load user aliases from ~/.config/dotrun/aliases/
# Supports both flat structure (NN-category.aliases) and nested (NN-category/NN-name.aliases)
# Files are loaded in alphabetical order (sorted by full path)
if test -d "$HOME/.config/dotrun/aliases"
    for alias_file in (find "$HOME/.config/dotrun/aliases" -name "*.aliases" -type f 2>/dev/null | sort)
        _load_aliases_from_file "$alias_file"
    end
end
