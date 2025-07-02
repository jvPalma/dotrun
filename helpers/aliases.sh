#!/usr/bin/env bash

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016

# DotRun Aliases Management System
# Provides centralized alias management with shell integration

set -euo pipefail

# Configuration
ALIASES_CONFIG_DIR="$DRUN_CONFIG/aliases"
ALIASES_FILE="$ALIASES_CONFIG_DIR/.aliases"
ALIASES_CATEGORIES_DIR="$ALIASES_CONFIG_DIR/.aliases.d"
SHELL_INTEGRATION_DIR="$ALIASES_CONFIG_DIR/shell"

# Shell integration files
BASH_INTEGRATION="$SHELL_INTEGRATION_DIR/bash_aliases"
ZSH_INTEGRATION="$SHELL_INTEGRATION_DIR/zsh_aliases"
FISH_INTEGRATION="$SHELL_INTEGRATION_DIR/fish_aliases"

# Validation functions
validate_alias_name() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Error: Alias name cannot be empty" >&2
    return 1
  fi
  if [[ "$name" =~ [[:space:]] ]]; then
    echo "Error: Alias name cannot contain spaces" >&2
    return 1
  fi
  if [[ "$name" =~ ^[0-9] ]]; then
    echo "Error: Alias name cannot start with a number" >&2
    return 1
  fi
  if [[ "$name" =~ [^a-zA-Z0-9_-] ]]; then
    echo "Error: Alias name contains invalid characters. Use only alphanumeric, underscore, and dash." >&2
    return 1
  fi
  # Check for reserved shell keywords
  local reserved_words=("if" "then" "else" "elif" "fi" "case" "esac" "for" "while" "until" "do" "done" "function" "select" "time" "coproc")
  for word in "${reserved_words[@]}"; do
    if [[ "$name" == "$word" ]]; then
      echo "Error: '$name' is a reserved shell keyword and cannot be used as an alias" >&2
      return 1
    fi
  done
}

validate_alias_command() {
  local command="$1"
  if [[ -z "$command" ]]; then
    echo "Error: Alias command cannot be empty" >&2
    return 1
  fi
}

validate_category() {
  local category="$1"
  if [[ -n "$category" ]] && [[ "$category" =~ [^a-zA-Z0-9_-] ]]; then
    echo "Error: Category name contains invalid characters. Use only alphanumeric, underscore, and dash." >&2
    return 1
  fi
}

# Initialize aliases system
aliases_init() {
  echo "Initializing DotRun aliases system..."
  
  # Create directories
  mkdir -p "$ALIASES_CONFIG_DIR"
  mkdir -p "$ALIASES_CATEGORIES_DIR"
  mkdir -p "$SHELL_INTEGRATION_DIR"
  
  # Create main aliases file if it doesn't exist
  if [[ ! -f "$ALIASES_FILE" ]]; then
    cat > "$ALIASES_FILE" << 'EOF'
# DotRun Aliases
# This file is managed by DotRun. Manual edits may be overwritten.
# Use 'drun aliases add/edit/remove' commands to manage aliases.

# Generated aliases will appear below this line
EOF
    echo "✓ Created main aliases file: $ALIASES_FILE"
  else
    echo "✓ Main aliases file already exists: $ALIASES_FILE"
  fi
  
  # Create shell integration files
  create_shell_integration_files
  
  # Create default categories
  create_default_categories
  
  echo "✓ Aliases system initialized successfully!"
  echo ""
  echo "To enable aliases in your current shell, run:"
  echo "  source $BASH_INTEGRATION    # For Bash"
  echo "  source $ZSH_INTEGRATION     # For Zsh"
  echo "  source $FISH_INTEGRATION    # For Fish"
  echo ""
  echo "To automatically load aliases in new shells, add one of these lines to your shell's RC file:"
  echo "  echo 'source $BASH_INTEGRATION' >> ~/.bashrc"
  echo "  echo 'source $ZSH_INTEGRATION' >> ~/.zshrc"
  echo "  echo 'source $FISH_INTEGRATION' >> ~/.config/fish/config.fish"
}

create_shell_integration_files() {
  # Bash integration
  cat > "$BASH_INTEGRATION" << EOF
#!/usr/bin/env bash
# DotRun Aliases - Bash Integration
# This file is auto-generated. Do not edit manually.

# Source main aliases file
if [[ -f "$ALIASES_FILE" ]]; then
  source "$ALIASES_FILE"
fi

# Source category-specific aliases
if [[ -d "$ALIASES_CATEGORIES_DIR" ]]; then
  for category_file in "$ALIASES_CATEGORIES_DIR"/*.aliases; do
    [[ -f "\$category_file" ]] && source "\$category_file"
  done
fi
EOF
  
  # Zsh integration (similar to bash)
  cat > "$ZSH_INTEGRATION" << EOF
#!/usr/bin/env zsh
# DotRun Aliases - Zsh Integration
# This file is auto-generated. Do not edit manually.

# Source main aliases file
if [[ -f "$ALIASES_FILE" ]]; then
  source "$ALIASES_FILE"
fi

# Source category-specific aliases
if [[ -d "$ALIASES_CATEGORIES_DIR" ]]; then
  for category_file in "$ALIASES_CATEGORIES_DIR"/*.aliases; do
    [[ -f "\$category_file" ]] && source "\$category_file"
  done
fi
EOF
  
  # Fish integration
  cat > "$FISH_INTEGRATION" << EOF
#!/usr/bin/env fish
# DotRun Aliases - Fish Integration
# This file is auto-generated. Do not edit manually.

# Function to load aliases from a file
function _load_aliases_from_file
    set -l file \$argv[1]
    if test -f "\$file"
        while read -l line
            # Skip comments and empty lines
            if string match -q "#*" "\$line"; or test -z "\$line"
                continue
            end
            # Parse alias format: alias name='command'
            if string match -qr "^alias\s+([^=]+)='(.*)'\$" "\$line"
                set -l alias_name (string match -r "^alias\s+([^=]+)=" "\$line" | string split "=" | head -n 1 | string trim | string sub -s 7)
                set -l alias_cmd (string match -r "'(.*)'\$" "\$line" | string sub -s 2 -e -1)
                alias \$alias_name="\$alias_cmd"
            end
        end < "\$file"
    end
end

# Load main aliases file
_load_aliases_from_file "$ALIASES_FILE"

# Load category-specific aliases
if test -d "$ALIASES_CATEGORIES_DIR"
    for category_file in "$ALIASES_CATEGORIES_DIR"/*.aliases
        _load_aliases_from_file "\$category_file"
    end
end
EOF
  
  echo "✓ Created shell integration files"
}

create_default_categories() {
  # Create some default category files
  local categories=("git" "docker" "system" "development")
  
  # Ensure the categories directory exists
  mkdir -p "$ALIASES_CATEGORIES_DIR"
  
  for category in "${categories[@]}"; do
    local category_file="$ALIASES_CATEGORIES_DIR/$category.aliases"
    if [[ ! -f "$category_file" ]]; then
      cat > "$category_file" << EOF
# DotRun Aliases - $category Category
# This file is managed by DotRun. Manual edits may be overwritten.
# Use 'drun aliases add <name> <command> --category $category' to add aliases to this category.

EOF
      echo "✓ Created category file: $category.aliases"
    fi
  done
}

# Add a new alias
aliases_add() {
  local name="$1"
  local command="$2"
  local category="${3:-}"
  
  validate_alias_name "$name" || return 1
  validate_alias_command "$command" || return 1
  validate_category "$category" || return 1
  
  # Check if alias already exists
  if alias_exists "$name"; then
    echo "Error: Alias '$name' already exists. Use 'drun aliases edit $name' to modify it." >&2
    return 1
  fi
  
  # Determine target file
  local target_file="$ALIASES_FILE"
  if [[ -n "$category" ]]; then
    target_file="$ALIASES_CATEGORIES_DIR/$category.aliases"
    # Create category file if it doesn't exist
    if [[ ! -f "$target_file" ]]; then
      cat > "$target_file" << EOF
# DotRun Aliases - $category Category
# This file is managed by DotRun. Manual edits may be overwritten.
# Use 'drun aliases add <name> <command> --category $category' to add aliases to this category.

EOF
    fi
  fi
  
  # Add the alias - escape single quotes in command
  local escaped_command="${command//\'/\'\"\'\"\'}"
  echo "alias $name='$escaped_command'" >> "$target_file"
  
  local category_text=""
  [[ -n "$category" ]] && category_text=" (category: $category)"
  echo "✓ Added alias: $name='$command'$category_text"
  echo "Run 'drun aliases reload' or restart your shell to use the new alias"
}

# Parse alias line to extract name and command
parse_alias_line() {
  local line="$1"
  local alias_name alias_command
  
  # Extract name: everything between 'alias ' and '='
  alias_name=$(echo "$line" | cut -d'=' -f1 | cut -d' ' -f2)
  
  # Extract command: everything between first and last single quote
  alias_command=$(echo "$line" | cut -d"'" -f2)
  
  echo "$alias_name:$alias_command"
}

# List all aliases
aliases_list() {
  local show_categories="${1:-false}"
  local filter_category="${2:-}"
  
  echo "DotRun Aliases:"
  echo "==============="
  
  local found_aliases=false
  
  # List aliases from main file
  if [[ -f "$ALIASES_FILE" ]]; then
    local main_aliases
    main_aliases=$(grep -E "^alias " "$ALIASES_FILE" 2>/dev/null | wc -l)
    if [[ "$main_aliases" -gt 0 ]]; then
      found_aliases=true
      if [[ -z "$filter_category" ]]; then
        echo ""
        echo "Main aliases:"
        while IFS= read -r line; do
          local parsed
          parsed=$(parse_alias_line "$line")
          local alias_name alias_command
          alias_name=$(echo "$parsed" | cut -d':' -f1)
          alias_command=$(echo "$parsed" | cut -d':' -f2-)
          echo "  $alias_name -> $alias_command"
        done < <(grep -E "^alias " "$ALIASES_FILE" 2>/dev/null)
      fi
    fi
  fi
  
  # List aliases from category files
  if [[ -d "$ALIASES_CATEGORIES_DIR" ]]; then
    for category_file in "$ALIASES_CATEGORIES_DIR"/*.aliases; do
      [[ ! -f "$category_file" ]] && continue
      
      local category_name
      category_name=$(basename "$category_file" .aliases)
      
      # Skip if filtering by category and this isn't the one
      if [[ -n "$filter_category" ]] && [[ "$category_name" != "$filter_category" ]]; then
        continue
      fi
      
      local category_aliases
      category_aliases=$(grep -E "^alias " "$category_file" 2>/dev/null | wc -l)
      if [[ "$category_aliases" -gt 0 ]]; then
        found_aliases=true
        echo ""
        echo "$category_name aliases:"
        while IFS= read -r line; do
          local parsed
          parsed=$(parse_alias_line "$line")
          local alias_name alias_command
          alias_name=$(echo "$parsed" | cut -d':' -f1)
          alias_command=$(echo "$parsed" | cut -d':' -f2-)
          echo "  $alias_name -> $alias_command"
        done < <(grep -E "^alias " "$category_file" 2>/dev/null)
      fi
    done
  fi
  
  if [[ "$found_aliases" == "false" ]]; then
    echo ""
    echo "No aliases found. Use 'drun aliases add <name> <command>' to create your first alias."
  fi
  
  # Show categories if requested
  if [[ "$show_categories" == "true" ]]; then
    echo ""
    echo "Available categories:"
    if [[ -d "$ALIASES_CATEGORIES_DIR" ]]; then
      for category_file in "$ALIASES_CATEGORIES_DIR"/*.aliases; do
        [[ ! -f "$category_file" ]] && continue
        local category_name
        category_name=$(basename "$category_file" .aliases)
        local count
        count=$(grep -E "^alias " "$category_file" 2>/dev/null | wc -l)
        echo "  $category_name ($count aliases)"
      done
    else
      echo "  No categories found."
    fi
  fi
}

# Check if an alias exists
alias_exists() {
  local name="$1"
  
  # Check main aliases file
  if [[ -f "$ALIASES_FILE" ]] && grep -q "^alias $name=" "$ALIASES_FILE" 2>/dev/null; then
    return 0
  fi
  
  # Check category files
  if [[ -d "$ALIASES_CATEGORIES_DIR" ]]; then
    for category_file in "$ALIASES_CATEGORIES_DIR"/*.aliases; do
      [[ ! -f "$category_file" ]] && continue
      if grep -q "^alias $name=" "$category_file" 2>/dev/null; then
        return 0
      fi
    done
  fi
  
  return 1
}

# Find which file contains an alias
find_alias_file() {
  local name="$1"
  
  # Check main aliases file
  if [[ -f "$ALIASES_FILE" ]] && grep -q "^alias $name=" "$ALIASES_FILE" 2>/dev/null; then
    echo "$ALIASES_FILE"
    return 0
  fi
  
  # Check category files
  if [[ -d "$ALIASES_CATEGORIES_DIR" ]]; then
    for category_file in "$ALIASES_CATEGORIES_DIR"/*.aliases; do
      [[ ! -f "$category_file" ]] && continue
      if grep -q "^alias $name=" "$category_file" 2>/dev/null; then
        echo "$category_file"
        return 0
      fi
    done
  fi
  
  return 1
}

# Edit an existing alias
aliases_edit() {
  local name="$1"
  
  validate_alias_name "$name" || return 1
  
  if ! alias_exists "$name"; then
    echo "Error: Alias '$name' not found" >&2
    echo "Use 'drun aliases list' to see available aliases" >&2
    return 1
  fi
  
  local alias_file
  alias_file=$(find_alias_file "$name")
  
  # Get current command
  local current_command
  current_command=$(grep "^alias $name=" "$alias_file" | cut -d"'" -f2)
  
  echo "Current alias: $name='$current_command'"
  echo -n "Enter new command (or press Enter to keep current): "
  read -r new_command
  
  # If no input, keep current command
  if [[ -z "$new_command" ]]; then
    echo "No changes made to alias '$name'"
    return 0
  fi
  
  validate_alias_command "$new_command" || return 1
  
  # Update the alias
  if command -v sed >/dev/null 2>&1; then
    # Use temporary file for atomic update
    local temp_file
    temp_file=$(mktemp)
    sed "s|^alias $name=.*|alias $name='$new_command'|" "$alias_file" > "$temp_file"
    mv "$temp_file" "$alias_file"
  else
    echo "Error: sed command not found" >&2
    return 1
  fi
  
  echo "✓ Updated alias: $name='$new_command'"
  echo "Run 'drun aliases reload' or restart your shell to use the updated alias"
}

# Remove an alias
aliases_remove() {
  local name="$1"
  
  validate_alias_name "$name" || return 1
  
  if ! alias_exists "$name"; then
    echo "Error: Alias '$name' not found" >&2
    echo "Use 'drun aliases list' to see available aliases" >&2
    return 1
  fi
  
  local alias_file
  alias_file=$(find_alias_file "$name")
  
  # Get current command for confirmation
  local current_command
  current_command=$(grep "^alias $name=" "$alias_file" | cut -d"'" -f2)
  
  echo "Are you sure you want to remove this alias?"
  echo "  $name='$current_command'"
  echo -n "Type 'yes' to confirm: "
  read -r confirmation
  
  if [[ "$confirmation" != "yes" ]]; then
    echo "Alias removal cancelled"
    return 0
  fi
  
  # Remove the alias
  if command -v sed >/dev/null 2>&1; then
    # Use temporary file for atomic update
    local temp_file
    temp_file=$(mktemp)
    grep -v "^alias $name=" "$alias_file" > "$temp_file"
    mv "$temp_file" "$alias_file"
  else
    echo "Error: sed command not found" >&2
    return 1
  fi
  
  echo "✓ Removed alias: $name"
}

# Reload aliases in current shell
aliases_reload() {
  echo "Reloading DotRun aliases..."
  
  # Detect current shell
  local current_shell
  current_shell=$(basename "$SHELL")
  
  case "$current_shell" in
    bash)
      if [[ -f "$BASH_INTEGRATION" ]]; then
        # shellcheck disable=SC1090
        source "$BASH_INTEGRATION"
        echo "✓ Reloaded aliases for Bash"
      else
        echo "Error: Bash integration file not found. Run 'drun aliases init' first." >&2
        return 1
      fi
      ;;
    zsh)
      if [[ -f "$ZSH_INTEGRATION" ]]; then
        # shellcheck disable=SC1090
        source "$ZSH_INTEGRATION"
        echo "✓ Reloaded aliases for Zsh"
      else
        echo "Error: Zsh integration file not found. Run 'drun aliases init' first." >&2
        return 1
      fi
      ;;
    fish)
      if [[ -f "$FISH_INTEGRATION" ]]; then
        echo "Note: Fish shell detected. Please run the following command manually:"
        echo "  source $FISH_INTEGRATION"
      else
        echo "Error: Fish integration file not found. Run 'drun aliases init' first." >&2
        return 1
      fi
      ;;
    *)
      echo "Warning: Unknown shell '$current_shell'. Attempting to source Bash integration..." >&2
      if [[ -f "$BASH_INTEGRATION" ]]; then
        # shellcheck disable=SC1090
        source "$BASH_INTEGRATION"
        echo "✓ Sourced Bash integration (may not work in all shells)"
      else
        echo "Error: Integration files not found. Run 'drun aliases init' first." >&2
        return 1
      fi
      ;;
  esac
}