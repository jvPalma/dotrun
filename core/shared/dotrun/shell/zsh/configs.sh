#!/usr/bin/env zsh
# DotRun Configuration - Zsh Integration
# This file is auto-generated. Do not edit manually.

# Source user configs from ~/.config/dotrun/configs/
# Supports both flat structure (NN-category.config) and nested (NN-category/NN-name.config)
# Files are loaded in alphabetical order (sorted by full path)
if [[ -d "$HOME/.config/dotrun/configs" ]]; then
  while IFS= read -r config_file; do
    [[ -f "$config_file" ]] && source "$config_file"
  done < <(find "$HOME/.config/dotrun/configs" -name "*.config" -type f 2>/dev/null | sort)
fi
