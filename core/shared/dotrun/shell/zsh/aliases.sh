#!/usr/bin/env zsh

# DotRun Aliases - Zsh Integration
# This file is auto-generated. Do not edit manually.

# Source user aliases from ~/.config/dotrun/aliases/
# Supports both flat structure (NN-category.aliases) and nested (NN-category/NN-name.aliases)
# Files are loaded in alphabetical order (sorted by full path)
if [[ -d "$HOME/.config/dotrun/aliases" ]]; then
  while IFS= read -r alias_file; do
    [[ -f "$alias_file" ]] && source "$alias_file"
  done < <(find "$HOME/.config/dotrun/aliases" -name "*.aliases" -type f 2>/dev/null | sort)
fi
