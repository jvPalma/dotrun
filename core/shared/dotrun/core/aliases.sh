#!/usr/bin/env bash
# shellcheck disable=SC2155
# DotRun Aliases Management System
# File-based workflow: one file contains multiple aliases

set -euo pipefail

ALIASES_CONFIG_DIR="${DR_CONFIG:-$HOME/.config/dotrun}/aliases"

# Initialize aliases system
aliases_init() {
  echo "Initializing aliases system..."
  mkdir -p "$ALIASES_CONFIG_DIR"
  echo "✓ Created aliases directory: $ALIASES_CONFIG_DIR"
  echo
  echo "Set aliases with: dr aliases set <path/to/file>"
  echo "Example: dr aliases set 01-git"
  echo "         dr aliases set cd/shortcuts"
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
# After saving, run 'dr aliases reload' to activate the aliases.

# Add your aliases below:

EOF
}

# Set alias file (idempotent - creates if missing, edits if exists)
aliases_set() {
  local filepath="$1"

  if [[ -z "$filepath" ]]; then
    echo "Usage: dr aliases set <path/to/file>" >&2
    echo "" >&2
    echo "Creates or opens an alias file for editing." >&2
    echo "One file can contain multiple aliases." >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  dr aliases set 01-git          # Creates/edits ~/.config/dotrun/aliases/01-git.aliases" >&2
    echo "  dr aliases set cd/shortcuts    # Creates/edits ~/.config/dotrun/aliases/cd/shortcuts.aliases" >&2
    echo "  dr aliases set docker/compose  # Creates/edits ~/.config/dotrun/aliases/docker/compose.aliases" >&2
    return 1
  fi

  # Ensure .aliases extension
  [[ "$filepath" != *.aliases ]] && filepath="${filepath}.aliases"

  local full_path="$ALIASES_CONFIG_DIR/$filepath"

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
  echo "Run 'dr aliases reload' or restart your shell to activate changes"
}

# List all alias files
aliases_list() {
  local show_categories="${1:-false}"
  local filter_category="${2:-}"

  if [[ ! -d "$ALIASES_CONFIG_DIR" ]]; then
    echo "No aliases directory found. Run 'dr aliases init' to create it."
    return
  fi

  local alias_files=()
  while IFS= read -r -d '' file; do
    alias_files+=("$file")
  done < <(find "$ALIASES_CONFIG_DIR" -name "*.aliases" -type f -print0 2>/dev/null | sort -z)

  if [[ ${#alias_files[@]} -eq 0 ]]; then
    echo "No alias files found."
    echo "Create one with: dr aliases set <filename>"
    return
  fi

  echo "Alias files:"
  for file in "${alias_files[@]}"; do
    local relpath="${file#"$ALIASES_CONFIG_DIR"/}"
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

    # Show alias count
    local count=$(grep -c "^alias " "$file" 2>/dev/null || echo "0")
    echo "    ($count aliases defined)"
  done
}

# Remove an alias file
aliases_remove() {
  local filepath="$1"

  if [[ -z "$filepath" ]]; then
    echo "Usage: dr aliases remove <path/to/file>" >&2
    return 1
  fi

  # Ensure .aliases extension
  [[ "$filepath" != *.aliases ]] && filepath="${filepath}.aliases"

  local full_path="$ALIASES_CONFIG_DIR/$filepath"

  if [[ ! -f "$full_path" ]]; then
    echo "Error: Alias file not found: $filepath" >&2
    echo "Use 'dr aliases list' to see available alias files" >&2
    return 1
  fi

  echo "Remove alias file: $full_path"
  read -r -p "Are you sure? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm "$full_path"
    echo "✓ Removed alias file: $filepath"

    # Clean up empty directories
    local dir_path="$(dirname "$full_path")"
    while [[ "$dir_path" != "$ALIASES_CONFIG_DIR" ]]; do
      if [[ -d "$dir_path" && -z "$(ls -A "$dir_path" 2>/dev/null)" ]]; then
        rmdir "$dir_path" 2>/dev/null && echo "✓ Removed empty directory: ${dir_path#"$ALIASES_CONFIG_DIR"/}"
      else
        break
      fi
      dir_path="$(dirname "$dir_path")"
    done

    echo "Run 'dr aliases reload' or restart your shell to apply changes"
  else
    echo "Cancelled"
  fi
}

# Reload aliases in current shell
aliases_reload() {
  echo "Reloading aliases..."

  # Detect current shell
  local current_shell
  if [[ -n "${BASH_VERSION:-}" ]]; then
    current_shell="bash"
  elif [[ -n "${ZSH_VERSION:-}" ]]; then
    current_shell="zsh"
  elif [[ -n "${FISH_VERSION:-}" ]]; then
    current_shell="fish"
  else
    echo "Error: Unknown shell" >&2
    return 1
  fi

  # Source the shell-specific alias loader
  local loader="${HOME}/.local/share/dotrun/shell/${current_shell}/aliases.sh"
  if [[ -f "$loader" ]]; then
    # shellcheck disable=SC1090
    source "$loader"
    echo "✓ Aliases reloaded for $current_shell"
  else
    echo "Error: Alias loader not found: $loader" >&2
    echo "Make sure DotRun is properly installed" >&2
    return 1
  fi
}
