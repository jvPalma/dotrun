#!/usr/bin/env bash
# shellcheck disable=SC2155
# DotRun Aliases Management System
# File-based workflow: one file contains multiple aliases

set -euo pipefail

# Initialize aliases system
aliases_init() {
  # TODO: CREATE/USE HELP MESSAGE SCRIPT
  echo "Initializing aliases system..."
  mkdir -p "$USER_COLLECTION_ALIASES"
  echo "✓ Created aliases directory: $USER_COLLECTION_ALIASES"
  echo
  echo "Set aliases with: dr -a <path/to/file>"
  echo "Example: dr -a 01-git"
  echo "         dr -a cd/shortcuts"
}

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

# Create skeleton for new alias file
create_alias_file_skeleton() {
  local filepath="$1"
  local filename="$(basename "$filepath" .aliases)"

  cat >"$filepath" <<'EOF'
#!/usr/bin/env bash
# DotRun Aliases File
#
# This file can contain multiple aliases.
# Each alias follows the format:  alias name='command'
#
# Examples:
#   alias ll='ls -lah'
#   alias la='ls -A'
#   alias ..='cd ..'
#   alias ...='cd ../..'
#   alias gs='git status'
#   alias gc='git commit'
#   alias gp='git push'
#
# After saving, run 'dr reload' (or 'source ~/.drrc') to activate the aliases.

# Add your aliases below:

EOF
}

# Set alias file (idempotent - creates if missing, edits if exists)
aliases_set() {
  local filepath="$1"

  if [[ -z "$filepath" ]]; then
    exec "${BASH_SOURCE[0]%/core/*}/core/help-messages/aliases/set.sh"
  fi

  # Ensure .aliases extension
  [[ "$filepath" != *.aliases ]] && filepath="${filepath}.aliases"

  local full_path="$USER_COLLECTION_ALIASES/$filepath"

  validate_editor || return 1

  # Create directory if needed
  mkdir -p "$(dirname "$full_path")"

  # If file doesn't exist, create skeleton
  if [[ ! -f "$full_path" ]]; then
    create_alias_file_skeleton "$full_path"
    echo "✓ Created alias file: $full_path"
  else
    echo "Opening existing alias file: $full_path"
  fi

  # Open in editor (works for both new and existing)
  "$EDITOR" "$full_path"

  echo "✓ Alias file ready: $full_path"
  echo "Run 'dr reload' or restart your shell to activate changes"
}

# Remove an alias file
aliases_remove() {
  local filepath="$1"

  if [[ -z "$filepath" ]]; then
    echo "Usage: dr -a rm <path/to/file>" >&2
    return 1
  fi

  # Ensure .aliases extension
  [[ "$filepath" != *.aliases ]] && filepath="${filepath}.aliases"

  local full_path="$USER_COLLECTION_ALIASES/$filepath"

  if [[ ! -f "$full_path" ]]; then
    echo "Error: Alias file not found: $filepath" >&2
    echo "Use 'dr -a list' to see available alias files" >&2
    return 1
  fi

  echo "Remove alias file: $full_path"
  read -r -p "Are you sure? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm "$full_path"
    echo "✓ Removed alias file: $filepath"

    # Clean up empty directories
    local dir_path="$(dirname "$full_path")"
    while [[ "$dir_path" != "$USER_COLLECTION_ALIASES" ]]; do
      if [[ -d "$dir_path" && -z "$(ls -A "$dir_path" 2>/dev/null)" ]]; then
        rmdir "$dir_path" 2>/dev/null && echo "✓ Removed empty directory: ${dir_path#"$USER_COLLECTION_ALIASES"/}"
      else
        break
      fi
      dir_path="$(dirname "$dir_path")"
    done

    echo "Run 'dr reload' or restart your shell to apply changes"
  else
    echo "Cancelled"
  fi
}

# Show help/documentation for an alias file
aliases_help() {
  local filepath="$1"

  if [[ -z "$filepath" ]]; then
    echo "Usage: dr -a help <path/to/file>" >&2
    return 1
  fi

  # Ensure .aliases extension
  [[ "$filepath" != *.aliases ]] && filepath="${filepath}.aliases"

  local full_path="$USER_COLLECTION_ALIASES/$filepath"

  if [[ ! -f "$full_path" ]]; then
    echo "Error: Alias file not found: $filepath" >&2
    echo "Use 'dr -a list' to see available alias files" >&2
    return 1
  fi

  # Extract and display comment block from top of file
  # Look for lines starting with # until we hit a non-comment line
  local filename="$(basename "$filepath" .aliases)"
  echo -e "\033[1;33m=== $filename ===\033[0m"
  echo ""

  # Extract the header comment block (lines starting with #)
  # Stop at first non-comment, non-empty line
  awk '
    /^#!/ { next }  # Skip shebang
    /^#/ { gsub(/^# ?/, ""); print; next }
    /^[[:space:]]*$/ { print; next }  # Keep blank lines in comment block
    { exit }  # Stop at first non-comment line
  ' "$full_path"

  echo ""
  # Also show the aliases defined
  local count=$(grep -c "^alias " "$full_path" 2>/dev/null || echo "0")
  echo -e "\033[0;37m($count aliases defined in this file)\033[0m"
}

# Move/rename an alias file
aliases_move() {
  local source="$1"
  local destination="$2"

  if [[ -z "$source" ]]; then
    echo "Usage: dr -a move <source> <destination>" >&2
    return 1
  fi

  if [[ -z "$destination" ]]; then
    echo "Usage: dr -a move <source> <destination>" >&2
    return 1
  fi

  # Ensure .aliases extension for source
  [[ "$source" != *.aliases ]] && source="${source}.aliases"

  # Find source file
  local source_file="$USER_COLLECTION_ALIASES/$source"
  if [[ ! -f "$source_file" ]]; then
    echo "Error: Source alias file not found: $source" >&2
    echo "Use 'dr -a list' to see available alias files" >&2
    return 1
  fi

  # Handle destination path
  # Fix bug: if destination ends with /, preserve source filename
  if [[ "$destination" == */ ]]; then
    local source_basename="$(basename "$source")"
    destination="${destination}${source_basename}"
  fi

  # Ensure .aliases extension for destination
  [[ "$destination" != *.aliases ]] && destination="${destination}.aliases"

  local dest_file="$USER_COLLECTION_ALIASES/$destination"

  # Check if destination already exists
  if [[ -f "$dest_file" ]]; then
    echo "Error: Destination alias file already exists: $destination" >&2
    return 1
  fi

  # Check for circular move
  if [[ "$source_file" == "$dest_file" ]]; then
    echo "Error: Source and destination are the same" >&2
    return 1
  fi

  # Create destination directories if needed
  local dest_dir="$(dirname "$dest_file")"
  if [[ ! -d "$dest_dir" ]]; then
    if ! mkdir -p "$dest_dir" 2>/dev/null; then
      echo "Error: Failed to create destination directory: $dest_dir" >&2
      return 1
    fi
  fi

  # Check write permissions
  if [[ -d "$dest_dir" ]] && [[ ! -w "$dest_dir" ]]; then
    echo "Error: No write permission for destination directory: $dest_dir" >&2
    return 1
  fi

  # Color variables for preview
  local color_source="\033[1;96m" # Cyan
  local color_dest="\033[1;92m"   # Green
  local color_reset="\033[0m"

  # Show colored preview
  echo -e "Move: ${color_source}${source}${color_reset} → ${color_dest}${destination}${color_reset}"
  read -r -p "Confirm? [Y/n] " confirm

  # Accept Y, y, or Enter (default yes)
  if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo "Cancelled"
    return 0
  fi

  # Move the file
  if ! mv "$source_file" "$dest_file" 2>/dev/null; then
    echo "Error: Failed to move alias file" >&2
    return 1
  fi

  echo "✓ Moved alias file: $source → $destination"

  # Clean up empty directories
  local source_dir="$(dirname "$source_file")"
  while [[ "$source_dir" != "$USER_COLLECTION_ALIASES" ]]; do
    if [[ -d "$source_dir" && -z "$(ls -A "$source_dir" 2>/dev/null)" ]]; then
      rmdir "$source_dir" 2>/dev/null && echo "✓ Removed empty directory: ${source_dir#"$USER_COLLECTION_ALIASES"/}"
    else
      break
    fi
    source_dir="$(dirname "$source_dir")"
  done

  echo "Run 'dr reload' or restart your shell to apply changes"
}

# List aliases in tree format (delegates to unified helper)
# list_aliases show_docs scope
#   show_docs: 0 = names only (-l), 1 = include docs (-L)
#   scope: optional sub-folder (e.g. "cd/")
list_aliases() {
  local _helper_path
  _helper_path="$(dirname "${BASH_SOURCE[0]}")/../helpers/list_feature_files_tree.sh"
  
  if [[ -f "$_helper_path" ]]; then
    # shellcheck disable=SC1090
    source "$_helper_path"
    list_feature_files_tree "aliases" "$1" "$2"
  else
    echo "Error: List helper not found at $_helper_path" >&2
    return 1
  fi
}
