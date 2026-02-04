#!/usr/bin/env bash
# shellcheck disable=SC2155
# DotRun Scripts Management System
# File-based workflow: manage executable shell scripts

set -euo pipefail

# Input validation
validate_script_name() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Error: Script name cannot be empty" >&2
    return 1
  fi
  if [[ "$name" =~ [^a-zA-Z0-9_/-] ]]; then
    echo "Error: Script name contains invalid characters. Use only alphanumeric, underscore, dash, and forward slash." >&2
    return 1
  fi
}

# Check if required directories exist and are writable
scripts_check_prerequisites() {
  if [[ ! -d "$USER_COLLECTION_SCRIPTS" ]] && ! mkdir -p "$USER_COLLECTION_SCRIPTS" 2>/dev/null; then
    echo "Error: Cannot create or access USER_COLLECTION_SCRIPTS: $USER_COLLECTION_SCRIPTS" >&2
    exit 1
  fi
}

# List scripts in tree format (delegates to unified helper)
# list_scripts show_docs scope
#   show_docs: 0 = names only, 1 = include docs
#   scope:     optional sub-folder (e.g. "code/")
list_scripts() {
  local _helper_path
  _helper_path="$(dirname "${BASH_SOURCE[0]}")/../helpers/list_feature_files_tree.sh"

  if [[ -f "$_helper_path" ]]; then
    # shellcheck disable=SC1090
    source "$_helper_path"
    list_feature_files_tree "scripts" "$1" "$2"
  else
    echo "Error: List helper not found at $_helper_path" >&2
    return 1
  fi
}

# Create script skeleton
create_script_skeleton() {
  local name="$1"
  local file="$USER_COLLECTION_SCRIPTS/$name.sh"
  mkdir -p "$(dirname "$file")"

  # Create script file from template
  local script_basename="$(basename "$name")"

  # Check if template file exists
  if [[ ! -f "$TEMPLATE_NEW_SCRIPT" ]]; then
    echo "Error: Template file not found at $TEMPLATE_NEW_SCRIPT" >&2
    echo "Please run the installer to set up DotRun properly." >&2
    return 1
  fi

  # Copy template and replace placeholder
  sed "s/{{SCRIPT_NAME}}/$script_basename/g" "$TEMPLATE_NEW_SCRIPT" > "$file"
  chmod +x "$file"
}

# Search script by name regardless of path
find_script_file() {
  local query="$1"

  # 1) explicit sub-folder path?
  if [[ "$query" == */* ]]; then
    local exact="$USER_COLLECTION_SCRIPTS/$query.sh"
    if [[ -f "$exact" ]]; then
      # Check if file is executable
      if [[ ! -x "$exact" ]]; then
        echo "Error: Script '$exact' is not executable" >&2
        return 1
      fi
      # Check for circular symlinks
      if [[ -L "$exact" ]] && ! readlink -e "$exact" >/dev/null 2>&1; then
        echo "Error: Script '$exact' is a broken symlink" >&2
        return 1
      fi
      echo "$exact"
      return
    fi
  fi

  # 2) fallback: search anywhere for basename
  local base
  base="$(basename "$query").sh"
  local found_file
  found_file=$(find "$USER_COLLECTION_SCRIPTS" -type f -name "$base" 2>/dev/null | head -n 1)

  if [[ -n "$found_file" ]]; then
    # Check if file is executable
    if [[ ! -x "$found_file" ]]; then
      echo "Error: Script '$found_file' is not executable" >&2
      return 1
    fi
    # Check for circular symlinks
    if [[ -L "$found_file" ]] && ! readlink -e "$found_file" >/dev/null 2>&1; then
      echo "Error: Script '$found_file' is a broken symlink" >&2
      return 1
    fi
    echo "$found_file"
  fi
}

add_script() {
  local name="$1"
  validate_script_name "$name" || exit 1
  scripts_check_prerequisites

  local file="$USER_COLLECTION_SCRIPTS/$name.sh"
  if [[ ! -f "$file" ]]; then
    create_script_skeleton "$name"
    echo "Created new script: $file"
  fi

  # Validate editor before using
  if [[ -z "$EDITOR" ]] || ! command -v "$EDITOR" >/dev/null 2>&1; then
    echo "Error: No valid editor found. Please set EDITOR environment variable." >&2
    exit 1
  fi

  "$EDITOR" "$file"
  [[ $(type -t run_shell_lint) == "function" ]] && run_shell_lint "$file"
}

edit_script() {
  local file
  file=$(find_script_file "$1")
  if [[ -n "$file" ]]; then
    # Validate editor before using
    if [[ -z "$EDITOR" ]] || ! command -v "$EDITOR" >/dev/null 2>&1; then
      echo "Error: No valid editor found. Please set EDITOR environment variable." >&2
      exit 1
    fi

    "$EDITOR" "$file"
    [[ $(type -t run_shell_lint) == "function" ]] && run_shell_lint "$file"
  else
    echo "Error: Script '$1' not found" >&2
    echo "Use 'dr -l' to list available scripts" >&2
    exit 1
  fi
}

# Set script (idempotent - creates if missing, edits if exists)
set_script() {
  local name="$1"
  validate_script_name "$name" || exit 1
  scripts_check_prerequisites

  # Validate editor before using
  if [[ -z "$EDITOR" ]] || ! command -v "$EDITOR" >/dev/null 2>&1; then
    echo "Error: No valid editor found. Please set EDITOR environment variable." >&2
    exit 1
  fi

  local file="$USER_COLLECTION_SCRIPTS/$name.sh"

  # If file doesn't exist, create skeleton
  if [[ ! -f "$file" ]]; then
    create_script_skeleton "$name"
    echo "Created new script: $file"
  else
    echo "Opening existing script: $file"
  fi

  # Open in editor (works for both new and existing)
  "$EDITOR" "$file"
  [[ $(type -t run_shell_lint) == "function" ]] && run_shell_lint "$file"
}

show_script_help() {
  local file
  file=$(find_script_file "$1")
  if [[ -z "$file" ]]; then
    echo "Error: Script '$1' not found" >&2
    exit 1
  fi

  # Try to extract content between SECOND and THIRD ### DOC markers
  # If no third marker exists, fallback to content between FIRST and SECOND
  local doc_content
  doc_content=$(awk '/^### DOC/ { count++; if (count == 3) exit; next } count == 2 { print }' "$file")

  # If no content found (no third marker), fallback to first-to-second
  if [[ -z "$doc_content" ]]; then
    awk '/^### DOC/ { count++; if (count == 2) exit; next } count == 1 { print }' "$file"
  else
    echo "$doc_content"
  fi
}

# Move/rename a script
move_script() {
  local source="$1"
  local destination="$2"

  # Validate inputs
  validate_script_name "$source" || exit 1
  validate_script_name "$destination" || exit 1

  # Find source script file
  local source_file
  source_file=$(find_script_file "$source")
  if [[ -z "$source_file" ]]; then
    echo "Error: Source script '$source' not found" >&2
    echo "Use 'dr -l' to list available scripts" >&2
    exit 1
  fi

  # Get relative paths
  local source_rel="${source_file#"$USER_COLLECTION_SCRIPTS"/}"
  local source_name="$(basename "$source_rel" .sh)"
  local source_dir="$(dirname "$source_rel")"

  # Construct destination paths
  local dest_file="$USER_COLLECTION_SCRIPTS/$destination.sh"
  local dest_name="$(basename "$destination")"
  local dest_dir="$(dirname "$destination")"

  # Normalize directory paths
  [[ "$source_dir" == "." ]] && source_dir=""
  [[ "$dest_dir" == "." ]] && dest_dir=""

  # Check if destination already exists
  if [[ -f "$dest_file" ]]; then
    echo "Error: Destination script '$destination' already exists" >&2
    exit 1
  fi

  # Check for circular move (source and destination are the same)
  if [[ "$source_file" == "$dest_file" ]]; then
    echo "Error: Source and destination are the same" >&2
    exit 1
  fi

  # Check write permissions on destination directory
  local dest_parent_dir="$USER_COLLECTION_SCRIPTS"
  [[ -n "$dest_dir" ]] && dest_parent_dir="$USER_COLLECTION_SCRIPTS/$dest_dir"
  if [[ -d "$dest_parent_dir" ]] && [[ ! -w "$dest_parent_dir" ]]; then
    echo "Error: No write permission for destination directory: $dest_parent_dir" >&2
    exit 1
  fi

  # Create destination directories if needed
  if [[ -n "$dest_dir" ]]; then
    if ! mkdir -p "$USER_COLLECTION_SCRIPTS/$dest_dir" 2>/dev/null; then
      echo "Error: Failed to create destination directory: $USER_COLLECTION_SCRIPTS/$dest_dir" >&2
      exit 1
    fi
  fi

  # Move script file
  if ! mv "$source_file" "$dest_file" 2>/dev/null; then
    echo "Error: Failed to move script file" >&2
    exit 1
  fi
  echo "Moved script: $source -> $destination"

  # Update inline documentation in script if name changed
  if [[ "$source_name" != "$dest_name" ]]; then
    # Update script name references in DOC_TOKEN section
    local temp_script="$dest_file.tmp"
    sed "s/# $source_name -/# $dest_name -/g" "$dest_file" > "$temp_script"
    mv "$temp_script" "$dest_file"
    chmod +x "$dest_file"  # Ensure script remains executable
    echo "Updated script inline documentation"
  fi

  # Clean up empty source directories (including parent directories)
  if [[ -n "$source_dir" ]]; then
    # Clean up bin directories
    local dir_to_check="$source_dir"
    while [[ -n "$dir_to_check" ]]; do
      if [[ -d "$USER_COLLECTION_SCRIPTS/$dir_to_check" && -z "$(ls -A "$USER_COLLECTION_SCRIPTS/$dir_to_check" 2>/dev/null)" ]]; then
        rmdir "$USER_COLLECTION_SCRIPTS/$dir_to_check" 2>/dev/null && echo "Removed empty directory: bin/$dir_to_check"
      else
        break  # Directory not empty or doesn't exist, stop checking parents
      fi
      # Move to parent directory
      dir_to_check="$(dirname "$dir_to_check")"
      [[ "$dir_to_check" == "." ]] && break
    done
  fi

  echo "Successfully moved/renamed script: $source -> $destination"
  echo "Run with: dr $destination"
}

# Remove/delete a script
remove_script() {
  local name="$1"

  # Validate input
  validate_script_name "$name" || exit 1
  scripts_check_prerequisites

  # Find script file
  local script_file
  script_file=$(find_script_file "$name")
  if [[ -z "$script_file" ]]; then
    echo "Error: Script '$name' not found" >&2
    echo "Use 'dr -l' to list available scripts" >&2
    exit 1
  fi

  # Get relative paths
  local rel_path="${script_file#"$USER_COLLECTION_SCRIPTS"/}"
  local script_name
  script_name="$(basename "$rel_path" .sh)"
  local script_dir
  script_dir="$(dirname "$rel_path")"

  # Normalize directory path
  [[ "$script_dir" == "." ]] && script_dir=""

  # Display what will be removed with color
  echo -e "${COLOR_SCRIPTS}Remove script:${COLOR_RESET} $rel_path"
  read -r -p "Are you sure? [y/N] " confirm

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm "$script_file"
    echo -e "${COLOR_SCRIPTS}Removed script:${COLOR_RESET} $name"

    # Clean up empty directories
    if [[ -n "$script_dir" ]]; then
      local dir_to_check="$script_dir"
      while [[ -n "$dir_to_check" ]]; do
        if [[ -d "$USER_COLLECTION_SCRIPTS/$dir_to_check" && -z "$(ls -A "$USER_COLLECTION_SCRIPTS/$dir_to_check" 2>/dev/null)" ]]; then
          rmdir "$USER_COLLECTION_SCRIPTS/$dir_to_check" 2>/dev/null && echo "Removed empty directory: $dir_to_check"
        else
          break
        fi
        dir_to_check="$(dirname "$dir_to_check")"
        [[ "$dir_to_check" == "." ]] && break
      done
    fi

    echo "Successfully removed script: $name"
  else
    echo "Cancelled"
  fi
}

run_script() {
  local name="$1"
  shift
  local file
  file=$(find_script_file "$name")
  if [[ -z "$file" ]]; then
    echo "Error: Script '$name' not found" >&2
    echo "Use 'dr -l' to list available scripts" >&2
    exit 1
  fi

  # Export environment variables for scripts
  export DR_CONFIG="$USER_COLLECTION_PATH"
  export DR_LOAD_HELPERS="${HOME}/.local/share/dotrun/helpers/loadHelpers.sh"

  "$file" "$@"
}
