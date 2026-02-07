#!/usr/bin/env bash
# loadHelpers - Flexible helper loading with pattern matching
# Location: ~/.local/share/dotrun/helpers/loadHelpers.sh
# Version: 1.1.0 (bash 3.x+ compatible)

# Bash version detection
_DR_BASH_MAJOR="${BASH_VERSINFO[0]:-3}"
_DR_BASH_MINOR="${BASH_VERSINFO[1]:-0}"

# Global tracking (prevent re-loading and circular dependencies)
# Bash 4+ uses associative arrays, Bash 3 uses indexed arrays
if [[ $_DR_BASH_MAJOR -ge 4 ]]; then
  # Bash 4+: Use associative array
  declare -gA _DR_LOADED_HELPERS 2>/dev/null || declare -A _DR_LOADED_HELPERS
  declare -gi _DR_LOAD_DEPTH=${_DR_LOAD_DEPTH:-0} 2>/dev/null
  declare -gri _DR_LOAD_DEPTH_MAX=${_DR_LOAD_DEPTH_MAX:-10} 2>/dev/null
else
  # Bash 3: Use indexed array
  _DR_LOADED_HELPERS=()
  _DR_LOAD_DEPTH=0
  _DR_LOAD_DEPTH_MAX=10
fi

# Helper function to check if a path is already loaded (bash 3 compatible)
_dr_is_loaded() {
  local path="$1"
  if [[ $_DR_BASH_MAJOR -ge 4 ]]; then
    # Bash 4+: Check associative array
    [[ -n "${_DR_LOADED_HELPERS[$path]:-}" ]]
  else
    # Bash 3: Search indexed array
    local item
    for item in "${_DR_LOADED_HELPERS[@]}"; do
      [[ "$item" == "$path" ]] && return 0
    done
    return 1
  fi
}

# Helper function to mark a path as loaded (bash 3 compatible)
_dr_mark_loaded() {
  local path="$1"
  if [[ $_DR_BASH_MAJOR -ge 4 ]]; then
    # Bash 4+: Set in associative array
    _DR_LOADED_HELPERS["$path"]=1
  else
    # Bash 3: Append to indexed array
    _DR_LOADED_HELPERS+=("$path")
  fi
}

# Cross-platform readlink -f alternative (works on bash 3+, macOS, Linux)
_dr_realpath() {
  local path="$1"

  # Try readlink -f first (Linux)
  if readlink -f "$path" 2>/dev/null; then
    return 0
  fi

  # Fallback for macOS/BSD (no -f flag)
  if [[ -d "$path" ]]; then
    (cd "$path" && pwd -P)
  elif [[ -f "$path" ]]; then
    local dir file
    dir="$(dirname "$path")"
    file="$(basename "$path")"
    (cd "$dir" && echo "$(pwd -P)/$file")
  else
    # Path doesn't exist, try to resolve as much as possible
    echo "$path"
  fi
}

loadHelpers() {
  local query="$1"
  local mode="${2:-}"

  # Validation
  if [[ -z "$query" ]]; then
    exec "${BASH_SOURCE[0]%/helpers/*}/core/help-messages/helpers/loadHelpers-usage.sh" >&2
  fi

  # Circular dependency protection
  _DR_LOAD_DEPTH=$((_DR_LOAD_DEPTH + 1))
  if [[ $_DR_LOAD_DEPTH -gt $_DR_LOAD_DEPTH_MAX ]]; then
    echo "Error: Maximum helper loading depth exceeded (possible circular dependency)" >&2
    _DR_LOAD_DEPTH=$((_DR_LOAD_DEPTH - 1))
    return 1
  fi

  local DR_CONFIG="${DR_CONFIG:-$HOME/.config/dotrun}"
  local -a matches=()
  local search_level=""
  local verbose="${DR_HELPERS_VERBOSE:-0}"
  local quiet="${DR_HELPERS_QUIET:-0}"

  [[ $verbose -eq 1 ]] && echo "→ Searching for '$query'" >&2

  # Normalize: remove leading 'helpers/' if present
  query="${query#helpers/}"

  # COLLECTION SCOPE: @collection-name loads all from collection
  if [[ "$query" == @* ]]; then
    local collection="${query#@}"
    collection="${collection#[0-9]*-}" # Remove numeric prefix

    local namespace_dir=$(find "$DR_CONFIG/helpers" -maxdepth 1 -type d -name "*-${collection}" 2>/dev/null | sort | head -1)

    if [[ -n "$namespace_dir" ]]; then
      matches=()
      while IFS= read -r line; do
        matches+=("$line")
      done < <(find -L "$namespace_dir" -type f -name "*.sh" 2>/dev/null | sort)
      search_level="collection"
      [[ $verbose -eq 1 ]] && echo "  Found collection: $namespace_dir" >&2
    fi
  fi

  # LEVEL 1: Absolute path
  if [[ ${#matches[@]} -eq 0 ]] && [[ "$query" == /* ]]; then
    [[ $verbose -eq 1 ]] && echo "  Trying: Absolute path" >&2
    if [[ -f "$query" ]]; then
      matches=("$query")
      search_level="absolute"
    fi
  fi

  # LEVEL 2: Exact path with .sh
  if [[ ${#matches[@]} -eq 0 ]] && [[ "$query" == *.sh ]]; then
    [[ $verbose -eq 1 ]] && echo "  Trying: Exact path with .sh" >&2
    local full_path="$DR_CONFIG/helpers/$query"
    if [[ -f "$full_path" ]]; then
      matches=("$full_path")
      search_level="exact"
    fi
  fi

  # LEVEL 3: Add .sh extension
  if [[ ${#matches[@]} -eq 0 ]]; then
    [[ $verbose -eq 1 ]] && echo "  Trying: Path + .sh extension" >&2
    local with_ext="$DR_CONFIG/helpers/${query}.sh"
    if [[ -f "$with_ext" ]]; then
      matches=("$with_ext")
      search_level="extension"
    fi
  fi

  # LEVEL 4: Path search with collection normalization
  if [[ ${#matches[@]} -eq 0 ]] && [[ "$query" == */* ]]; then
    [[ $verbose -eq 1 ]] && echo "  Trying: Path search with normalization" >&2

    # Handle collection/path format (with or without numeric prefix)
    if [[ "$query" =~ ^([a-zA-Z0-9_-]+)/(.+)$ ]]; then
      local collection_part="${BASH_REMATCH[1]}"
      local path_part="${BASH_REMATCH[2]}"

      # Search in sorted order for deterministic results
      matches=()
      while IFS= read -r line; do
        matches+=("$line")
      done < <(
        find -L "$DR_CONFIG/helpers" -type f \
          \( -path "*/[0-9]*-${collection_part}/${path_part}.sh" \
          -o -path "*/[0-9]*-${collection_part}/${path_part}" \
          -o -path "*/${collection_part}/${path_part}.sh" \
          -o -path "*/${collection_part}/${path_part}" \) 2>/dev/null | sort
      )
    else
      matches=()
      while IFS= read -r line; do
        matches+=("$line")
      done < <(
        find -L "$DR_CONFIG/helpers" -type f \
          \( -path "*/$query" -o -path "*/${query}.sh" \) 2>/dev/null | sort
      )
    fi
    [[ ${#matches[@]} -gt 0 ]] && search_level="path"
  fi

  # LEVEL 5: Filename-only (least specific, most permissive)
  if [[ ${#matches[@]} -eq 0 ]]; then
    [[ $verbose -eq 1 ]] && echo "  Trying: Filename-only search" >&2
    local filename="${query##*/}"
    matches=()
    while IFS= read -r line; do
      matches+=("$line")
    done < <(
      find -L "$DR_CONFIG/helpers" -type f \
        \( -name "${filename}.sh" -o -name "${filename}" \) 2>/dev/null | sort
    )
    [[ ${#matches[@]} -gt 0 ]] && search_level="filename"
  fi

  # No matches found
  if [[ ${#matches[@]} -eq 0 ]]; then
    echo "Error: No helpers found matching '$query'" >&2
    echo "Searched in: $DR_CONFIG/helpers" >&2
    [[ $verbose -eq 1 ]] && {
      echo "Tip: Use 'loadHelpers <pattern> --list' to preview matches" >&2
    }
    _DR_LOAD_DEPTH=$((_DR_LOAD_DEPTH - 1))
    return 1
  fi

  # LIST MODE: Preview without loading
  if [[ "$mode" == "--list" ]]; then
    echo "Found ${#matches[@]} helper(s) matching '$query' (level: $search_level):"
    printf "  %s\n" "${matches[@]}"
    _DR_LOAD_DEPTH=$((_DR_LOAD_DEPTH - 1))
    return 0
  fi

  # Warning for multiple matches
  if [[ ${#matches[@]} -gt 1 ]] && [[ $quiet -eq 0 ]]; then
    echo "Warning: Multiple helpers matched '$query' (level: $search_level)" >&2
    printf "  - %s\n" "${matches[@]}" >&2
    echo "Loading all matches..." >&2
  fi

  # Security: Get allowed base directory (using bash 3+ compatible function)
  local allowed_base="$(_dr_realpath "$DR_CONFIG/helpers")"

  # Load all matched helpers
  local loaded=0 failed=0 skipped=0

  for helper in "${matches[@]}"; do
    # CRITICAL: Use canonical path for tracking (prevents re-sourcing via different specs)
    local canonical_path="$(_dr_realpath "$helper")"

    if [[ -z "$canonical_path" ]]; then
      [[ $quiet -eq 0 ]] && echo "Warning: Could not resolve path: $helper" >&2
      failed=$((failed + 1))
      continue
    fi

    # Security: Ensure within allowed directory
    if [[ "$canonical_path" != "$allowed_base"* ]]; then
      echo "Error: Helper outside allowed directory: $helper" >&2
      failed=$((failed + 1))
      continue
    fi

    # Check if already loaded (using canonical path) - bash 3+ compatible
    if _dr_is_loaded "$canonical_path"; then
      [[ $verbose -eq 1 ]] && echo "  Skipping (already loaded): $helper" >&2
      skipped=$((skipped + 1))
      continue
    fi

    # Source the helper
    if source "$canonical_path" 2>/dev/null; then
      _dr_mark_loaded "$canonical_path"
      loaded=$((loaded + 1))
      [[ $verbose -eq 1 ]] && echo "  ✓ Loaded: $helper" >&2
    else
      echo "Error: Failed to source: $helper" >&2
      failed=$((failed + 1))
    fi
  done

  # Summary
  if [[ $quiet -eq 0 ]]; then
    if [[ $loaded -eq 1 ]] && [[ $skipped -eq 0 ]]; then
      echo "✓ Loaded: $(basename "${matches[0]}")" >&2
    elif [[ $loaded -gt 1 ]]; then
      echo "✓ Loaded $loaded helper(s)" >&2
    elif [[ $loaded -eq 0 ]] && [[ $skipped -gt 0 ]]; then
      echo "ℹ All $skipped helper(s) already loaded" >&2
    fi
  fi

  _DR_LOAD_DEPTH=$((_DR_LOAD_DEPTH - 1))
  [[ $failed -gt 0 ]] && return 1
  return 0
}

# Export functions for subshells (bash 3+ compatible)
if [[ $_DR_BASH_MAJOR -ge 4 ]]; then
  # Bash 4+: Export works more reliably
  export -f loadHelpers 2>/dev/null || true
  export -f _dr_is_loaded 2>/dev/null || true
  export -f _dr_mark_loaded 2>/dev/null || true
  export -f _dr_realpath 2>/dev/null || true
else
  # Bash 3: export -f may not work reliably, but try anyway
  export -f loadHelpers 2>/dev/null || true
  export -f _dr_is_loaded 2>/dev/null || true
  export -f _dr_mark_loaded 2>/dev/null || true
  export -f _dr_realpath 2>/dev/null || true
fi
