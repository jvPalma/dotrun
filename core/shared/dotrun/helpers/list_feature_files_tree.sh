#!/usr/bin/env bash
# shellcheck disable=SC2155,SC2034

# =============================================================================
# list_feature_files_tree - Unified tree display for DotRun features
# =============================================================================
# Displays files in a colorized tree format for any feature type.
# This is the single source of truth for tree-style listing in DotRun.
#
# Usage: list_feature_files_tree <feature> <show_docs> [scope]
#   feature:   scripts | aliases | configs
#   show_docs: 0 = names only, 1 = include documentation
#   scope:     optional sub-folder (e.g., "git/")
#
# Example:
#   list_feature_files_tree scripts 0          # List all scripts
#   list_feature_files_tree aliases 1 "cd/"    # List aliases in cd/ with docs
# =============================================================================

# Resolve script directory for sourcing constants
_LFFT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source constants if not already loaded
if [[ -z "${_DR_CONSTANTS_LOADED:-}" ]]; then
  # shellcheck disable=SC1091
  source "${_LFFT_SCRIPT_DIR}/constants.sh"
fi

# =============================================================================
# MAIN FUNCTION
# =============================================================================
list_feature_files_tree() {
  local feature="$1"
  local show_docs="$2"
  local scope="${3:-}"

  # Validate feature
  case "$feature" in
    scripts|aliases|configs) ;;
    *)
      echo "Error: Invalid feature '$feature'. Use: scripts, aliases, or configs" >&2
      return 1
      ;;
  esac

  # Get feature-specific values
  local base_dir
  base_dir="$(get_feature_dir "$feature")"
  local file_ext
  file_ext="$(get_feature_ext "$feature")"
  local feature_icon
  feature_icon="$(get_feature_icon "$feature")"
  local feature_color
  feature_color="$(get_feature_color "$feature")"

  local start_dir="${base_dir}/${scope%/}" # strip trailing /

  [[ ! -d "$start_dir" ]] && {
    echo "Error: No such folder: $scope" >&2
    return 1
  }

  # Check for broken symlinks (scripts only, as they're executable)
  if [[ "$feature" == "scripts" ]]; then
    if find "$start_dir" -type l -exec test ! -e {} \; -print 2>/dev/null | grep -q .; then
      echo "Warning: Broken symlinks found in $start_dir" >&2
    fi
  fi

  # Build tree structure: collect all directories and files
  declare -A tree_dirs=()
  declare -A tree_files=()

  while IFS= read -r -d '' file; do
    local rel_path="${file#"$base_dir"/}"
    local file_name
    file_name="$(basename "$rel_path" "$file_ext")"
    local dir_path
    dir_path="$(dirname "$rel_path")"

    # Mark this directory as having content
    tree_dirs["$dir_path"]=1

    # Add file to this directory's file list
    if [[ -z "${tree_files[$dir_path]+x}" ]]; then
      tree_files["$dir_path"]="$file_name"
    else
      tree_files["$dir_path"]="${tree_files[$dir_path]}|$file_name"
    fi

    # Mark all parent directories
    local parent="$dir_path"
    while [[ "$parent" != "." ]]; do
      parent="$(dirname "$parent")"
      tree_dirs["$parent"]=1
    done
  done < <(find "$start_dir" -type f -name "*${file_ext}" -print0)

  # Check if no files found
  if [[ ${#tree_files[@]} -eq 0 ]]; then
    echo "No ${feature} files found${scope:+ in $scope}"
    return 0
  fi

  # Recursively print directory tree
  _print_feature_tree() {
    local current_dir="$1"
    local prefix="$2"
    local depth="${3:-0}"

    # Get color for tree symbols based on depth
    local tree_color="${TREE_COLORS[$((depth % ${#TREE_COLORS[@]}))]}"

    # Get all immediate subdirectories
    local -a subdirs=()
    for dir in "${!tree_dirs[@]}"; do
      local parent
      parent="$(dirname "$dir")"
      if [[ "$parent" == "$current_dir" && "$dir" != "$current_dir" ]]; then
        subdirs+=("$(basename "$dir")")
      fi
    done

    # Sort subdirectories alphabetically
    IFS=$'\n' subdirs=($(sort <<<"${subdirs[*]}"))
    unset IFS

    # Get files in this directory (sorted alphabetically)
    local -a files=()
    if [[ -n "${tree_files[$current_dir]+x}" ]]; then
      IFS='|' read -ra files <<<"${tree_files[$current_dir]}"
      IFS=$'\n' files=($(sort <<<"${files[*]}"))
      unset IFS
    fi

    # Calculate total items (subdirs + files)
    local total_items=$((${#subdirs[@]} + ${#files[@]}))
    local item_index=0

    # Print subdirectories first
    for subdir in "${subdirs[@]}"; do
      [[ -z "$subdir" ]] && continue
      item_index=$((item_index + 1))

      local is_last=false
      [[ $item_index -eq $total_items ]] && is_last=true

      # Choose the branch character
      local branch="${tree_color}├──${COLOR_RESET} "
      local extension="${tree_color}│${COLOR_RESET}   "
      if $is_last; then
        branch="${tree_color}└──${COLOR_RESET} "
        extension="    "
      fi

      echo -e "${prefix}${branch}${COLOR_FOLDER}${FOLDER_ICON} ${subdir}${COLOR_RESET}"

      local full_path="$current_dir/$subdir"
      [[ "$current_dir" == "." ]] && full_path="$subdir"

      _print_feature_tree "$full_path" "${prefix}${extension}" $((depth + 1))
    done

    # Then print files in this directory
    for file_name in "${files[@]}"; do
      [[ -z "$file_name" ]] && continue
      item_index=$((item_index + 1))

      local is_last=false
      [[ $item_index -eq $total_items ]] && is_last=true

      # Choose the branch character with color
      local branch="${tree_color}├──${COLOR_RESET} "
      if $is_last; then
        branch="${tree_color}└──${COLOR_RESET} "
      fi

      echo -e "${prefix}${branch}${feature_color}${feature_icon} ${file_name}${COLOR_RESET}"

      if ((show_docs)); then
        # Find the actual file path
        local file_path="${base_dir}/${current_dir}/${file_name}${file_ext}"
        [[ "$current_dir" == "." ]] && file_path="${base_dir}/${file_name}${file_ext}"

        # Choose doc prefix based on whether this is last item
        local doc_prefix="${prefix}"
        if $is_last; then
          doc_prefix="${prefix}    "
        else
          doc_prefix="${prefix}${tree_color}│${COLOR_RESET}   "
        fi

        # Extract documentation based on feature type
        _extract_doc "$feature" "$file_path" "$doc_prefix"
      fi
    done
  }

  _print_feature_tree "." "" 0
}

# =============================================================================
# DOCUMENTATION EXTRACTION
# =============================================================================
# Different features have different documentation formats:
# - scripts: Uses ### DOC markers
# - aliases/configs: Uses first meaningful comment line

_extract_doc() {
  local feature="$1"
  local file_path="$2"
  local doc_prefix="$3"

  case "$feature" in
    scripts)
      # Extract content between first and second ### DOC markers
      awk '
        /^### DOC/ { count++; if (count == 2) exit; next }
        count == 1 { print "'"${doc_prefix}${COLOR_DOC}"'" $0 "'"${COLOR_RESET}"'" }
      ' "$file_path"
      ;;
    aliases|configs)
      # Extract first meaningful comment line (skip shebang and generic headers)
      local skip_pattern="DotRun"
      [[ "$feature" == "aliases" ]] && skip_pattern="DotRun Aliases File"
      [[ "$feature" == "configs" ]] && skip_pattern="DotRun Config File"

      awk '
        NR == 1 && /^#!/ { next }
        /^#/ && !/^# *$/ && !/'"${skip_pattern}"'/ {
          line = $0
          sub(/^# */, "", line)
          if (line != "") {
            print "'"${doc_prefix}${COLOR_DOC}"'" line "'"${COLOR_RESET}"'"
            exit
          }
        }
        /^[^#]/ && NF > 0 { exit }
      ' "$file_path"
      ;;
  esac
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================
# If called directly (not sourced), run with provided arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  list_feature_files_tree "$@"
fi
