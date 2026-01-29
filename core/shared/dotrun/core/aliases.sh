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
# After saving, run 'dr reload' (or 'source ~/.drrc') to activate the aliases.

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
  echo "Run 'dr reload' or restart your shell to activate changes"
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
    echo "Usage: dr aliases rm <path/to/file>" >&2
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

    echo "Run 'dr reload' or restart your shell to apply changes"
  else
    echo "Cancelled"
  fi
}

# Show help/documentation for an alias file
aliases_help() {
  local filepath="$1"

  if [[ -z "$filepath" ]]; then
    echo "Usage: dr aliases help <path/to/file>" >&2
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
    echo "Usage: dr aliases move <source> <destination>" >&2
    return 1
  fi

  if [[ -z "$destination" ]]; then
    echo "Usage: dr aliases move <source> <destination>" >&2
    return 1
  fi

  # Ensure .aliases extension for source
  [[ "$source" != *.aliases ]] && source="${source}.aliases"

  # Find source file
  local source_file="$ALIASES_CONFIG_DIR/$source"
  if [[ ! -f "$source_file" ]]; then
    echo "Error: Source alias file not found: $source" >&2
    echo "Use 'dr aliases list' to see available alias files" >&2
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

  local dest_file="$ALIASES_CONFIG_DIR/$destination"

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
  while [[ "$source_dir" != "$ALIASES_CONFIG_DIR" ]]; do
    if [[ -d "$source_dir" && -z "$(ls -A "$source_dir" 2>/dev/null)" ]]; then
      rmdir "$source_dir" 2>/dev/null && echo "✓ Removed empty directory: ${source_dir#"$ALIASES_CONFIG_DIR"/}"
    else
      break
    fi
    source_dir="$(dirname "$source_dir")"
  done

  echo "Run 'dr reload' or restart your shell to apply changes"
}

# List aliases in tree format
# list_aliases show_docs scope
#   show_docs: 0 = names only (-l), 1 = include docs (-L)
#   scope: optional sub-folder (e.g. "cd/")
list_aliases() {
  local show_docs="$1"
  local scope="${2:-}"
  local start_dir="$ALIASES_CONFIG_DIR/${scope%/}" # strip trailing /

  [[ ! -d "$start_dir" ]] && {
    echo "Error: No such folder: $scope" >&2
    return 1
  }

  # Colors for aliases tree
  local color_folder="\033[1;33m" # Bright Yellow (folders)
  local color_alias="\033[1;34m"  # Bright Blue (alias files)
  local color_doc="\033[0;37m"    # Gray (docs)
  local color_reset="\033[0m"

  # Build tree structure: collect all directories and files
  declare -A tree_dirs=()
  declare -A tree_files=()

  while IFS= read -r -d '' file; do
    rel_path="${file#"$ALIASES_CONFIG_DIR"/}"
    alias_name="$(basename "$rel_path" .aliases)"
    dir_path="$(dirname "$rel_path")"

    # Mark this directory as having content
    tree_dirs["$dir_path"]=1

    # Add file to this directory's file list
    if [[ -z "${tree_files[$dir_path]+x}" ]]; then
      tree_files["$dir_path"]="$alias_name"
    else
      tree_files["$dir_path"]="${tree_files[$dir_path]}|$alias_name"
    fi

    # Mark all parent directories
    local parent="$dir_path"
    while [[ "$parent" != "." ]]; do
      parent="$(dirname "$parent")"
      tree_dirs["$parent"]=1
    done
  done < <(find "$start_dir" -type f -name "*.aliases" -print0)

  # Check if no aliases found
  if [[ ${#tree_files[@]} -eq 0 ]]; then
    echo "No alias files found in $scope"
    return 0
  fi

  # Recursively print directory tree: folders first, then alias files
  _print_tree() {
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

    # Get alias files in this directory (sorted alphabetically)
    local -a aliases=()
    if [[ -n "${tree_files[$current_dir]+x}" ]]; then
      IFS='|' read -ra aliases <<<"${tree_files[$current_dir]}"
      IFS=$'\n' aliases=($(sort <<<"${aliases[*]}"))
      unset IFS
    fi

    # Calculate total items (subdirs + aliases)
    local total_items=$((${#subdirs[@]} + ${#aliases[@]}))
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

      _print_tree "$full_path" "${prefix}${extension}" $((depth + 1))
    done

    # Then print alias files in this directory
    for alias_file in "${aliases[@]}"; do
      [[ -z "$alias_file" ]] && continue
      item_index=$((item_index + 1))

      local is_last=false
      [[ $item_index -eq $total_items ]] && is_last=true

      # Choose the branch character with color
      local branch="${tree_color}├──${color_reset} "
      if $is_last; then
        branch="${tree_color}└──${color_reset} "
      fi

      echo -e "${prefix}${branch}${color_alias}📝 ${alias_file}${color_reset}"

      if ((show_docs)); then
        # Find the actual file path
        local file_path="$ALIASES_CONFIG_DIR/$current_dir/$alias_file.aliases"
        [[ "$current_dir" == "." ]] && file_path="$ALIASES_CONFIG_DIR/$alias_file.aliases"

        # Choose doc prefix based on whether this is last item
        local doc_prefix="${prefix}"
        if $is_last; then
          doc_prefix="${prefix}    "
        else
          doc_prefix="${prefix}${tree_color}│${color_reset}   "
        fi

        # Extract first meaningful comment line after shebang
        # Skip shebang, look for first non-empty comment line that's not generic
        awk '
          NR == 1 && /^#!/ { next }
          /^#/ && !/^# *$/ && !/DotRun Aliases File/ {
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

  _print_tree "." "" 0
}
