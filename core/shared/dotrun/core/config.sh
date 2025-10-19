#!/usr/bin/env bash
# shellcheck disable=SC2155
# DotRun Config Management System
# File-based workflow: one file contains multiple config exports

set -euo pipefail

CONFIG_DIR="${DR_CONFIG:-$HOME/.config/dotrun}/configs"

# Validate editor is set and available
validate_editor() {
  if [[ -z "${EDITOR:-}" ]]; then
    echo "Error: EDITOR environment variable is not set" >&2
    echo "Set it with: export EDITOR=nano (or code, vim, etc.)" >&2
    return 1
  fi

  if ! command -v "$EDITOR" >/dev/null 2>&1; then
    echo "Error: Editor '$EDITOR' not found in PATH" >&2
    return 1
  fi

  return 0
}

# Create skeleton for new config file
create_config_file_skeleton() {
  local filepath="$1"
  local filename="$(basename "$filepath" .config)"

  cat >"$filepath" <<'EOF'
#!/usr/bin/env bash
# DotRun Config File
#
# This file can contain multiple configuration exports.
# Each export follows the format:  export KEY="value"
#
# Examples:
#   export API_KEY="your-api-key-here"
#   export DB_HOST="localhost"
#   export DB_PORT="5432"
#   export NODE_ENV="development"
#   export DEBUG="true"
#
# These variables will be available in your shell after running:
#   source ~/.drrc
# Or reload with:
#   dr -r  (or: dr reload)
#
# Add your configuration exports below:

EOF
}

# Set config file (idempotent - creates if missing, edits if exists)
config_set() {
  local filepath="$1"

  if [[ -z "$filepath" ]]; then
    echo "Usage: dr config set <path/to/file>" >&2
    echo "" >&2
    echo "Creates or opens a config file for editing." >&2
    echo "One file can contain multiple configuration exports." >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  dr config set 01-main          # Creates/edits ~/.config/dotrun/configs/01-main.config" >&2
    echo "  dr config set api/keys         # Creates/edits ~/.config/dotrun/configs/api/keys.config" >&2
    echo "  dr config set dev/database     # Creates/edits ~/.config/dotrun/configs/dev/database.config" >&2
    return 1
  fi

  # Ensure .config extension
  [[ "$filepath" != *.config ]] && filepath="${filepath}.config"

  local full_path="$CONFIG_DIR/$filepath"

  validate_editor || return 1

  # Create directory if needed
  mkdir -p "$(dirname "$full_path")"

  # If file doesn't exist, create skeleton
  if [[ ! -f "$full_path" ]]; then
    create_config_file_skeleton "$full_path"
    echo "✓ Created config file: $full_path"
  else
    echo "Opening existing config file: $full_path"
  fi

  # Open in editor (works for both new and existing)
  "$EDITOR" "$full_path"

  echo "✓ Config file ready: $full_path"
  echo "Run 'dr -r' or restart your shell to activate changes"
}

# List all config files
config_list() {
  local show_categories="${1:-false}"
  local filter_category="${2:-}"

  if [[ ! -d "$CONFIG_DIR" ]]; then
    echo "No configs directory found."
    echo "Create one with: dr config set <filename>"
    return
  fi

  local config_files=()
  while IFS= read -r -d '' file; do
    config_files+=("$file")
  done < <(find "$CONFIG_DIR" -name "*.config" -type f -print0 2>/dev/null | sort -z)

  if [[ ${#config_files[@]} -eq 0 ]]; then
    echo "No config files found."
    echo "Create one with: dr config set <filename>"
    return
  fi

  echo "Config files:"
  for file in "${config_files[@]}"; do
    local relpath="${file#"$CONFIG_DIR"/}"
    local category="$(dirname "$relpath")"
    [[ "$category" == "." ]] && category="(root)"

    # Apply category filter if specified
    if [[ -n "$filter_category" && "$category" != "$filter_category" ]]; then
      continue
    fi

    if [[ "$show_categories" == "true" ]]; then
      echo "  $relpath [$category]"
    else
      echo "  $relpath"
    fi

    # Show export count
    local count=$(grep -c "^export " "$file" 2>/dev/null || echo "0")
    echo "    ($count exports defined)"
  done
}

# Remove a config file
config_remove() {
  local filepath="$1"

  if [[ -z "$filepath" ]]; then
    echo "Usage: dr config remove <path/to/file>" >&2
    return 1
  fi

  # Ensure .config extension
  [[ "$filepath" != *.config ]] && filepath="${filepath}.config"

  local full_path="$CONFIG_DIR/$filepath"

  if [[ ! -f "$full_path" ]]; then
    echo "Error: Config file not found: $filepath" >&2
    echo "Use 'dr config list' to see available config files" >&2
    return 1
  fi

  echo "Remove config file: $full_path"
  read -r -p "Are you sure? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm "$full_path"
    echo "✓ Removed config file: $filepath"

    # Clean up empty directories
    local dir_path="$(dirname "$full_path")"
    while [[ "$dir_path" != "$CONFIG_DIR" ]]; do
      if [[ -d "$dir_path" && -z "$(ls -A "$dir_path" 2>/dev/null)" ]]; then
        rmdir "$dir_path" 2>/dev/null && echo "✓ Removed empty directory: ${dir_path#"$CONFIG_DIR"/}"
      else
        break
      fi
      dir_path="$(dirname "$dir_path")"
    done

    echo "Run 'dr -r' or restart your shell to apply changes"
  else
    echo "Cancelled"
  fi
}
