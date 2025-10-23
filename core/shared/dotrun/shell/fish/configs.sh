#!/usr/bin/env fish
# DotRun Configuration - Fish Integration
# This file is auto-generated. Do not edit manually.

# Function to load config from a file
function _load_config_from_file
    set -l file $argv[1]
    if test -f "$file"
        while read -l line
            # Skip comments and empty lines
            if string match -q "#*" "$line"; or test -z "$line"
                continue
            end
            # Parse export format: export KEY=value or export KEY="value"
            if string match -qr "^export\s+([^=]+)=(.*)$" "$line"
                set -l key_value (string match -r "^export\s+([^=]+)=(.*)$" "$line")
                set -l key (echo $key_value[2])
                set -l value (echo $key_value[3])
                # Remove surrounding quotes if present
                set value (string trim -c '"' $value)
                set value (string trim -c "'" $value)
                set -gx $key "$value"
            end
        end < "$file"
    end
end

# Load user configs from ~/.config/dotrun/configs/
# Supports both flat structure (NN-category.config) and nested (NN-category/NN-name.config)
# Files are loaded in alphabetical order (sorted by full path)
if test -d "$HOME/.config/dotrun/configs"
    for config_file in (find "$HOME/.config/dotrun/configs" -name "*.config" -type f 2>/dev/null | sort)
        _load_config_from_file "$config_file"
    end
end
