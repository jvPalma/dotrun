#!/usr/bin/env bash

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016

# DotRun Configuration Management System
# Provides centralized global variable/config management with shell integration

set -euo pipefail

# Configuration directories
CONFIG_DIR="$DRUN_CONFIG/config"
CONFIG_FILE="$CONFIG_DIR/.dotrun_config"
CONFIG_CATEGORIES_DIR="$CONFIG_DIR/.dotrun_config.d"
SHELL_INTEGRATION_DIR="$CONFIG_DIR/shell"
SECURE_CONFIG_DIR="$CONFIG_DIR/.secure"

# Shell integration files
BASH_CONFIG_INTEGRATION="$SHELL_INTEGRATION_DIR/bash_config"
ZSH_CONFIG_INTEGRATION="$SHELL_INTEGRATION_DIR/zsh_config"
FISH_CONFIG_INTEGRATION="$SHELL_INTEGRATION_DIR/fish_config"

# Security settings
SECURE_KEYS_FILE="$CONFIG_DIR/.secure_keys"

# Validation functions
validate_config_key() {
  local key="$1"
  if [[ -z "$key" ]]; then
    echo "Error: Config key cannot be empty" >&2
    return 1
  fi
  if [[ "$key" =~ [[:space:]] ]]; then
    echo "Error: Config key cannot contain spaces" >&2
    return 1
  fi
  if [[ "$key" =~ ^[0-9] ]]; then
    echo "Error: Config key cannot start with a number" >&2
    return 1
  fi
  if [[ "$key" =~ [^a-zA-Z0-9_] ]]; then
    echo "Error: Config key contains invalid characters. Use only alphanumeric and underscore." >&2
    return 1
  fi
  # Check for reserved environment variables
  local reserved_vars=("PATH" "HOME" "USER" "SHELL" "PWD" "OLDPWD" "PS1" "PS2" "IFS" "BASH_VERSION" "ZSH_VERSION")
  for var in "${reserved_vars[@]}"; do
    if [[ "$key" == "$var" ]]; then
      echo "Error: '$key' is a reserved environment variable and cannot be used as a config key" >&2
      return 1
    fi
  done
}

validate_config_value() {
  local value="$1"
  # Allow empty values but warn
  if [[ -z "$value" ]]; then
    echo "Warning: Config value is empty" >&2
  fi
}

validate_category() {
  local category="$1"
  if [[ -n "$category" ]] && [[ "$category" =~ [^a-zA-Z0-9_-] ]]; then
    echo "Error: Category name contains invalid characters. Use only alphanumeric, underscore, and dash." >&2
    return 1
  fi
}

# Security functions
is_sensitive_key() {
  local key="$1"
  local sensitive_patterns=("API" "KEY" "SECRET" "TOKEN" "PASSWORD" "PASS" "AUTH" "PRIVATE" "CREDENTIAL")
  
  for pattern in "${sensitive_patterns[@]}"; do
    if [[ "$key" =~ $pattern ]]; then
      return 0
    fi
  done
  return 1
}

mark_key_as_sensitive() {
  local key="$1"
  if [[ ! -f "$SECURE_KEYS_FILE" ]]; then
    touch "$SECURE_KEYS_FILE"
    chmod 600 "$SECURE_KEYS_FILE"
  fi
  
  if ! grep -q "^$key$" "$SECURE_KEYS_FILE" 2>/dev/null; then
    echo "$key" >> "$SECURE_KEYS_FILE"
  fi
}

is_key_marked_sensitive() {
  local key="$1"
  [[ -f "$SECURE_KEYS_FILE" ]] && grep -q "^$key$" "$SECURE_KEYS_FILE" 2>/dev/null
}

mask_sensitive_value() {
  local value="$1"
  local length=${#value}
  if [[ $length -le 4 ]]; then
    echo "****"
  else
    local visible=$((length / 4))
    local masked=$((length - visible))
    printf "%s%s" "${value:0:$visible}" "$(printf '%*s' $masked | tr ' ' '*')"
  fi
}

# Initialize config system
config_init() {
  echo "Initializing DotRun configuration system..."
  
  # Create directories
  mkdir -p "$CONFIG_DIR"
  mkdir -p "$CONFIG_CATEGORIES_DIR"
  mkdir -p "$SHELL_INTEGRATION_DIR"
  mkdir -p "$SECURE_CONFIG_DIR"
  
  # Set secure permissions on secure directory
  chmod 700 "$SECURE_CONFIG_DIR"
  
  # Create main config file if it doesn't exist
  if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" << 'EOF'
# DotRun Global Configuration
# This file is managed by DotRun. Manual edits may be overwritten.
# Use 'drun config set/unset' commands to manage configuration.

# Generated configuration will appear below this line
EOF
    echo "✓ Created main config file: $CONFIG_FILE"
  else
    echo "✓ Main config file already exists: $CONFIG_FILE"
  fi
  
  # Create shell integration files
  create_shell_integration_files
  
  # Create default categories
  create_default_categories
  
  echo "✓ Configuration system initialized successfully!"
  echo ""
  echo "To enable config variables in your current shell, run:"
  echo "  source $BASH_CONFIG_INTEGRATION    # For Bash"
  echo "  source $ZSH_CONFIG_INTEGRATION     # For Zsh"
  echo "  source $FISH_CONFIG_INTEGRATION    # For Fish"
  echo ""
  echo "To automatically load config in new shells, add one of these lines to your shell's RC file:"
  echo "  echo 'source $BASH_CONFIG_INTEGRATION' >> ~/.bashrc"
  echo "  echo 'source $ZSH_CONFIG_INTEGRATION' >> ~/.zshrc"
  echo "  echo 'source $FISH_CONFIG_INTEGRATION' >> ~/.config/fish/config.fish"
}

create_shell_integration_files() {
  # Bash integration
  cat > "$BASH_CONFIG_INTEGRATION" << EOF
#!/usr/bin/env bash
# DotRun Configuration - Bash Integration
# This file is auto-generated. Do not edit manually.

# Source main config file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

# Source category-specific config files
if [[ -d "$CONFIG_CATEGORIES_DIR" ]]; then
  for config_file in "$CONFIG_CATEGORIES_DIR"/*.config; do
    [[ -f "\$config_file" ]] && source "\$config_file"
  done
fi
EOF
  
  # Zsh integration (similar to bash)
  cat > "$ZSH_CONFIG_INTEGRATION" << EOF
#!/usr/bin/env zsh
# DotRun Configuration - Zsh Integration
# This file is auto-generated. Do not edit manually.

# Source main config file
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

# Source category-specific config files
if [[ -d "$CONFIG_CATEGORIES_DIR" ]]; then
  for config_file in "$CONFIG_CATEGORIES_DIR"/*.config; do
    [[ -f "\$config_file" ]] && source "\$config_file"
  done
fi
EOF
  
  # Fish integration
  cat > "$FISH_CONFIG_INTEGRATION" << EOF
#!/usr/bin/env fish
# DotRun Configuration - Fish Integration
# This file is auto-generated. Do not edit manually.

# Function to load config from a file
function _load_config_from_file
    set -l file \$argv[1]
    if test -f "\$file"
        while read -l line
            # Skip comments and empty lines
            if string match -q "#*" "\$line"; or test -z "\$line"
                continue
            end
            # Parse export format: export KEY=value or export KEY="value"
            if string match -qr "^export\s+([^=]+)=(.*)$" "\$line"
                set -l key_value (string match -r "^export\s+([^=]+)=(.*)$" "\$line")
                set -l key (echo \$key_value[2])
                set -l value (echo \$key_value[3])
                # Remove surrounding quotes if present
                set value (string trim -c '"' \$value)
                set value (string trim -c "'" \$value)
                set -gx \$key "\$value"
            end
        end < "\$file"
    end
end

# Load main config file
_load_config_from_file "$CONFIG_FILE"

# Load category-specific config files
if test -d "$CONFIG_CATEGORIES_DIR"
    for config_file in "$CONFIG_CATEGORIES_DIR"/*.config
        _load_config_from_file "\$config_file"
    end
end
EOF
  
  echo "✓ Created shell integration files"
}

create_default_categories() {
  # Create some default category files
  local categories=("api" "dev" "personal" "project" "system")
  
  # Ensure the categories directory exists
  mkdir -p "$CONFIG_CATEGORIES_DIR"
  
  for category in "${categories[@]}"; do
    local category_file="$CONFIG_CATEGORIES_DIR/$category.config"
    if [[ ! -f "$category_file" ]]; then
      cat > "$category_file" << EOF
# DotRun Configuration - $category Category
# This file is managed by DotRun. Manual edits may be overwritten.
# Use 'drun config set <key> <value> --category $category' to add config to this category.

EOF
      echo "✓ Created category file: $category.config"
    fi
  done
}

# Set a configuration value
config_set() {
  local key="$1"
  local value="$2"
  local category="${3:-}"
  local secure="${4:-false}"
  
  validate_config_key "$key" || return 1
  validate_config_value "$value" || return 1
  validate_category "$category" || return 1
  
  # Auto-detect sensitive keys
  if [[ "$secure" == "false" ]] && is_sensitive_key "$key"; then
    echo "⚠ Key '$key' appears to contain sensitive information"
    echo -n "Mark as secure? (y/N): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      secure="true"
    fi
  fi
  
  # Mark key as sensitive if requested
  if [[ "$secure" == "true" ]]; then
    mark_key_as_sensitive "$key"
  fi
  
  # Check if key already exists
  if config_key_exists "$key"; then
    local existing_file
    existing_file=$(find_config_file "$key")
    local current_value
    current_value=$(get_config_value_from_file "$key" "$existing_file")
    
    if is_key_marked_sensitive "$key"; then
      echo "Key '$key' already exists with masked value: $(mask_sensitive_value "$current_value")"
    else
      echo "Key '$key' already exists with value: $current_value"
    fi
    echo -n "Overwrite? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo "Configuration update cancelled"
      return 0
    fi
    
    # Remove existing key
    remove_config_key_from_file "$key" "$existing_file"
  fi
  
  # Determine target file
  local target_file="$CONFIG_FILE"
  if [[ -n "$category" ]]; then
    target_file="$CONFIG_CATEGORIES_DIR/$category.config"
    # Create category file if it doesn't exist
    if [[ ! -f "$target_file" ]]; then
      cat > "$target_file" << EOF
# DotRun Configuration - $category Category
# This file is managed by DotRun. Manual edits may be overwritten.
# Use 'drun config set <key> <value> --category $category' to add config to this category.

EOF
    fi
  fi
  
  # Escape value for shell safety
  local escaped_value
  if [[ "$value" =~ [[:space:]\'\"\\$] ]]; then
    escaped_value="\"$(printf '%s\n' "$value" | sed 's/[\\"$]/\\&/g')\""
  else
    escaped_value="$value"
  fi
  
  # Add the config
  echo "export $key=$escaped_value" >> "$target_file"
  
  local category_text=""
  [[ -n "$category" ]] && category_text=" (category: $category)"
  local secure_text=""
  [[ "$secure" == "true" ]] && secure_text=" [SECURE]"
  
  if is_key_marked_sensitive "$key"; then
    echo "✓ Set config: $key=$(mask_sensitive_value "$value")$category_text$secure_text"
  else
    echo "✓ Set config: $key=$value$category_text$secure_text"
  fi
  echo "Run 'drun config reload' or restart your shell to use the new config"
}

# Get a configuration value
config_get() {
  local key="$1"
  local show_masked="${2:-false}"
  
  validate_config_key "$key" || return 1
  
  if ! config_key_exists "$key"; then
    echo "Error: Config key '$key' not found" >&2
    echo "Use 'drun config list' to see available keys" >&2
    return 1
  fi
  
  local config_file
  config_file=$(find_config_file "$key")
  local value
  value=$(get_config_value_from_file "$key" "$config_file")
  
  if [[ "$show_masked" == "false" ]] && is_key_marked_sensitive "$key"; then
    echo "$(mask_sensitive_value "$value")"
  else
    echo "$value"
  fi
}

# List all configuration keys and values
config_list() {
  local show_categories="${1:-false}"
  local filter_category="${2:-}"
  local show_values="${3:-true}"
  
  echo "DotRun Configuration:"
  echo "====================="
  
  local found_config=false
  
  # List config from main file
  if [[ -f "$CONFIG_FILE" ]]; then
    local main_config
    main_config=$(grep -E "^export " "$CONFIG_FILE" 2>/dev/null | wc -l)
    if [[ "$main_config" -gt 0 ]]; then
      found_config=true
      if [[ -z "$filter_category" ]]; then
        echo ""
        echo "Main configuration:"
        while IFS= read -r line; do
          local key value
          key=$(echo "$line" | cut -d'=' -f1 | cut -d' ' -f2)
          value=$(echo "$line" | cut -d'=' -f2-)
          # Remove surrounding quotes
          value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
          
          if [[ "$show_values" == "true" ]]; then
            if is_key_marked_sensitive "$key"; then
              echo "  $key = $(mask_sensitive_value "$value") [SECURE]"
            else
              echo "  $key = $value"
            fi
          else
            local secure_marker=""
            is_key_marked_sensitive "$key" && secure_marker=" [SECURE]"
            echo "  $key$secure_marker"
          fi
        done < <(grep -E "^export " "$CONFIG_FILE" 2>/dev/null)
      fi
    fi
  fi
  
  # List config from category files
  if [[ -d "$CONFIG_CATEGORIES_DIR" ]]; then
    for config_file in "$CONFIG_CATEGORIES_DIR"/*.config; do
      [[ ! -f "$config_file" ]] && continue
      
      local category_name
      category_name=$(basename "$config_file" .config)
      
      # Skip if filtering by category and this isn't the one
      if [[ -n "$filter_category" ]] && [[ "$category_name" != "$filter_category" ]]; then
        continue
      fi
      
      local category_config
      category_config=$(grep -E "^export " "$config_file" 2>/dev/null | wc -l)
      if [[ "$category_config" -gt 0 ]]; then
        found_config=true
        echo ""
        echo "$category_name configuration:"
        while IFS= read -r line; do
          local key value
          key=$(echo "$line" | cut -d'=' -f1 | cut -d' ' -f2)
          value=$(echo "$line" | cut -d'=' -f2-)
          # Remove surrounding quotes
          value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
          
          if [[ "$show_values" == "true" ]]; then
            if is_key_marked_sensitive "$key"; then
              echo "  $key = $(mask_sensitive_value "$value") [SECURE]"
            else
              echo "  $key = $value"
            fi
          else
            local secure_marker=""
            is_key_marked_sensitive "$key" && secure_marker=" [SECURE]"
            echo "  $key$secure_marker"
          fi
        done < <(grep -E "^export " "$config_file" 2>/dev/null)
      fi
    done
  fi
  
  if [[ "$found_config" == "false" ]]; then
    echo ""
    echo "No configuration found. Use 'drun config set <key> <value>' to create your first config."
  fi
  
  # Show categories if requested
  if [[ "$show_categories" == "true" ]]; then
    echo ""
    echo "Available categories:"
    if [[ -d "$CONFIG_CATEGORIES_DIR" ]]; then
      for config_file in "$CONFIG_CATEGORIES_DIR"/*.config; do
        [[ ! -f "$config_file" ]] && continue
        local category_name
        category_name=$(basename "$config_file" .config)
        local count
        count=$(grep -E "^export " "$config_file" 2>/dev/null | wc -l)
        echo "  $category_name ($count variables)"
      done
    else
      echo "  No categories found."
    fi
  fi
}

# Edit a configuration value
config_edit() {
  local key="$1"
  
  validate_config_key "$key" || return 1
  
  if ! config_key_exists "$key"; then
    echo "Error: Config key '$key' not found" >&2
    echo "Use 'drun config list' to see available keys" >&2
    return 1
  fi
  
  local config_file
  config_file=$(find_config_file "$key")
  local current_value
  current_value=$(get_config_value_from_file "$key" "$config_file")
  
  if is_key_marked_sensitive "$key"; then
    echo "Current value: $(mask_sensitive_value "$current_value") [SECURE]"
    echo "Note: This is a secure key. Value will be masked in displays."
  else
    echo "Current value: $current_value"
  fi
  
  echo -n "Enter new value (or press Enter to keep current): "
  read -r new_value
  
  # If no input, keep current value
  if [[ -z "$new_value" ]]; then
    echo "No changes made to config '$key'"
    return 0
  fi
  
  validate_config_value "$new_value" || return 1
  
  # Determine category from file location
  local category=""
  if [[ "$config_file" != "$CONFIG_FILE" ]]; then
    category=$(basename "$config_file" .config)
  fi
  
  # Remove old value and set new one
  remove_config_key_from_file "$key" "$config_file"
  config_set "$key" "$new_value" "$category" "false"
}

# Remove a configuration key
config_unset() {
  local key="$1"
  
  validate_config_key "$key" || return 1
  
  if ! config_key_exists "$key"; then
    echo "Error: Config key '$key' not found" >&2
    echo "Use 'drun config list' to see available keys" >&2
    return 1
  fi
  
  local config_file
  config_file=$(find_config_file "$key")
  local current_value
  current_value=$(get_config_value_from_file "$key" "$config_file")
  
  echo "Are you sure you want to remove this configuration?"
  if is_key_marked_sensitive "$key"; then
    echo "  $key = $(mask_sensitive_value "$current_value") [SECURE]"
  else
    echo "  $key = $current_value"
  fi
  echo -n "Type 'yes' to confirm: "
  read -r confirmation
  
  if [[ "$confirmation" != "yes" ]]; then
    echo "Config removal cancelled"
    return 0
  fi
  
  # Remove the config
  remove_config_key_from_file "$key" "$config_file"
  
  # Remove from secure keys if it was marked
  if [[ -f "$SECURE_KEYS_FILE" ]]; then
    if command -v sed >/dev/null 2>&1; then
      local temp_file
      temp_file=$(mktemp)
      grep -v "^$key$" "$SECURE_KEYS_FILE" > "$temp_file" 2>/dev/null || true
      mv "$temp_file" "$SECURE_KEYS_FILE"
    fi
  fi
  
  echo "✓ Removed config: $key"
}

# Reload configuration in current shell
config_reload() {
  echo "Reloading DotRun configuration..."
  
  # Detect current shell
  local current_shell
  current_shell=$(basename "$SHELL")
  
  case "$current_shell" in
    bash)
      if [[ -f "$BASH_CONFIG_INTEGRATION" ]]; then
        # shellcheck disable=SC1090
        source "$BASH_CONFIG_INTEGRATION"
        echo "✓ Reloaded configuration for Bash"
      else
        echo "Error: Bash integration file not found. Run 'drun config init' first." >&2
        return 1
      fi
      ;;
    zsh)
      if [[ -f "$ZSH_CONFIG_INTEGRATION" ]]; then
        # shellcheck disable=SC1090
        source "$ZSH_CONFIG_INTEGRATION"
        echo "✓ Reloaded configuration for Zsh"
      else
        echo "Error: Zsh integration file not found. Run 'drun config init' first." >&2
        return 1
      fi
      ;;
    fish)
      if [[ -f "$FISH_CONFIG_INTEGRATION" ]]; then
        echo "Note: Fish shell detected. Please run the following command manually:"
        echo "  source $FISH_CONFIG_INTEGRATION"
      else
        echo "Error: Fish integration file not found. Run 'drun config init' first." >&2
        return 1
      fi
      ;;
    *)
      echo "Warning: Unknown shell '$current_shell'. Attempting to source Bash integration..." >&2
      if [[ -f "$BASH_CONFIG_INTEGRATION" ]]; then
        # shellcheck disable=SC1090
        source "$BASH_CONFIG_INTEGRATION"
        echo "✓ Sourced Bash integration (may not work in all shells)"
      else
        echo "Error: Integration files not found. Run 'drun config init' first." >&2
        return 1
      fi
      ;;
  esac
}

# Helper functions
config_key_exists() {
  local key="$1"
  
  # Check main config file
  if [[ -f "$CONFIG_FILE" ]] && grep -q "^export $key=" "$CONFIG_FILE" 2>/dev/null; then
    return 0
  fi
  
  # Check category files
  if [[ -d "$CONFIG_CATEGORIES_DIR" ]]; then
    for config_file in "$CONFIG_CATEGORIES_DIR"/*.config; do
      [[ ! -f "$config_file" ]] && continue
      if grep -q "^export $key=" "$config_file" 2>/dev/null; then
        return 0
      fi
    done
  fi
  
  return 1
}

find_config_file() {
  local key="$1"
  
  # Check main config file
  if [[ -f "$CONFIG_FILE" ]] && grep -q "^export $key=" "$CONFIG_FILE" 2>/dev/null; then
    echo "$CONFIG_FILE"
    return 0
  fi
  
  # Check category files
  if [[ -d "$CONFIG_CATEGORIES_DIR" ]]; then
    for config_file in "$CONFIG_CATEGORIES_DIR"/*.config; do
      [[ ! -f "$config_file" ]] && continue
      if grep -q "^export $key=" "$config_file" 2>/dev/null; then
        echo "$config_file"
        return 0
      fi
    done
  fi
  
  return 1
}

get_config_value_from_file() {
  local key="$1"
  local file="$2"
  
  grep "^export $key=" "$file" | cut -d'=' -f2- | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/"
}

remove_config_key_from_file() {
  local key="$1"
  local file="$2"
  
  if command -v sed >/dev/null 2>&1; then
    local temp_file
    temp_file=$(mktemp)
    grep -v "^export $key=" "$file" > "$temp_file" 2>/dev/null || true
    mv "$temp_file" "$file"
  else
    echo "Error: sed command not found" >&2
    return 1
  fi
}