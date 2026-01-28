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
    echo "Usage: dr config rm <path/to/file>" >&2
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

# Show help/documentation for a config file
config_help() {
  local filepath="$1"

  if [[ -z "$filepath" ]]; then
    echo "Usage: dr config help <path/to/file>" >&2
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

  # Extract and display comment block from top of file
  local filename="$(basename "$filepath" .config)"
  echo -e "\033[1;31m=== $filename ===\033[0m"
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
  # Also show the exports defined
  local count=$(grep -c "^export " "$full_path" 2>/dev/null || echo "0")
  echo -e "\033[0;37m($count exports defined in this file)\033[0m"
}

# Move/rename a config file
config_move() {
  local source="$1"
  local destination="$2"

  if [[ -z "$source" ]]; then
    echo "Usage: dr config move <source> <destination>" >&2
    return 1
  fi

  if [[ -z "$destination" ]]; then
    echo "Usage: dr config move <source> <destination>" >&2
    return 1
  fi

  # Ensure .config extension for source
  [[ "$source" != *.config ]] && source="${source}.config"

  # Find source file
  local source_file="$CONFIG_DIR/$source"
  if [[ ! -f "$source_file" ]]; then
    echo "Error: Source config file not found: $source" >&2
    echo "Use 'dr config list' to see available config files" >&2
    return 1
  fi

  # Handle destination path
  # Fix bug: if destination ends with /, preserve source filename
  if [[ "$destination" == */ ]]; then
    local source_basename="$(basename "$source")"
    destination="${destination}${source_basename}"
  fi

  # Ensure .config extension for destination
  [[ "$destination" != *.config ]] && destination="${destination}.config"

  local dest_file="$CONFIG_DIR/$destination"

  # Check if destination already exists
  if [[ -f "$dest_file" ]]; then
    echo "Error: Destination config file already exists: $destination" >&2
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
    echo "Error: Failed to move config file" >&2
    return 1
  fi

  echo "✓ Moved config file: $source → $destination"

  # Clean up empty directories
  local source_dir="$(dirname "$source_file")"
  while [[ "$source_dir" != "$CONFIG_DIR" ]]; do
    if [[ -d "$source_dir" && -z "$(ls -A "$source_dir" 2>/dev/null)" ]]; then
      rmdir "$source_dir" 2>/dev/null && echo "✓ Removed empty directory: ${source_dir#"$CONFIG_DIR"/}"
    else
      break
    fi
    source_dir="$(dirname "$source_dir")"
  done

  echo "Run 'dr -r' or restart your shell to apply changes"
}

# List configs in tree format
# list_configs show_docs scope
#   show_docs: 0 = names only (-l), 1 = include docs (-L)
#   scope: optional sub-folder (e.g. "api/")
list_configs() {
  local show_docs="$1"
  local scope="${2:-}"
  local start_dir="$CONFIG_DIR/${scope%/}" # strip trailing /

  [[ ! -d "$start_dir" ]] && {
    echo "Error: No such folder: $scope" >&2
    return 1
  }

  # Colors for configs tree
  local color_folder="\033[1;33m" # Bright Yellow (folders)
  local color_config="\033[1;31m" # Bright Red (config files)
  local color_doc="\033[0;37m"    # Gray (docs)
  local color_reset="\033[0m"

  # Build tree structure: collect all directories and files
  declare -A tree_dirs=()
  declare -A tree_files=()

  while IFS= read -r -d '' file; do
    rel_path="${file#"$CONFIG_DIR"/}"
    config_name="$(basename "$rel_path" .config)"
    dir_path="$(dirname "$rel_path")"

    # Mark this directory as having content
    tree_dirs["$dir_path"]=1

    # Add file to this directory's file list
    if [[ -z "${tree_files[$dir_path]+x}" ]]; then
      tree_files["$dir_path"]="$config_name"
    else
      tree_files["$dir_path"]="${tree_files[$dir_path]}|$config_name"
    fi

    # Mark all parent directories
    local parent="$dir_path"
    while [[ "$parent" != "." ]]; do
      parent="$(dirname "$parent")"
      tree_dirs["$parent"]=1
    done
  done < <(find "$start_dir" -type f -name "*.config" -print0)

  # Check if no configs found
  if [[ ${#tree_files[@]} -eq 0 ]]; then
    echo "No config files found in $scope"
    return 0
  fi

  # Recursively print directory tree: folders first, then config files
  _print_config_tree() {
    local current_dir="$1"
    local prefix="$2"
    local depth="${3:-0}"

    # Get color for tree symbols based on depth
    local tree_color
    case $((depth % 6)) in
      0) tree_color="\033[38;5;33m" ;;  # Bright Blue
      1) tree_color="\033[38;5;35m" ;;  # Bright Cyan
      2) tree_color="\033[38;5;141m" ;; # Bright Magenta
      3) tree_color="\033[38;5;214m" ;; # Orange
      4) tree_color="\033[38;5;228m" ;; # Yellow
      5) tree_color="\033[38;5;121m" ;; # Green
    esac

    # Get all immediate subdirectories
    local -a subdirs=()
    for dir in "${!tree_dirs[@]}"; do
      local parent="$(dirname "$dir")"
      if [[ "$parent" == "$current_dir" && "$dir" != "$current_dir" ]]; then
        subdirs+=("$(basename "$dir")")
      fi
    done

    # Sort subdirectories alphabetically
    IFS=$'\n' subdirs=($(sort <<<"${subdirs[*]}"))
    unset IFS

    # Get config files in this directory (sorted alphabetically)
    local -a configs=()
    if [[ -n "${tree_files[$current_dir]+x}" ]]; then
      IFS='|' read -ra configs <<<"${tree_files[$current_dir]}"
      IFS=$'\n' configs=($(sort <<<"${configs[*]}"))
      unset IFS
    fi

    # Calculate total items (subdirs + configs)
    local total_items=$((${#subdirs[@]} + ${#configs[@]}))
    local item_index=0

    # Print subdirectories first
    for subdir in "${subdirs[@]}"; do
      [[ -z "$subdir" ]] && continue
      item_index=$((item_index + 1))

      local is_last=false
      [[ $item_index -eq $total_items ]] && is_last=true

      # Choose the branch character
      local branch="${tree_color}├──${color_reset} "
      local extension="${tree_color}│${color_reset}   "
      if $is_last; then
        branch="${tree_color}└──${color_reset} "
        extension="    "
      fi

      echo -e "${prefix}${branch}${color_folder}📁 ${subdir}${color_reset}"

      local full_path="$current_dir/$subdir"
      [[ "$current_dir" == "." ]] && full_path="$subdir"

      _print_config_tree "$full_path" "${prefix}${extension}" $((depth + 1))
    done

    # Then print config files in this directory
    for config_file in "${configs[@]}"; do
      [[ -z "$config_file" ]] && continue
      item_index=$((item_index + 1))

      local is_last=false
      [[ $item_index -eq $total_items ]] && is_last=true

      # Choose the branch character with color
      local branch="${tree_color}├──${color_reset} "
      if $is_last; then
        branch="${tree_color}└──${color_reset} "
      fi

      echo -e "${prefix}${branch}${color_config}⚙️  ${config_file}${color_reset}"

      if ((show_docs)); then
        # Find the actual file path
        local file_path="$CONFIG_DIR/$current_dir/$config_file.config"
        [[ "$current_dir" == "." ]] && file_path="$CONFIG_DIR/$config_file.config"

        # Choose doc prefix based on whether this is last item
        local doc_prefix="${prefix}"
        if $is_last; then
          doc_prefix="${prefix}    "
        else
          doc_prefix="${prefix}${tree_color}│${color_reset}   "
        fi

        # Extract first meaningful comment line after shebang
        awk '
          NR == 1 && /^#!/ { next }
          /^#/ && !/^# *$/ && !/DotRun Config File/ {
            line = $0
            sub(/^# */, "", line)
            if (line != "") {
              print "'"${doc_prefix}${color_doc}"'" line "'"$color_reset"'"
              exit
            }
          }
          /^[^#]/ && NF > 0 { exit }
        ' "$file_path"
      fi
    done
  }

  _print_config_tree "." "" 0
}
