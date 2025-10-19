#!/usr/bin/env bash
# DotRun Collections System - Copy-Based Architecture
# Version tracking, hash-based modification detection, git-based updates

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016

set -euo pipefail

# ──────────────────────────────────────────────────────────────
# Configuration and Constants
# ──────────────────────────────────────────────────────────────

DR_CONFIG="${DR_CONFIG:-$HOME/.config/dotrun}"
BIN_DIR="${BIN_DIR:-$DR_CONFIG/scripts}"
DR_DATA="${HOME}/.local/share/dotrun"
COLLECTIONS_DIR="$DR_DATA/collections"
COLLECTIONS_CONF="$DR_DATA/collections.conf"
TEMP_DIR="${TMPDIR:-/tmp}/dotrun-$$"

BOLD=$'\e[1m'
CYAN=$'\e[36m'
GREEN=$'\e[32m'
PURPLE=$'\e[35m'
RED=$'\e[31m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
GRAY=$'\e[90m'
RESET=$'\e[0m'

# Features Colors.
## COLOR Scripts
COLOR_S="${GREEN}"
## COLOR Aliases
COLOR_A="${PURPLE}"
## COLOR Configs
COLOR_C="${RED}"
## COLOR Helpers
COLOR_H="${BLUE}"

# Ensure dependencies
source "$DR_CONFIG/helpers/global/pkg.sh"
validatePkg git

# Ensure directories exist
mkdir -p "$COLLECTIONS_DIR"
mkdir -p "$(dirname "$COLLECTIONS_CONF")"

# ──────────────────────────────────────────────────────────────
# Core Utility Functions
# ──────────────────────────────────────────────────────────────

# Calculate SHA256 hash of file (truncated to 8 chars)
calculate_file_hash() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "Error: File not found: $file" >&2
    return 1
  fi

  # Calculate SHA256 and return first 8 characters
  sha256sum "$file" | cut -d' ' -f1 | cut -c1-8
}

# Validate GitHub URL format (supports HTTPS, SSH, and local paths for testing)
validate_github_url() {
  local url="$1"

  # Check for local directory path (for testing)
  if [[ -d "$url" ]]; then
    # Resolve to absolute path
    url="$(cd "$url" && pwd)"

    # Verify it has a dotrun.collection.yml file
    if [[ -f "$url/dotrun.collection.yml" ]]; then
      echo "$url"
      return 0
    else
      echo "Error: Local directory missing dotrun.collection.yml" >&2
      echo "Path: $url" >&2
      return 1
    fi
  fi

  # Check for SSH format
  if [[ "$url" =~ ^git@github\.com:[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+(\.git)?$ ]]; then
    # SSH URL - ensure .git suffix
    url="${url%.git}.git"
    echo "$url"
    return 0
  fi

  # Check for HTTPS format
  if [[ ! "$url" =~ ^https://github\.com/[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+(/)?$ ]]; then
    echo "Error: Invalid GitHub URL format" >&2
    echo "" >&2
    echo "Valid formats:" >&2
    echo "  HTTPS: https://github.com/user/repo" >&2
    echo "  SSH:   git@github.com:user/repo" >&2
    echo "  Local: /path/to/collection (for testing)" >&2
    echo "" >&2
    echo "Common mistakes:" >&2
    echo "  ✗ Missing protocol:     github.com/user/repo" >&2
    echo "  ✗ Wrong protocol:       http://github.com/user/repo" >&2
    echo "  ✗ Extra path:           https://github.com/user/repo/tree/main" >&2
    echo "  ✗ Non-GitHub URL:       https://gitlab.com/user/repo" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  HTTPS (public/private): dr -col add https://github.com/jvPalma/dotrun.git" >&2
    echo "  SSH (private repos):    dr -col add git@github.com:company/private-repo.git" >&2
    echo "  Local (testing):        dr -col add /home/user/dotrun/examples" >&2
    return 1
  fi

  # Normalize HTTPS: remove trailing slash, ensure .git suffix
  url="${url%/}"
  if [[ ! "$url" =~ \.git$ ]]; then
    url="${url}.git"
  fi

  echo "$url"
  return 0
}

# Extract owner/repo from GitHub URL (or "local" for local paths)
extract_repo_name() {
  local url="$1"

  # Handle local directory paths
  if [[ -d "$url" ]]; then
    echo "local/$(basename "$url")"
    return 0
  fi

  # Remove .git suffix if present
  url="${url%.git}"

  # Extract owner/repo from SSH URL format
  if [[ "$url" =~ git@github\.com:([^/]+)/(.+)$ ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    return 0
  fi

  # Extract owner/repo from HTTPS URL format
  if [[ "$url" =~ github\.com/([^/]+)/([^/]+)$ ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    return 0
  fi

  echo "unknown/unknown"
}

# Check if repository is accessible (handles private repos and local paths)
check_repo_access() {
  local url="$1"

  # Handle local directory paths (for testing)
  if [[ -d "$url" ]]; then
    # Just verify it has the required metadata file
    if [[ -f "$url/dotrun.collection.yml" ]]; then
      return 0
    else
      return 1
    fi
  fi

  local owner_repo=$(extract_repo_name "$url")

  # Try using gh CLI first (works for private repos if authenticated)
  if command -v gh &>/dev/null; then
    if gh repo view "$owner_repo" &>/dev/null; then
      return 0
    fi
  fi

  # Fallback: try git ls-remote with timeout (works if credentials configured)
  if timeout 10 git ls-remote "$url" HEAD &>/dev/null; then
    return 0
  fi

  # Repository not accessible
  return 1
}

# ──────────────────────────────────────────────────────────────
# Collections.conf Management
# ──────────────────────────────────────────────────────────────

# Initialize collections.conf if it doesn't exist
init_collections_conf() {
  # Ensure data directory exists
  mkdir -p "$DR_DATA"

  # Run migration before any other operations
  migrate_collections_location

  if [[ ! -f "$COLLECTIONS_CONF" ]]; then
    cat >"$COLLECTIONS_CONF" <<'EOF'
# DotRun Collections Tracking Database
# Stores installed collections with version and import tracking
#
# Format per collection:
# [collection-name]
# url = https://github.com/user/repo.git
# version = 1.0.0
# path = /home/user/.config/dotrun/collections/collection-name
# imported_scripts = file1.sh:hash1,file2.sh:hash2
# imported_aliases = file1.aliases:hash1
# imported_helpers = file1.sh:hash1
# imported_configs = file1.config:hash1

EOF
  fi
}

# Migrate collections from old XDG-non-compliant location to new location
# Old: ~/.config/dotrun/collections/ (wrong - this is for user config)
# New: ~/.local/share/dotrun/collections/ (correct - this is application data)
# This migration runs once and updates all paths in collections.conf
migrate_collections_location() {
  local old_dir="$DR_CONFIG/collections"
  local new_dir="$COLLECTIONS_DIR" # Points to ~/.local/share/dotrun/collections

  # Skip if old location doesn't exist or is a symlink or new already exists
  [[ ! -d "$old_dir" ]] && return 0
  [[ -L "$old_dir" ]] && return 0
  [[ -d "$new_dir" ]] && return 0

  echo "${CYAN}Migrating collections to XDG-compliant location...${RESET}" >&2

  # Ensure parent directory exists
  mkdir -p "$(dirname "$new_dir")"

  # Move the directory
  if ! mv "$old_dir" "$new_dir"; then
    echo "${RED}Error: Failed to move collections from '$old_dir' to '$new_dir'${RESET}" >&2
    echo "${RED}Please check permissions and try again.${RESET}" >&2
    return 1
  fi

  # Update all path entries in collections.conf
  if [[ -f "$COLLECTIONS_CONF" ]]; then
    # Use sed to update paths atomically
    sed "s|$old_dir|$new_dir|g" "$COLLECTIONS_CONF" >"$COLLECTIONS_CONF.tmp" \
      && mv "$COLLECTIONS_CONF.tmp" "$COLLECTIONS_CONF"
  fi

  echo "${GREEN}✓ Collections migrated to: $new_dir${RESET}" >&2
  echo "${GRAY}  Old location: $old_dir${RESET}" >&2
  echo "${GRAY}  New location: $new_dir${RESET}" >&2
  return 0
}

# Check if collection exists in tracking file
collection_exists() {
  local name="$1"

  [[ -f "$COLLECTIONS_CONF" ]] && grep -q "^\[$name\]" "$COLLECTIONS_CONF"
}

# Get collection property from tracking file
get_collection_property() {
  local name="$1"
  local property="$2"

  if [[ ! -f "$COLLECTIONS_CONF" ]]; then
    return 1
  fi

  # Use awk to extract property value from INI section
  awk -v section="$name" -v key="$property" '
    /^\[.*\]/ {
      in_section = ($0 == "[" section "]")
    }
    in_section && $0 ~ "^" key " *= *" {
      sub("^" key " *= *", "")
      print
      exit
    }
  ' "$COLLECTIONS_CONF"
}

# Set collection property in tracking file
set_collection_property() {
  local name="$1"
  local property="$2"
  local value="$3"

  init_collections_conf

  # Check if section exists
  if ! collection_exists "$name"; then
    # Add new section
    echo "" >>"$COLLECTIONS_CONF"
    echo "[$name]" >>"$COLLECTIONS_CONF"
  fi

  # Use awk to update or add property
  local tmpfile=$(mktemp)
  awk -v section="$name" -v key="$property" -v val="$value" '
    /^\[.*\]/ {
      if (in_section && !found) {
        print key " = " val
        found = 1
      }
      in_section = ($0 == "[" section "]")
      print
      next
    }
    in_section && $0 ~ "^" key " *= *" {
      print key " = " val
      found = 1
      next
    }
    { print }
    END {
      if (in_section && !found) {
        print key " = " val
      }
    }
  ' "$COLLECTIONS_CONF" >"$tmpfile"

  mv "$tmpfile" "$COLLECTIONS_CONF"
}

# Remove collection from tracking file
remove_collection_from_conf() {
  local name="$1"

  if [[ ! -f "$COLLECTIONS_CONF" ]]; then
    return 0
  fi

  # Use awk to remove entire section
  local tmpfile=$(mktemp)
  awk -v section="$name" '
    /^\[.*\]/ {
      in_section = ($0 == "[" section "]")
      if (!in_section) print
      next
    }
    !in_section { print }
  ' "$COLLECTIONS_CONF" >"$tmpfile"

  mv "$tmpfile" "$COLLECTIONS_CONF"
}

# List all collection names from tracking file
list_collection_names() {
  if [[ ! -f "$COLLECTIONS_CONF" ]]; then
    return 0
  fi

  grep '^\[' "$COLLECTIONS_CONF" | tr -d '[]'
}

# Find similar collection names (simple fuzzy matching using substring matching)
find_similar_collection_names() {
  local query="$1"
  local max_suggestions="${2:-3}"

  if [[ ! -f "$COLLECTIONS_CONF" ]]; then
    return 0
  fi

  local all_collections=($(list_collection_names))
  local suggestions=()

  # Simple substring matching: collections that contain the query or vice versa
  for collection in "${all_collections[@]}"; do
    # Case-insensitive substring match
    local query_lower="${query,,}"
    local collection_lower="${collection,,}"

    if [[ "$collection_lower" == *"$query_lower"* ]] || [[ "$query_lower" == *"$collection_lower"* ]]; then
      suggestions+=("$collection")
    fi
  done

  # Limit to max_suggestions
  if [[ ${#suggestions[@]} -gt 0 ]]; then
    printf '%s\n' "${suggestions[@]}" | head -n "$max_suggestions"
  fi
}

# ──────────────────────────────────────────────────────────────
# Git Operations
# ──────────────────────────────────────────────────────────────

# Clone repository to temporary location (or copy for local paths)
git_clone_temp() {
  local url="$1"
  local temp_dir="$TEMP_DIR/clone-$(date +%s)"

  mkdir -p "$temp_dir"

  # Handle local directory paths (for testing)
  if [[ -d "$url" ]]; then
    echo "${GRAY}Copying local directory (testing mode)${RESET}" >&2
    echo "Path: $url" >&2
    if ! cp -r "$url/"* "$temp_dir/"; then
      echo "Error: Failed to copy local directory" >&2
      echo "Source: $url" >&2
      echo "Destination: $temp_dir" >&2
      rm -rf "$temp_dir"
      return 1
    fi
    echo "$temp_dir"
    return 0
  fi

  echo "Cloning repository to temporary location..." >&2
  echo "URL: $url" >&2

  # Clone with timeout (errors go to stderr, not captured in return value)
  if ! timeout 30 git clone --quiet "$url" "$temp_dir" >&2; then
    local exit_code=$?
    echo "" >&2
    echo "Error: Failed to clone repository" >&2
    echo "URL: $url" >&2
    echo "" >&2

    if [[ $exit_code -eq 124 ]]; then
      echo "Reason: Operation timed out after 30 seconds" >&2
      echo "" >&2
      echo "Possible causes:" >&2
      echo "  • Network connectivity issues" >&2
      echo "  • Very large repository" >&2
      echo "  • Slow connection" >&2
      echo "" >&2
      echo "Troubleshooting steps:" >&2
      echo "  1. Check your internet connection" >&2
      echo "  2. Try again later" >&2
      echo "  3. Clone manually first: git clone $url ~/temp-clone" >&2
      echo "  4. Then add from local path: dr -col add ~/temp-clone" >&2
    elif [[ $exit_code -eq 128 ]]; then
      echo "Reason: Repository not found or authentication required" >&2
      echo "" >&2
      echo "Common causes:" >&2
      echo "  • Repository doesn't exist" >&2
      echo "  • Repository is private and not authenticated" >&2
      echo "  • Incorrect URL format" >&2
      echo "  • Network/firewall blocking access" >&2
      echo "" >&2
      echo "Troubleshooting steps:" >&2
      echo "  1. Verify the repository exists: visit URL in browser" >&2
      echo "  2. For private repos, use SSH: git@github.com:user/repo.git" >&2
      echo "  3. Configure SSH keys: ssh-keygen && gh ssh-key add ~/.ssh/id_rsa.pub" >&2
      echo "  4. Or authenticate with gh: gh auth login" >&2
      echo "  5. Test access manually: git ls-remote $url" >&2
    else
      echo "Reason: Git clone failed with exit code $exit_code" >&2
      echo "" >&2
      echo "Troubleshooting steps:" >&2
      echo "  1. Check git is installed: git --version" >&2
      echo "  2. Test repository access: git ls-remote $url" >&2
      echo "  3. Check disk space: df -h" >&2
      echo "  4. Try manual clone: git clone $url ~/test-clone" >&2
    fi

    rm -rf "$temp_dir"
    return 1
  fi

  echo "$temp_dir"
}

# Clone repository to collections directory (or copy for local paths)
git_clone_persistent() {
  local url="$1"
  local name="$2"
  local dest="$COLLECTIONS_DIR/$name"

  if [[ -d "$dest" ]]; then
    echo "${YELLOW}Warning: Collection directory already exists: $dest${RESET}" >&2
    return 1
  fi

  echo "Installing collection to $dest..." >&2

  # Handle local directory paths (for testing)
  if [[ -d "$url" ]]; then
    echo "${GRAY}Using local directory (testing mode)${RESET}" >&2
    if ! cp -r "$url" "$dest"; then
      echo "Error: Failed to copy local directory" >&2
      echo "Source: $url" >&2
      echo "Destination: $dest" >&2
      rm -rf "$dest"
      return 1
    fi
    echo "$dest"
    return 0
  fi

  # Clone with timeout and visible errors
  if ! timeout 60 git clone --quiet "$url" "$dest" >&2; then
    local exit_code=$?
    echo "" >&2
    echo "Error: Failed to install collection" >&2
    echo "URL: $url" >&2
    echo "Destination: $dest" >&2
    echo "" >&2

    if [[ $exit_code -eq 124 ]]; then
      echo "Reason: Operation timed out after 60 seconds" >&2
      echo "" >&2
      echo "This may indicate:" >&2
      echo "  • Large repository size" >&2
      echo "  • Network connectivity issues" >&2
      echo "" >&2
      echo "Recovery options:" >&2
      echo "  1. Clone manually: git clone $url $dest" >&2
      echo "  2. Try again with better connection" >&2
      echo "  3. Contact repository owner about size" >&2
    elif [[ $exit_code -eq 128 ]]; then
      echo "Reason: Repository not found or authentication required" >&2
      echo "" >&2
      echo "Recovery options:" >&2
      echo "  1. Verify repository URL is correct" >&2
      echo "  2. For private repos, ensure SSH keys are configured" >&2
      echo "  3. Run: ssh -T git@github.com (to test SSH access)" >&2
      echo "  4. Or authenticate: gh auth login" >&2
    else
      echo "Reason: Git clone failed with exit code $exit_code" >&2
      echo "" >&2
      echo "Troubleshooting:" >&2
      echo "  1. Check available disk space: df -h $(dirname $dest)" >&2
      echo "  2. Verify write permissions: ls -ld $(dirname $dest)" >&2
      echo "  3. Try manual clone to diagnose: git clone $url $dest" >&2
    fi

    rm -rf "$dest"
    return 1
  fi

  echo "$dest"
}

# Fetch updates for collection (skips local non-git directories)
git_fetch_collection() {
  local collection_dir="$1"

  # Handle local non-git directories (for testing)
  # These are treated as static snapshots that don't receive updates
  if [[ ! -d "$collection_dir/.git" ]]; then
    # If it's a local path (has dotrun.collection.yml but no .git), skip fetch
    if [[ -f "$collection_dir/dotrun.collection.yml" ]]; then
      # Local directory, no updates available
      return 0
    fi

    echo "Error: Not a git repository: $collection_dir" >&2
    echo "Directory: $collection_dir" >&2
    echo "" >&2
    echo "The collection directory may have been corrupted or moved." >&2
    echo "" >&2
    echo "Recovery options:" >&2
    echo "  1. Remove and re-add the collection" >&2
    echo "  2. Check if the directory exists: ls -la $collection_dir" >&2
    return 1
  fi

  cd "$collection_dir" || return 1

  # Attempt fetch with timeout and error capture
  local fetch_output=$(timeout 30 git fetch origin --tags 2>&1)
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo "Error: Failed to fetch updates from remote" >&2
    echo "Repository: $collection_dir" >&2
    echo "" >&2

    if [[ $exit_code -eq 124 ]]; then
      echo "Reason: Operation timed out after 30 seconds" >&2
      echo "" >&2
      echo "Possible causes:" >&2
      echo "  • Network connectivity issues" >&2
      echo "  • Remote server not responding" >&2
      echo "" >&2
      echo "Troubleshooting:" >&2
      echo "  1. Check internet connection" >&2
      echo "  2. Try again later" >&2
      echo "  3. Test remote access: cd $collection_dir && git fetch origin --dry-run" >&2
    elif [[ "$fetch_output" =~ "Could not resolve host" ]] || [[ "$fetch_output" =~ "unable to access" ]]; then
      echo "Reason: Cannot reach remote repository" >&2
      echo "" >&2
      echo "Possible causes:" >&2
      echo "  • Network connectivity issues" >&2
      echo "  • DNS resolution problems" >&2
      echo "  • Remote repository moved or deleted" >&2
      echo "" >&2
      echo "Troubleshooting:" >&2
      echo "  1. Check internet: ping github.com" >&2
      echo "  2. Verify remote URL: cd $collection_dir && git remote -v" >&2
      echo "  3. Update remote if changed: cd $collection_dir && git remote set-url origin <new-url>" >&2
    elif [[ "$fetch_output" =~ "Permission denied" ]] || [[ "$fetch_output" =~ "Authentication failed" ]]; then
      echo "Reason: Authentication failed" >&2
      echo "" >&2
      echo "Possible causes:" >&2
      echo "  • SSH keys not configured or expired" >&2
      echo "  • Repository became private" >&2
      echo "  • Access revoked" >&2
      echo "" >&2
      echo "Troubleshooting:" >&2
      echo "  1. Test SSH access: ssh -T git@github.com" >&2
      echo "  2. Reconfigure SSH keys: gh ssh-key add ~/.ssh/id_rsa.pub" >&2
      echo "  3. Or authenticate: gh auth login" >&2
    else
      echo "Reason: Git fetch failed with exit code $exit_code" >&2
      echo "Output: $fetch_output" >&2
      echo "" >&2
      echo "Troubleshooting:" >&2
      echo "  1. Check git status: cd $collection_dir && git status" >&2
      echo "  2. Try manual fetch: cd $collection_dir && git fetch origin" >&2
      echo "  3. Check remote URL: cd $collection_dir && git remote -v" >&2
    fi

    return 1
  fi

  return 0
}

# List git tags for collection
git_list_tags() {
  local collection_dir="$1"

  if [[ ! -d "$collection_dir/.git" ]]; then
    return 1
  fi

  cd "$collection_dir" || return 1
  git tag -l | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | sort -V
}

# Get latest version tag
git_get_latest_tag() {
  local collection_dir="$1"

  git_list_tags "$collection_dir" | tail -1
}

# Checkout specific version tag
git_checkout_tag() {
  local collection_dir="$1"
  local tag="$2"

  if [[ ! -d "$collection_dir/.git" ]]; then
    echo "Error: Not a git repository: $collection_dir" >&2
    return 1
  fi

  cd "$collection_dir" || return 1
  if ! git checkout --quiet "$tag" 2>/dev/null; then
    echo "Error: Failed to checkout tag: $tag" >&2
    return 1
  fi
}

# Compare two semantic versions (returns 0 if v1 < v2, 1 if v1 >= v2)
version_less_than() {
  local v1="$1"
  local v2="$2"

  # Remove 'v' prefix if present
  v1="${v1#v}"
  v2="${v2#v}"

  # Use sort -V to compare versions
  if [[ "$(printf '%s\n' "$v1" "$v2" | sort -V | head -1)" == "$v1" ]] && [[ "$v1" != "$v2" ]]; then
    return 0 # v1 < v2
  else
    return 1 # v1 >= v2
  fi
}

# ──────────────────────────────────────────────────────────────
# Metadata Parsing (YAML - simplified parser)
# ──────────────────────────────────────────────────────────────

# Parse YAML field from dotrun.collection.yml
parse_collection_metadata() {
  local collection_dir="$1"
  local field="$2"
  local metadata_file="$collection_dir/dotrun.collection.yml"

  if [[ ! -f "$metadata_file" ]]; then
    # Try .yaml extension
    metadata_file="$collection_dir/dotrun.collection.yaml"
    if [[ ! -f "$metadata_file" ]]; then
      echo "Error: Collection metadata file not found" >&2
      echo "" >&2
      echo "Expected file location:" >&2
      echo "  $collection_dir/dotrun.collection.yml" >&2
      echo "  or" >&2
      echo "  $collection_dir/dotrun.collection.yaml" >&2
      echo "" >&2
      echo "This repository is not a valid DotRun collection." >&2
      echo "" >&2
      echo "To create a DotRun collection:" >&2
      echo "  1. Navigate to your repository directory" >&2
      echo "  2. Run: dr -col init" >&2
      echo "  3. Follow the prompts to create metadata" >&2
      echo "  4. Commit and push: git add . && git commit -m 'Initialize collection'" >&2
      return 1
    fi
  fi

  # Simple YAML parser for key: value format
  grep "^$field:" "$metadata_file" | sed "s/^$field:[[:space:]]*//" | tr -d '"' | tr -d "'"
}

# Validate collection metadata
validate_collection_metadata() {
  local collection_dir="$1"

  local required_fields=("name" "version" "description" "author" "repository")
  local missing_fields=()

  for field in "${required_fields[@]}"; do
    local value=$(parse_collection_metadata "$collection_dir" "$field")
    if [[ -z "$value" ]]; then
      missing_fields+=("$field")
    fi
  done

  if [[ ${#missing_fields[@]} -gt 0 ]]; then
    echo "Error: Invalid collection metadata - missing required fields" >&2
    echo "" >&2
    echo "Missing fields:" >&2
    for field in "${missing_fields[@]}"; do
      echo "  • $field" >&2
    done
    echo "" >&2
    echo "Required metadata format (dotrun.collection.yml):" >&2
    echo "" >&2
    echo "  name: my-collection           # Unique identifier (alphanumeric, dashes, underscores)" >&2
    echo "  version: 1.0.0                # Semantic version (X.Y.Z)" >&2
    echo "  description: Brief summary    # What this collection provides" >&2
    echo "  author: Your Name             # Collection creator" >&2
    echo "  repository: https://github.com/user/repo  # Git repository URL" >&2
    echo "" >&2
    echo "Optional fields:" >&2
    echo "  license: MIT                  # License identifier" >&2
    echo "  homepage: https://example.com # Documentation URL" >&2
    echo "  dependencies: []              # Other required collections" >&2
    echo "" >&2
    echo "To create valid metadata:" >&2
    echo "  1. Run: dr -col init" >&2
    echo "  2. Or manually create dotrun.collection.yml with all required fields" >&2
    return 1
  fi

  return 0
}

# ──────────────────────────────────────────────────────────────
# Namespace Management
# ──────────────────────────────────────────────────────────────

# Get next available numeric prefix for collection namespace
# Scans existing directories with NN- prefix and returns next number
get_next_collection_prefix() {
  local target_dir="$1" # e.g., "$BIN_DIR" for scripts

  # Find all directories with NN- prefix pattern
  local max_num=0
  if [[ -d "$target_dir" ]]; then
    while IFS= read -r dir; do
      local basename=$(basename "$dir")
      if [[ "$basename" =~ ^([0-9]{2})- ]]; then
        local num="${BASH_REMATCH[1]}"
        num=$((10#$num)) # Remove leading zero for arithmetic
        if [[ $num -gt $max_num ]]; then
          max_num=$num
        fi
      fi
    done < <(find "$target_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  fi

  # Return next number (01 if none exist)
  local next_num=$((max_num + 1))
  printf "%02d" "$next_num"
}

# Find namespace directory for a collection by pattern matching
# Searches for directories matching *-collection-name in target directory
# For new imports (no directory exists), generates next available prefix
#
# @arg $1 collection_name The name of the collection (e.g., "dotrun-anc")
# @arg $2 resource_type The type of resource ("scripts", "aliases", "helpers", "configs")
# @stdout The namespace directory name (e.g., "05-dotrun-anc")
# @return 0 on unique match or new prefix generated
#         1 if base directory doesn't exist
#         2 if ambiguous (multiple directories match)
find_collection_namespace() {
  local collection_name="$1"
  local resource_type="$2"
  local target_dir=""
  local -a matches

  # Determine target directory based on resource type
  case "$resource_type" in
    scripts) target_dir="$BIN_DIR" ;;
    aliases) target_dir="$DR_CONFIG/aliases" ;;
    helpers) target_dir="$DR_CONFIG/helpers" ;;
    configs) target_dir="$DR_CONFIG/configs" ;;
    *)
      echo "Error: Invalid resource type: $resource_type" >&2
      return 1
      ;;
  esac

  # Base directory doesn't exist yet
  if [[ ! -d "$target_dir" ]]; then
    # Generate new namespace for first import
    local prefix=$(get_next_collection_prefix "$target_dir")
    echo "${prefix}-${collection_name}"
    return 0
  fi

  # Search for existing directory matching *-collection-name pattern
  mapfile -t matches < <(find "$target_dir" -mindepth 1 -maxdepth 1 -type d -name "*-${collection_name}" 2>/dev/null)

  if [[ ${#matches[@]} -eq 0 ]]; then
    # Not found - generate new namespace for import
    local prefix=$(get_next_collection_prefix "$target_dir")
    echo "${prefix}-${collection_name}"
    return 0
  elif [[ ${#matches[@]} -gt 1 ]]; then
    # Ambiguous match - user has multiple directories for same collection
    echo "Error: Found multiple directories for collection '${collection_name}' (${resource_type}):" >&2
    printf "  %s\n" "${matches[@]}" >&2
    echo "Please resolve the conflict by removing or renaming duplicates." >&2
    return 2
  fi

  # Unique match found - return just the directory name
  basename "${matches[0]}"
  return 0
}

# ──────────────────────────────────────────────────────────────
# File Operations with Hashing
# ──────────────────────────────────────────────────────────────

# Copy file with hash calculation
copy_with_hash() {
  local source="$1"
  local dest="$2"

  if [[ ! -f "$source" ]]; then
    echo "Error: Source file not found: $source" >&2
    return 1
  fi

  # Check read permission on source
  if [[ ! -r "$source" ]]; then
    echo "Error: Cannot read source file (permission denied)" >&2
    echo "File: $source" >&2
    echo "" >&2
    echo "Troubleshooting:" >&2
    echo "  1. Check file permissions: ls -la $source" >&2
    echo "  2. Fix permissions: chmod +r $source" >&2
    return 1
  fi

  # Create destination directory if needed
  local dest_dir=$(dirname "$dest")
  if ! mkdir -p "$dest_dir" 2>/dev/null; then
    echo "Error: Cannot create destination directory (permission denied)" >&2
    echo "Directory: $dest_dir" >&2
    echo "" >&2
    echo "Troubleshooting:" >&2
    echo "  1. Check directory permissions: ls -ld $(dirname $dest_dir)" >&2
    echo "  2. Verify ownership: ls -ld $(dirname $dest_dir)" >&2
    echo "  3. Fix permissions: chmod +w $(dirname $dest_dir)" >&2
    echo "  4. Or use sudo if this is a system directory" >&2
    return 1
  fi

  # Check write permission on destination directory
  if [[ ! -w "$dest_dir" ]]; then
    echo "Error: Cannot write to destination directory (permission denied)" >&2
    echo "Directory: $dest_dir" >&2
    echo "" >&2
    echo "Troubleshooting:" >&2
    echo "  1. Check directory permissions: ls -ld $dest_dir" >&2
    echo "  2. Fix permissions: chmod +w $dest_dir" >&2
    return 1
  fi

  # Copy file
  if ! cp "$source" "$dest" 2>/dev/null; then
    echo "Error: Failed to copy file (permission denied or disk full)" >&2
    echo "Source: $source" >&2
    echo "Destination: $dest" >&2
    echo "" >&2
    echo "Troubleshooting:" >&2
    echo "  1. Check disk space: df -h $(dirname $dest)" >&2
    echo "  2. Check destination permissions: ls -la $dest" >&2
    echo "  3. Try manual copy: cp $source $dest" >&2
    return 1
  fi

  # Calculate and return hash
  calculate_file_hash "$dest"
}

# Copy file and make executable (for scripts)
copy_script_with_hash() {
  local source="$1"
  local dest="$2"

  local hash=$(copy_with_hash "$source" "$dest")
  local result=$?

  if [[ $result -eq 0 ]]; then
    if ! chmod +x "$dest" 2>/dev/null; then
      echo "Error: Failed to make script executable (permission denied)" >&2
      echo "File: $dest" >&2
      echo "" >&2
      echo "Troubleshooting:" >&2
      echo "  1. Check file permissions: ls -la $dest" >&2
      echo "  2. Try manual chmod: chmod +x $dest" >&2
      echo "  3. Verify file ownership: ls -l $dest" >&2
      return 1
    fi
  fi

  echo "$hash"
  return $result
}

# Cleanup temp directory
cleanup_temp() {
  if [[ -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}

# Trap to ensure cleanup on exit
trap cleanup_temp EXIT

# ──────────────────────────────────────────────────────────────
# Resource Import Functions
# ──────────────────────────────────────────────────────────────

# Import script with copy and hash tracking (namespaced to collection directory)
import_script() {
  local collection_name="$1"
  local script_file="$2"
  local collection_dir="$COLLECTIONS_DIR/$collection_name"
  local source="$collection_dir/scripts/$script_file"

  # Get namespace directory for this collection
  local namespace=$(find_collection_namespace "$collection_name" "scripts")
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to get namespace for collection" >&2
    return 1
  fi

  # Build destination path with namespace (preserves subdirectories)
  local dest="$BIN_DIR/$namespace/$script_file"

  if [[ ! -f "$source" ]]; then
    echo "Error: Script not found: $script_file" >&2
    return 1
  fi

  # Check if destination already exists
  if [[ -f "$dest" ]]; then
    echo "" >&2
    echo "$script_file already exists in $namespace/" >&2
    read -p "[O]verwrite  [R]ename  [S]kip: " choice
    case "${choice,,}" in
      o | overwrite) ;;
      r | rename)
        local base="${script_file%.sh}"
        local counter=1
        while [[ -f "$BIN_DIR/$namespace/$base-$counter.sh" ]]; do
          ((counter++))
        done
        dest="$BIN_DIR/$namespace/$base-$counter.sh"
        script_file="$base-$counter.sh"
        echo "Renaming to: $script_file" >&2
        ;;
      s | skip | *)
        echo "Skipped: $script_file" >&2
        return 0
        ;;
    esac
  fi

  local hash=$(copy_script_with_hash "$source" "$dest")
  if [[ $? -eq 0 ]]; then
    echo "✓ Imported script: $namespace/$script_file" >&2
    # Store basename in tracking (not full namespace path)
    echo "$script_file:$hash"
  else
    return 1
  fi
}

# Import alias file with copy and hash tracking (namespaced to collection directory)
import_alias() {
  local collection_name="$1"
  local alias_file="$2"
  local collection_dir="$COLLECTIONS_DIR/$collection_name"
  local source="$collection_dir/aliases/$alias_file"

  # Get namespace directory for this collection
  local namespace=$(find_collection_namespace "$collection_name" "aliases")
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to get namespace for collection" >&2
    return 1
  fi

  # Build destination path with namespace (preserves subdirectories)
  local dest="$DR_CONFIG/aliases/$namespace/$alias_file"

  if [[ ! -f "$source" ]]; then
    echo "Error: Alias file not found: $alias_file" >&2
    return 1
  fi

  # Check if destination already exists
  if [[ -f "$dest" ]]; then
    echo "" >&2
    echo "$alias_file already exists in $namespace/" >&2
    read -p "[O]verwrite  [R]ename  [S]kip: " choice
    case "${choice,,}" in
      o | overwrite) ;;
      r | rename)
        local base="${alias_file%.aliases}"
        local counter=1
        while [[ -f "$DR_CONFIG/aliases/$namespace/$base-$counter.aliases" ]]; do
          ((counter++))
        done
        dest="$DR_CONFIG/aliases/$namespace/$base-$counter.aliases"
        alias_file="$base-$counter.aliases"
        echo "Renaming to: $alias_file" >&2
        ;;
      s | skip | *)
        echo "Skipped: $alias_file" >&2
        return 0
        ;;
    esac
  fi

  local hash=$(copy_with_hash "$source" "$dest")
  if [[ $? -eq 0 ]]; then
    echo "✓ Imported alias: $namespace/$alias_file" >&2
    # Store basename in tracking (not full namespace path)
    echo "$alias_file:$hash"
  else
    return 1
  fi
}

# Import helper file with copy and hash tracking (namespaced to collection directory)
import_helper() {
  local collection_name="$1"
  local helper_file="$2"
  local collection_dir="$COLLECTIONS_DIR/$collection_name"
  local source="$collection_dir/helpers/$helper_file"

  # Get namespace directory for this collection
  local namespace=$(find_collection_namespace "$collection_name" "helpers")
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to get namespace for collection" >&2
    return 1
  fi

  # Build destination path with namespace (preserves subdirectories)
  local dest="$DR_CONFIG/helpers/$namespace/$helper_file"

  if [[ ! -f "$source" ]]; then
    echo "Error: Helper file not found: $helper_file" >&2
    return 1
  fi

  # Check if destination already exists
  if [[ -f "$dest" ]]; then
    echo "" >&2
    echo "$helper_file already exists in $namespace/" >&2
    read -p "[O]verwrite  [R]ename  [S]kip: " choice
    case "${choice,,}" in
      o | overwrite) ;;
      r | rename)
        local base="${helper_file%.sh}"
        local counter=1
        while [[ -f "$DR_CONFIG/helpers/$namespace/$base-$counter.sh" ]]; do
          ((counter++))
        done
        dest="$DR_CONFIG/helpers/$namespace/$base-$counter.sh"
        helper_file="$base-$counter.sh"
        echo "Renaming to: $helper_file" >&2
        ;;
      s | skip | *)
        echo "Skipped: $helper_file" >&2
        return 0
        ;;
    esac
  fi

  local hash=$(copy_with_hash "$source" "$dest")
  if [[ $? -eq 0 ]]; then
    echo "✓ Imported helper: $namespace/$helper_file" >&2
    # Store basename in tracking (not full namespace path)
    echo "$helper_file:$hash"
  else
    return 1
  fi
}

# Import config file with copy and hash tracking (namespaced to collection directory)
import_config() {
  local collection_name="$1"
  local config_file="$2"
  local collection_dir="$COLLECTIONS_DIR/$collection_name"
  local source="$collection_dir/configs/$config_file"

  # Get namespace directory for this collection
  local namespace=$(find_collection_namespace "$collection_name" "configs")
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to get namespace for collection" >&2
    return 1
  fi

  # Build destination path with namespace (preserves subdirectories)
  local dest="$DR_CONFIG/configs/$namespace/$config_file"

  if [[ ! -f "$source" ]]; then
    echo "Error: Config file not found: $config_file" >&2
    return 1
  fi

  # Check if destination already exists
  if [[ -f "$dest" ]]; then
    echo "" >&2
    echo "$config_file already exists in $namespace/" >&2
    read -p "[O]verwrite  [R]ename  [S]kip: " choice
    case "${choice,,}" in
      o | overwrite) ;;
      r | rename)
        local base="${config_file%.config}"
        local counter=1
        while [[ -f "$DR_CONFIG/configs/$namespace/$base-$counter.config" ]]; do
          ((counter++))
        done
        dest="$DR_CONFIG/configs/$namespace/$base-$counter.config"
        config_file="$base-$counter.config"
        echo "Renaming to: $config_file" >&2
        ;;
      s | skip | *)
        echo "Skipped: $config_file" >&2
        return 0
        ;;
    esac
  fi

  local hash=$(copy_with_hash "$source" "$dest")
  if [[ $? -eq 0 ]]; then
    echo "✓ Imported config: $namespace/$config_file" >&2
    # Store basename in tracking (not full namespace path)
    echo "$config_file:$hash"
  else
    return 1
  fi
}

# Interactive resource selection menu
select_resources_to_import() {
  local collection_name="$1"
  local collection_dir="$COLLECTIONS_DIR/$collection_name"
  local imported_scripts=()
  local imported_aliases=()
  local imported_helpers=()
  local imported_configs=()

  # Discover namespace directories dynamically (filesystem is source of truth)
  local namespace_scripts=$(find_collection_namespace "$collection_name" "scripts" 2>/dev/null)
  local namespace_aliases=$(find_collection_namespace "$collection_name" "aliases" 2>/dev/null)
  local namespace_helpers=$(find_collection_namespace "$collection_name" "helpers" 2>/dev/null)
  local namespace_configs=$(find_collection_namespace "$collection_name" "configs" 2>/dev/null)

  echo "" >&2
  echo "Available resources in ${BOLD}${CYAN}$collection_name${RESET}:" >&2
  echo "" >&2

  # List available resources by type
  local has_scripts=false
  local has_aliases=false
  local has_helpers=false
  local has_configs=false

  if [[ -d "$collection_dir/scripts" ]] && [[ -n "$(ls -A "$collection_dir/scripts" 2>/dev/null)" ]]; then
    echo "${COLOR_S}Scripts:${RESET}" >&2
    find "$collection_dir/scripts" -name "*.sh" -type f | sort | while read -r file; do
      local rel_path="${file#$collection_dir/scripts/}"
      local mark=""
      # Check filesystem instead of tracking (handles user deletions)
      if [[ -f "$BIN_DIR/$namespace_scripts/$rel_path" ]]; then
        mark=" ${GREEN}✓"
      fi
      echo "  - ${COLOR_S}$rel_path${RESET}$mark${RESET}" >&2
    done
    has_scripts=true
  fi

  if [[ -d "$collection_dir/aliases" ]] && [[ -n "$(ls -A "$collection_dir/aliases" 2>/dev/null)" ]]; then
    echo "${COLOR_A}Aliases:${RESET}" >&2
    find "$collection_dir/aliases" -type f | sort | while read -r file; do
      local rel_path="${file#$collection_dir/aliases/}"
      local mark=""
      # Check filesystem instead of tracking (handles user deletions)
      if [[ -f "$DR_CONFIG/aliases/$namespace_aliases/$rel_path" ]]; then
        mark=" ${GREEN}✓"
      fi
      echo "  - ${COLOR_A}$rel_path${RESET}$mark${RESET}" >&2
    done
    has_aliases=true
  fi

  if [[ -d "$collection_dir/helpers" ]] && [[ -n "$(ls -A "$collection_dir/helpers" 2>/dev/null)" ]]; then
    echo "${COLOR_H}Helpers:${RESET}" >&2
    find "$collection_dir/helpers" -type f | sort | while read -r file; do
      local rel_path="${file#$collection_dir/helpers/}"
      local mark=""
      # Check filesystem instead of tracking (handles user deletions)
      if [[ -f "$DR_CONFIG/helpers/$namespace_helpers/$rel_path" ]]; then
        mark=" ${GREEN}✓"
      fi
      echo "  - ${COLOR_H}$rel_path${RESET}$mark${RESET}" >&2
    done
    has_helpers=true
  fi

  if [[ -d "$collection_dir/configs" ]] && [[ -n "$(ls -A "$collection_dir/configs" 2>/dev/null)" ]]; then
    echo "${COLOR_C}Configs:${RESET}" >&2
    find "$collection_dir/configs" -type f | sort | while read -r file; do
      local rel_path="${file#$collection_dir/configs/}"
      local mark=""
      # Check filesystem instead of tracking (handles user deletions)
      if [[ -f "$DR_CONFIG/configs/$namespace_configs/$rel_path" ]]; then
        mark=" ${GREEN}✓"
      fi
      echo "  - ${COLOR_C}$rel_path${RESET}$mark${RESET}" >&2
    done
    has_configs=true
  fi

  echo "${RESET}" >&2
  echo "Import resources:" >&2
  echo "  [${CYAN}a${RESET}] ${CYAN}All resources${RESET}" >&2
  echo "  [${GREEN}s${RESET}] ${GREEN}Scripts${RESET} only" >&2
  echo "  [${PURPLE}l${RESET}] ${PURPLE}Aliases${RESET} only" >&2
  echo "  [${BLUE}h${RESET}] ${BLUE}Helpers${RESET} only" >&2
  echo "  [${RED}c${RESET}] ${RED}Configs${RESET} only" >&2
  echo "  [${YELLOW}n${RESET}] ${YELLOW}None${RESET} (skip import)" >&2
  echo "" >&2
  read -p "Choice: " choice

  echo "" >&2

  case "${choice,,}" in
    a | all)
      # Import all resources
      if [[ "$has_scripts" == "true" ]]; then
        echo "Importing ${GREEN}Scripts${RESET}..." >&2
        while read -r file; do
          local rel_path="${file#$collection_dir/scripts/}"
          local hash_result=$(import_script "$collection_name" "$rel_path")
          if [[ -n "$hash_result" ]] && [[ ! "$hash_result" =~ ^Error ]]; then
            imported_scripts+=("$hash_result")
          fi
        done < <(find "$collection_dir/scripts" -name "*.sh" -type f)
      fi
      if [[ "$has_aliases" == "true" ]]; then
        echo "Importing ${PURPLE}Aliases${RESET}..." >&2
        while read -r file; do
          local rel_path="${file#$collection_dir/aliases/}"
          local hash_result=$(import_alias "$collection_name" "$rel_path")
          if [[ -n "$hash_result" ]] && [[ ! "$hash_result" =~ ^Error ]]; then
            imported_aliases+=("$hash_result")
          fi
        done < <(find "$collection_dir/aliases" -type f)
      fi
      if [[ "$has_helpers" == "true" ]]; then
        echo "Importing ${BLUE}Helpers${RESET}..." >&2
        while read -r file; do
          local rel_path="${file#$collection_dir/helpers/}"
          local hash_result=$(import_helper "$collection_name" "$rel_path")
          if [[ -n "$hash_result" ]] && [[ ! "$hash_result" =~ ^Error ]]; then
            imported_helpers+=("$hash_result")
          fi
        done < <(find "$collection_dir/helpers" -type f)
      fi
      if [[ "$has_configs" == "true" ]]; then
        echo "Importing ${RED}Configs${RESET}..." >&2
        while read -r file; do
          local rel_path="${file#$collection_dir/configs/}"
          local hash_result=$(import_config "$collection_name" "$rel_path")
          if [[ -n "$hash_result" ]] && [[ ! "$hash_result" =~ ^Error ]]; then
            imported_configs+=("$hash_result")
          fi
        done < <(find "$collection_dir/configs" -type f)
      fi
      ;;
    s | scripts)
      if [[ "$has_scripts" == "true" ]]; then
        echo "Importing ${GREEN}Scripts${RESET}..." >&2
        while read -r file; do
          local rel_path="${file#$collection_dir/scripts/}"
          local hash_result=$(import_script "$collection_name" "$rel_path")
          if [[ -n "$hash_result" ]] && [[ ! "$hash_result" =~ ^Error ]]; then
            imported_scripts+=("$hash_result")
          fi
        done < <(find "$collection_dir/scripts" -name "*.sh" -type f)
      fi
      ;;
    l | aliases)
      if [[ "$has_aliases" == "true" ]]; then
        echo "Importing ${PURPLE}Aliases${RESET}..." >&2
        while read -r file; do
          local rel_path="${file#$collection_dir/aliases/}"
          local hash_result=$(import_alias "$collection_name" "$rel_path")
          if [[ -n "$hash_result" ]] && [[ ! "$hash_result" =~ ^Error ]]; then
            imported_aliases+=("$hash_result")
          fi
        done < <(find "$collection_dir/aliases" -type f)
      fi
      ;;
    h | helpers)
      if [[ "$has_helpers" == "true" ]]; then
        echo "Importing ${BLUE}Helpers${RESET}..." >&2
        while read -r file; do
          local rel_path="${file#$collection_dir/helpers/}"
          local hash_result=$(import_helper "$collection_name" "$rel_path")
          if [[ -n "$hash_result" ]] && [[ ! "$hash_result" =~ ^Error ]]; then
            imported_helpers+=("$hash_result")
          fi
        done < <(find "$collection_dir/helpers" -type f)
      fi
      ;;
    c | configs)
      if [[ "$has_configs" == "true" ]]; then
        echo "Importing ${RED}Configs${RESET}..." >&2
        while read -r file; do
          local rel_path="${file#$collection_dir/configs/}"
          local hash_result=$(import_config "$collection_name" "$rel_path")
          if [[ -n "$hash_result" ]] && [[ ! "$hash_result" =~ ^Error ]]; then
            imported_configs+=("$hash_result")
          fi
        done < <(find "$collection_dir/configs" -type f)
      fi
      ;;
    n | none | *)
      echo "Skipping resource import" >&2
      ;;
  esac

  # Return imported file lists (colon-separated for storage in collections.conf)
  # Note: No color codes here - these are parsed by grep in cmd_col_browse
  echo "SCRIPTS:$(
    IFS=,
    echo "${imported_scripts[*]}"
  )"
  echo "ALIASES:$(
    IFS=,
    echo "${imported_aliases[*]}"
  )"
  echo "HELPERS:$(
    IFS=,
    echo "${imported_helpers[*]}"
  )"
  echo "CONFIGS:$(
    IFS=,
    echo "${imported_configs[*]}"
  )"
}

# ──────────────────────────────────────────────────────────────
# Conflict Resolution Functions
# ──────────────────────────────────────────────────────────────

# Show diff between two files
show_file_diff() {
  local file1="$1"
  local file2="$2"
  local label1="$3"
  local label2="$4"

  if command -v diff &>/dev/null; then
    echo "--- $label1"
    echo "+++ $label2"
    diff -u "$file1" "$file2" || true
  else
    echo "diff command not available"
  fi
}

# Show 3-way diff (original, user's, collection's)
show_3way_diff() {
  local original_hash="$1"
  local user_file="$2"
  local collection_file="$3"
  local collection_name="$4"
  local rel_path="$5"

  echo ""
  echo "=== 3-Way Comparison ==="
  echo ""
  echo "Original (from collection v$original_hash):"
  echo "User's version (modified):"
  head -20 "$user_file" 2>/dev/null || echo "(file not readable)"
  echo ""
  echo "Collection's new version:"
  head -20 "$collection_file" 2>/dev/null || echo "(file not readable)"
  echo ""

  if command -v diff &>/dev/null; then
    echo "Diff (User vs Collection):"
    show_file_diff "$user_file" "$collection_file" "Your version" "Collection version"
  fi
  echo ""
}

# Attempt 3-way merge using git merge-file
attempt_3way_merge() {
  local base_file="$1"
  local user_file="$2"
  local collection_file="$3"

  if ! command -v git &>/dev/null; then
    echo "Error: git not available for merge" >&2
    return 1
  fi

  # Create temp file for merged result
  local temp_merged=$(mktemp)
  cp "$user_file" "$temp_merged"

  # Attempt merge
  if git merge-file -p "$temp_merged" "$base_file" "$collection_file" >"$user_file" 2>/dev/null; then
    rm -f "$temp_merged"
    echo "✓ Merged successfully"
    return 0
  else
    # Merge had conflicts
    git merge-file "$temp_merged" "$base_file" "$collection_file" 2>/dev/null || true
    cp "$temp_merged" "$user_file"
    rm -f "$temp_merged"
    echo "⚠️  Merge completed with conflicts - please review manually"
    return 0
  fi
}

# Handle update for unmodified file
handle_unmodified_file_update() {
  local collection_name="$1"
  local rel_path="$2"
  local resource_type="$3" # scripts, aliases, helpers, configs
  local collection_dir="$4"

  local source="$collection_dir/$resource_type/$rel_path"
  local dest=""

  case "$resource_type" in
    scripts)
      # Get namespace for scripts
      local namespace=$(find_collection_namespace "$collection_name" "scripts")
      dest="$BIN_DIR/$namespace/$rel_path"
      ;;
    aliases)
      # Get namespace for aliases
      local namespace=$(find_collection_namespace "$collection_name" "aliases")
      dest="$DR_CONFIG/aliases/$namespace/$rel_path"
      ;;
    helpers)
      # Get namespace for helpers
      local namespace=$(find_collection_namespace "$collection_name" "helpers")
      dest="$DR_CONFIG/helpers/$namespace/$rel_path"
      ;;
    configs)
      # Get namespace for configs
      local namespace=$(find_collection_namespace "$collection_name" "configs")
      dest="$DR_CONFIG/configs/$namespace/$rel_path"
      ;;
  esac

  echo ""
  echo "$rel_path: UNMODIFIED"
  read -p "  [U]pdate  [D]iff  [S]kip: " choice

  case "${choice,,}" in
    u | update)
      if [[ "$resource_type" == "scripts" ]]; then
        local hash=$(copy_script_with_hash "$source" "$dest")
      else
        local hash=$(copy_with_hash "$source" "$dest")
      fi
      echo "  ✓ Updated: $rel_path"
      echo "$rel_path:$hash"
      return 0
      ;;
    d | diff)
      show_file_diff "$dest" "$source" "Current" "New"
      # Ask again after showing diff
      return handle_unmodified_file_update "$collection_name" "$rel_path" "$resource_type" "$collection_dir"
      ;;
    s | skip | *)
      echo "  Skipped: $rel_path"
      return 1
      ;;
  esac
}

# Handle update for modified file (conflict resolution)
handle_modified_file_update() {
  local collection_name="$1"
  local rel_path="$2"
  local resource_type="$3"
  local collection_dir="$4"
  local original_hash="$5"

  local source="$collection_dir/$resource_type/$rel_path"
  local dest=""

  case "$resource_type" in
    scripts)
      # Get namespace for scripts
      local namespace=$(find_collection_namespace "$collection_name" "scripts")
      dest="$BIN_DIR/$namespace/$rel_path"
      ;;
    aliases)
      # Get namespace for aliases
      local namespace=$(find_collection_namespace "$collection_name" "aliases")
      dest="$DR_CONFIG/aliases/$namespace/$rel_path"
      ;;
    helpers)
      # Get namespace for helpers
      local namespace=$(find_collection_namespace "$collection_name" "helpers")
      dest="$DR_CONFIG/helpers/$namespace/$rel_path"
      ;;
    configs)
      # Get namespace for configs
      local namespace=$(find_collection_namespace "$collection_name" "configs")
      dest="$DR_CONFIG/configs/$namespace/$rel_path"
      ;;
  esac

  echo ""
  echo "$rel_path: ⚠️  LOCAL CHANGES DETECTED"
  echo "  Your version: Modified locally"
  echo ""
  echo "  [K]eep yours (skip update)"
  echo "  [O]verwrite with collection version"
  echo "  [D]iff (show changes)"
  echo "  [B]ackup yours, then overwrite"
  echo ""
  read -p "  Choice: " choice

  case "${choice,,}" in
    k | keep)
      echo "  Kept local version: $rel_path"
      # Return original hash to preserve tracking
      echo "$rel_path:$original_hash"
      return 0
      ;;
    o | overwrite)
      if [[ "$resource_type" == "scripts" ]]; then
        local hash=$(copy_script_with_hash "$source" "$dest")
      else
        local hash=$(copy_with_hash "$source" "$dest")
      fi
      echo "  ✓ Overwritten with collection version: $rel_path"
      echo "$rel_path:$hash"
      return 0
      ;;
    d | diff)
      show_3way_diff "$original_hash" "$dest" "$source" "$collection_name" "$rel_path"
      # Ask again after showing diff
      return handle_modified_file_update "$collection_name" "$rel_path" "$resource_type" "$collection_dir" "$original_hash"
      ;;
    b | backup)
      local backup="$dest.bak"
      cp "$dest" "$backup"
      echo "  ✓ Backed up to: $backup"
      if [[ "$resource_type" == "scripts" ]]; then
        local hash=$(copy_script_with_hash "$source" "$dest")
      else
        local hash=$(copy_with_hash "$source" "$dest")
      fi
      echo "  ✓ Overwritten with collection version: $rel_path"
      echo "$rel_path:$hash"
      return 0
      ;;
    *)
      echo "  Invalid choice, keeping local version"
      echo "$rel_path:$original_hash"
      return 0
      ;;
  esac
}

# Handle import of new file
handle_new_file_import() {
  local collection_name="$1"
  local rel_path="$2"
  local resource_type="$3"
  local collection_dir="$4"

  local source="$collection_dir/$resource_type/$rel_path"

  echo ""
  echo "$rel_path: NEW FILE"
  read -p "  [I]mport  [V]iew  [S]kip: " choice

  case "${choice,,}" in
    i | import)
      # Use existing import functions which handle conflicts
      case "$resource_type" in
        scripts)
          import_script "$collection_name" "$rel_path"
          return $?
          ;;
        aliases)
          import_alias "$collection_name" "$rel_path"
          return $?
          ;;
        helpers)
          import_helper "$collection_name" "$rel_path"
          return $?
          ;;
        configs)
          import_config "$collection_name" "$rel_path"
          return $?
          ;;
      esac
      ;;
    v | view)
      echo ""
      echo "=== Content of $rel_path ==="
      head -50 "$source" 2>/dev/null || echo "(file not readable)"
      echo "=== End of file preview ==="
      # Ask again after showing content
      return handle_new_file_import "$collection_name" "$rel_path" "$resource_type" "$collection_dir"
      ;;
    s | skip | *)
      echo "  Skipped: $rel_path"
      return 1
      ;;
  esac
}

# ──────────────────────────────────────────────────────────────
# Update Detection Functions
# ──────────────────────────────────────────────────────────────

# Detect changes between current version and latest version
detect_collection_changes() {
  local collection_name="$1"
  local collection_dir="$2"
  local current_version="$3"
  local latest_version="$4"

  local imported_scripts=$(get_collection_property "$collection_name" "imported_scripts")
  local imported_aliases=$(get_collection_property "$collection_name" "imported_aliases")
  local imported_helpers=$(get_collection_property "$collection_name" "imported_helpers")
  local imported_configs=$(get_collection_property "$collection_name" "imported_configs")

  local modified_scripts=()
  local new_scripts=()
  local removed_scripts=()
  local modified_aliases=()
  local new_aliases=()
  local removed_aliases=()
  local modified_helpers=()
  local new_helpers=()
  local removed_helpers=()
  local modified_configs=()
  local new_configs=()
  local removed_configs=()

  # Save current directory
  local orig_dir=$(pwd)
  cd "$collection_dir" || return 1

  # Get list of files at latest version
  git checkout --quiet "v$latest_version" 2>/dev/null || git checkout --quiet "$latest_version" 2>/dev/null

  # Check previously imported scripts for modifications and removals
  if [[ -n "$imported_scripts" ]]; then
    while IFS=',' read -ra SCRIPTS; do
      for item in "${SCRIPTS[@]}"; do
        local filename="${item%%:*}"
        if [[ -n "$filename" ]]; then
          if [[ -f "scripts/$filename" ]]; then
            # File exists in new version - check if content changed
            local new_hash=$(calculate_file_hash "scripts/$filename")
            local old_hash="${item##*:}"
            if [[ "$new_hash" != "$old_hash" ]]; then
              modified_scripts+=("$filename")
            fi
          else
            # File no longer exists in new version - mark as removed
            removed_scripts+=("$filename")
          fi
        fi
      done
    done <<<"$imported_scripts"
  fi

  # Check for new scripts not previously imported
  if [[ -d "scripts" ]]; then
    while IFS= read -r -d '' file; do
      local rel_path="${file#scripts/}"
      # Check if this was previously imported
      if [[ ! "$imported_scripts" =~ $rel_path: ]]; then
        new_scripts+=("$rel_path")
      fi
    done < <(find scripts -name "*.sh" -type f -print0)
  fi

  # Check aliases for modifications and removals
  if [[ -n "$imported_aliases" ]]; then
    while IFS=',' read -ra ALIASES; do
      for item in "${ALIASES[@]}"; do
        local filename="${item%%:*}"
        if [[ -n "$filename" ]]; then
          if [[ -f "aliases/$filename" ]]; then
            local new_hash=$(calculate_file_hash "aliases/$filename")
            local old_hash="${item##*:}"
            if [[ "$new_hash" != "$old_hash" ]]; then
              modified_aliases+=("$filename")
            fi
          else
            # File no longer exists in new version - mark as removed
            removed_aliases+=("$filename")
          fi
        fi
      done
    done <<<"$imported_aliases"
  fi

  # Check for new aliases
  if [[ -d "aliases" ]]; then
    while IFS= read -r -d '' file; do
      local rel_path="${file#aliases/}"
      if [[ ! "$imported_aliases" =~ $rel_path: ]]; then
        new_aliases+=("$rel_path")
      fi
    done < <(find aliases -type f -print0)
  fi

  # Check helpers for modifications and removals
  if [[ -n "$imported_helpers" ]]; then
    while IFS=',' read -ra HELPERS; do
      for item in "${HELPERS[@]}"; do
        local filename="${item%%:*}"
        if [[ -n "$filename" ]]; then
          if [[ -f "helpers/$filename" ]]; then
            local new_hash=$(calculate_file_hash "helpers/$filename")
            local old_hash="${item##*:}"
            if [[ "$new_hash" != "$old_hash" ]]; then
              modified_helpers+=("$filename")
            fi
          else
            # File no longer exists in new version - mark as removed
            removed_helpers+=("$filename")
          fi
        fi
      done
    done <<<"$imported_helpers"
  fi

  # Check for new helpers
  if [[ -d "helpers" ]]; then
    while IFS= read -r -d '' file; do
      local rel_path="${file#helpers/}"
      if [[ ! "$imported_helpers" =~ $rel_path: ]]; then
        new_helpers+=("$rel_path")
      fi
    done < <(find helpers -type f -print0)
  fi

  # Check configs for modifications and removals
  if [[ -n "$imported_configs" ]]; then
    while IFS=',' read -ra CONFIGS; do
      for item in "${CONFIGS[@]}"; do
        local filename="${item%%:*}"
        if [[ -n "$filename" ]]; then
          if [[ -f "configs/$filename" ]]; then
            local new_hash=$(calculate_file_hash "configs/$filename")
            local old_hash="${item##*:}"
            if [[ "$new_hash" != "$old_hash" ]]; then
              modified_configs+=("$filename")
            fi
          else
            # File no longer exists in new version - mark as removed
            removed_configs+=("$filename")
          fi
        fi
      done
    done <<<"$imported_configs"
  fi

  # Check for new configs
  if [[ -d "configs" ]]; then
    while IFS= read -r -d '' file; do
      local rel_path="${file#configs/}"
      if [[ ! "$imported_configs" =~ $rel_path: ]]; then
        new_configs+=("$rel_path")
      fi
    done < <(find configs -type f -print0)
  fi

  # Return to original directory
  cd "$orig_dir" || return 1

  # Output results grouped by type
  echo "SCRIPTS_MODIFIED:$(
    IFS=,
    echo "${modified_scripts[*]}"
  )"
  echo "SCRIPTS_NEW:$(
    IFS=,
    echo "${new_scripts[*]}"
  )"
  echo "SCRIPTS_REMOVED:$(
    IFS=,
    echo "${removed_scripts[*]}"
  )"
  echo "ALIASES_MODIFIED:$(
    IFS=,
    echo "${modified_aliases[*]}"
  )"
  echo "ALIASES_NEW:$(
    IFS=,
    echo "${new_aliases[*]}"
  )"
  echo "ALIASES_REMOVED:$(
    IFS=,
    echo "${removed_aliases[*]}"
  )"
  echo "HELPERS_MODIFIED:$(
    IFS=,
    echo "${modified_helpers[*]}"
  )"
  echo "HELPERS_NEW:$(
    IFS=,
    echo "${new_helpers[*]}"
  )"
  echo "HELPERS_REMOVED:$(
    IFS=,
    echo "${removed_helpers[*]}"
  )"
  echo "CONFIGS_MODIFIED:$(
    IFS=,
    echo "${modified_configs[*]}"
  )"
  echo "CONFIGS_NEW:$(
    IFS=,
    echo "${new_configs[*]}"
  )"
  echo "CONFIGS_REMOVED:$(
    IFS=,
    echo "${removed_configs[*]}"
  )"
}

# ──────────────────────────────────────────────────────────────
# Command Implementations
# ──────────────────────────────────────────────────────────────

cmd_col_init() {
  local current_dir=$(basename "$PWD")
  local metadata_file="dotrun.collection.yml"

  # Check if already initialized
  if [[ -f "$metadata_file" ]]; then
    echo "${YELLOW}⚠️  Collection already initialized: ${CYAN}$metadata_file${RESET} ${YELLOW}exists${RESET}"
    echo "${GRAY}To reinitialize, delete the file first or edit it manually${RESET}"
    return 1
  fi

  echo "${BOLD}Initializing DotRun collection in current directory...${RESET}"
  echo ""

  # Prompt for collection name (default to directory name)
  local collection_name
  read -p "Collection name [${CYAN}$current_dir${RESET}]: " collection_name
  collection_name="${collection_name:-$current_dir}"

  # Validate collection name (alphanumeric, dash, underscore only)
  if [[ ! "$collection_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "${RED}Error: Collection name must be alphanumeric with dashes/underscores only${RESET}" >&2
    return 1
  fi

  # Prompt for description
  local description
  read -p "Description: " description
  if [[ -z "$description" ]]; then
    echo "${RED}Error: Description is required${RESET}" >&2
    return 1
  fi

  # Prompt for author
  local author
  read -p "Author: " author
  if [[ -z "$author" ]]; then
    echo "${RED}Error: Author is required${RESET}" >&2
    return 1
  fi

  # Prompt for repository URL (optional, can be added later)
  local repository
  read -p "Repository URL ${GRAY}(optional)${RESET}: " repository

  # Create dotrun.collection.yml
  cat >"$metadata_file" <<EOF
# DotRun Collection Metadata
# This file defines collection properties for version tracking and distribution

name: $collection_name
version: 0.1.0
description: $description
author: $author
repository: ${repository:-""}

# Optional fields:
# license: MIT
# homepage: https://example.com
# dependencies: []
EOF

  echo ""
  echo "${GREEN}✓ Created ${CYAN}$metadata_file${RESET}"

  # Create resource directories
  local dirs=("scripts" "aliases" "helpers" "configs")
  local dir_colors=("${COLOR_S}" "${COLOR_A}" "${COLOR_H}" "${COLOR_C}")
  local created_dirs=()
  local created_dir_names=()

  for i in "${!dirs[@]}"; do
    local dir="${dirs[$i]}"
    if [[ ! -d "$dir" ]]; then
      mkdir -p "$dir"
      created_dirs+=("${dir_colors[$i]}$dir${RESET}")
      created_dir_names+=("$dir")
    fi
  done

  if [[ ${#created_dirs[@]} -gt 0 ]]; then
    echo -n "${GREEN}✓ Created directories:${RESET}"
    for dir in "${created_dirs[@]}"; do
      echo -n " $dir"
    done
    echo ""
  fi

  # Display existing directories that were preserved
  local existing_dirs=()
  for i in "${!dirs[@]}"; do
    local dir="${dirs[$i]}"
    if [[ -d "$dir" ]] && [[ ! " ${created_dir_names[@]} " =~ " ${dir} " ]]; then
      existing_dirs+=("${dir_colors[$i]}$dir${RESET}")
    fi
  done

  if [[ ${#existing_dirs[@]} -gt 0 ]]; then
    echo -n "${YELLOW}⚠️  Preserved existing directories:${RESET}"
    for dir in "${existing_dirs[@]}"; do
      echo -n " $dir"
    done
    echo ""
  fi

  echo ""
  echo "${BOLD}${GREEN}Collection initialized successfully!${RESET}"
  echo ""
  echo "${BOLD}Next steps:${RESET}"
  echo "  ${GRAY}1.${RESET} Add your ${COLOR_S}scripts${RESET} to ${COLOR_S}scripts/${RESET}"
  echo "  ${GRAY}2.${RESET} Add your ${COLOR_A}aliases${RESET} to ${COLOR_A}aliases/${RESET}"
  echo "  ${GRAY}3.${RESET} Add your ${COLOR_H}helpers${RESET} to ${COLOR_H}helpers/${RESET}"
  echo "  ${GRAY}4.${RESET} Add your ${COLOR_C}configs${RESET} to ${COLOR_C}configs/${RESET}"
  echo "  ${GRAY}5.${RESET} Update version in ${CYAN}$metadata_file${RESET}"
  echo "  ${GRAY}6.${RESET} Commit to git and tag with version: ${CYAN}git tag v0.1.0${RESET}"
  echo "  ${GRAY}7.${RESET} Push to GitHub for sharing"
  echo ""
  echo "${BOLD}Structure:${RESET}"
  echo "  ${CYAN}$collection_name/${RESET}"
  echo "  ├── ${CYAN}dotrun.collection.yml${RESET}"
  echo "  ├── ${COLOR_S}scripts/${RESET}"
  echo "  ├── ${COLOR_A}aliases/${RESET}"
  echo "  ├── ${COLOR_H}helpers/${RESET}"
  echo "  └── ${COLOR_C}configs/${RESET}"
}

cmd_col_add() {
  local url="$1"

  # Validate URL argument
  if [[ -z "$url" ]]; then
    echo "${RED}Error: GitHub URL required${RESET}" >&2
    echo "${GRAY}Usage: ${CYAN}dr -col add <github-url>${RESET}" >&2
    return 1
  fi

  # Validate and normalize GitHub URL
  url=$(validate_github_url "$url")
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  echo "${BOLD}Adding collection from: ${CYAN}$url${RESET}" >&2

  # Check repository access before cloning
  echo "${GRAY}Checking repository access...${RESET}" >&2
  if ! check_repo_access "$url"; then
    local owner_repo=$(extract_repo_name "$url")
    echo "" >&2
    echo "${RED}Error: Cannot access repository: ${CYAN}$owner_repo${RESET}" >&2
    echo "" >&2
    echo "${YELLOW}This may be because:${RESET}" >&2
    echo "  ${GRAY}1.${RESET} Repository is private and you're not authenticated" >&2
    echo "  ${GRAY}2.${RESET} Repository doesn't exist" >&2
    echo "  ${GRAY}3.${RESET} URL is incorrect" >&2
    echo "" >&2
    echo "${BOLD}For private repositories, use one of these options:${RESET}" >&2
    echo "" >&2
    echo "${BOLD}Option 1:${RESET} Use SSH URL ${GRAY}(requires SSH keys configured)${RESET}" >&2
    echo "  ${CYAN}dr -col add git@github.com:$owner_repo.git${RESET}" >&2
    echo "" >&2
    echo "${BOLD}Option 2:${RESET} Authenticate with GitHub CLI" >&2
    echo "  ${CYAN}gh auth login${RESET}" >&2
    echo "  ${CYAN}dr -col add $url${RESET}" >&2
    echo "" >&2
    echo "${BOLD}Option 3:${RESET} Configure Git credentials" >&2
    echo "  ${CYAN}git config --global credential.helper store${RESET}" >&2
    echo "  ${GRAY}# Then manually clone once to save credentials${RESET}" >&2
    echo "" >&2
    echo "${BOLD}Option 4:${RESET} Use local path ${GRAY}(if repo already cloned)${RESET}" >&2
    echo "  ${CYAN}dr -col add ~/dotrun-anc${RESET}" >&2
    return 1
  fi

  echo "${GREEN}✓ Repository is accessible${RESET}" >&2

  # Clone to temporary location to read metadata
  local temp_clone=$(git_clone_temp "$url")
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  # Validate collection metadata
  if ! validate_collection_metadata "$temp_clone"; then
    rm -rf "$temp_clone"
    return 1
  fi

  # Extract collection name and version
  local collection_name=$(parse_collection_metadata "$temp_clone" "name")
  local collection_version=$(parse_collection_metadata "$temp_clone" "version")

  if [[ -z "$collection_name" ]] || [[ -z "$collection_version" ]]; then
    echo "${RED}Error: Failed to parse collection metadata${RESET}" >&2
    rm -rf "$temp_clone"
    return 1
  fi

  # Check for name conflicts
  if collection_exists "$collection_name"; then
    echo "${RED}Error: Collection ${CYAN}'$collection_name'${RED} already exists${RESET}" >&2
    local existing_url=$(get_collection_property "$collection_name" "url")
    local existing_version=$(get_collection_property "$collection_name" "version")
    echo "${YELLOW}Existing collection:${RESET}" >&2
    echo "  ${GRAY}URL:${RESET} ${CYAN}$existing_url${RESET}" >&2
    echo "  ${GRAY}Version:${RESET} ${CYAN}$existing_version${RESET}" >&2
    echo "" >&2
    echo "${GRAY}Run ${CYAN}'dr -col list'${GRAY} to view all installed collections${RESET}" >&2
    echo "${GRAY}Run ${CYAN}'dr -col remove $collection_name'${GRAY} to remove existing collection first${RESET}" >&2
    rm -rf "$temp_clone"
    return 1
  fi

  # Clean up temp clone
  rm -rf "$temp_clone"

  # Clone to permanent location
  local collection_dir=$(git_clone_persistent "$url" "$collection_name")
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  echo "${GREEN}✓ Cloned collection to: ${GRAY}$collection_dir${RESET}" >&2

  # Create collection entry in tracking database
  # Note: Namespaces are now discovered dynamically, not stored
  init_collections_conf
  set_collection_property "$collection_name" "url" "$url"
  set_collection_property "$collection_name" "version" "$collection_version"
  set_collection_property "$collection_name" "path" "$collection_dir"

  # Display interactive resource selection menu
  local import_results=$(select_resources_to_import "$collection_name")

  # Parse import results (use -f2- to keep hashes which also contain colons)
  local imported_scripts=$(echo "$import_results" | grep "^SCRIPTS:" | cut -d: -f2-)
  local imported_aliases=$(echo "$import_results" | grep "^ALIASES:" | cut -d: -f2-)
  local imported_helpers=$(echo "$import_results" | grep "^HELPERS:" | cut -d: -f2-)
  local imported_configs=$(echo "$import_results" | grep "^CONFIGS:" | cut -d: -f2-)

  # Update imported file lists in collections.conf
  # (Collection entry and namespaces were already created before import)
  set_collection_property "$collection_name" "imported_scripts" "$imported_scripts"
  set_collection_property "$collection_name" "imported_aliases" "$imported_aliases"
  set_collection_property "$collection_name" "imported_helpers" "$imported_helpers"
  set_collection_property "$collection_name" "imported_configs" "$imported_configs"

  echo ""
  echo "${BOLD}${GREEN}✓ Collection ${CYAN}'$collection_name'${GREEN} (v$collection_version) installed successfully${RESET}"
  echo ""
  echo "${GRAY}Run ${CYAN}'dr -col list'${GRAY} to view installed collections${RESET}"
  echo "${GRAY}Run ${CYAN}'dr -col sync'${GRAY} to check for updates${RESET}"
}

cmd_col_list() {
  if [[ ! -f "$COLLECTIONS_CONF" ]]; then
    echo "No collections installed"
    echo ""
    echo "Run 'dr -col add <github-url>' to install a collection"
    return 0
  fi

  local collections=($(list_collection_names))

  if [[ ${#collections[@]} -eq 0 ]]; then
    echo "No collections installed"
    echo ""
    echo "Run 'dr -col add <github-url>' to install a collection"
    return 0
  fi

  echo "Installed Collections:"
  echo ""

  local index=1
  for collection in "${collections[@]}"; do
    local version=$(get_collection_property "$collection" "version")
    local url=$(get_collection_property "$collection" "url")
    local imported_scripts=$(get_collection_property "$collection" "imported_scripts")
    local imported_aliases=$(get_collection_property "$collection" "imported_aliases")
    local imported_helpers=$(get_collection_property "$collection" "imported_helpers")
    local imported_configs=$(get_collection_property "$collection" "imported_configs")

    # Count imported resources (comma-separated list)
    local script_count=0
    local alias_count=0
    local helper_count=0
    local config_count=0

    if [[ -n "$imported_scripts" ]]; then
      script_count=$(echo "$imported_scripts" | tr ',' '\n' | grep -c ':' || echo 0)
    fi

    if [[ -n "$imported_aliases" ]]; then
      alias_count=$(echo "$imported_aliases" | tr ',' '\n' | grep -c ':' || echo 0)
    fi

    if [[ -n "$imported_helpers" ]]; then
      helper_count=$(echo "$imported_helpers" | tr ',' '\n' | grep -c ':' || echo 0)
    fi

    if [[ -n "$imported_configs" ]]; then
      config_count=$(echo "$imported_configs" | tr ',' '\n' | grep -c ':' || echo 0)
    fi

    # Build imported resources summary
    local imported_parts=()
    if [[ $script_count -gt 0 ]]; then
      if [[ $script_count -eq 1 ]]; then
        imported_parts+=(" ${COLOR_S}$script_count script")
      else
        imported_parts+=(" ${COLOR_S}$script_count scripts")
      fi
    fi

    if [[ $alias_count -gt 0 ]]; then
      if [[ $alias_count -eq 1 ]]; then
        imported_parts+=(" ${COLOR_A}$alias_count alias")
      else
        imported_parts+=(" ${COLOR_A}$alias_count aliases")
      fi
    fi

    if [[ $helper_count -gt 0 ]]; then
      if [[ $helper_count -eq 1 ]]; then
        imported_parts+=(" ${COLOR_C}$helper_count helper")
      else
        imported_parts+=(" ${COLOR_C}$helper_count helpers")
      fi
    fi

    if [[ $config_count -gt 0 ]]; then
      if [[ $config_count -eq 1 ]]; then
        imported_parts+=(" ${COLOR_H}$config_count config")
      else
        imported_parts+=(" ${COLOR_H}$config_count configs")
      fi
    fi

    local imported_summary=""
    if [[ ${#imported_parts[@]} -gt 0 ]]; then
      imported_summary=$(
        IFS=', '
        echo "${imported_parts[*]}"
      )
    else
      imported_summary="${GRAY}none"
    fi

    echo "${GRAY}$index. ${BOLD}${CYAN}$collection ${RESET}(v$version)"
    echo "   ${GRAY}URL: ${BLUE}$url${RESET}"
    echo "   ${GRAY}Imported: $imported_summary${RESET}"
    echo ""

    ((index++))
  done
}

cmd_col_sync() {
  if [[ ! -f "$COLLECTIONS_CONF" ]]; then
    echo "${GRAY}No collections installed${RESET}"
    echo ""
    echo "${GRAY}Run ${CYAN}'dr -col add <github-url>'${GRAY} to install a collection${RESET}"
    return 0
  fi

  local collections=($(list_collection_names))

  if [[ ${#collections[@]} -eq 0 ]]; then
    echo "${GRAY}No collections installed${RESET}"
    echo ""
    echo "${GRAY}Run ${CYAN}'dr -col add <github-url>'${GRAY} to install a collection${RESET}"
    return 0
  fi

  echo "${BOLD}Checking for updates...${RESET}"
  echo ""

  local updates_available=false
  local orig_dir=$(pwd)

  for collection in "${collections[@]}"; do
    local current_version=$(get_collection_property "$collection" "version")
    local collection_path=$(get_collection_property "$collection" "path")

    # Fetch updates
    echo -n "${CYAN}$collection${RESET} ${GRAY}(v$current_version)${RESET}... "

    if [[ ! -d "$collection_path" ]]; then
      echo "${RED}Error: Collection directory not found: ${GRAY}$collection_path${RESET}" >&2
      continue
    fi

    # Fetch from git (errors are already detailed by git_fetch_collection)
    if ! git_fetch_collection "$collection_path" >&2; then
      echo "" >&2
      echo "${RED}Skipping ${CYAN}'$collection'${RED} due to fetch failure${RESET}" >&2
      echo "${GRAY}Fix the issue and run ${CYAN}'dr -col sync'${GRAY} again${RESET}" >&2
      echo "" >&2
      continue
    fi

    # Get latest version tag
    local latest_tag=$(git_get_latest_tag "$collection_path")

    if [[ -z "$latest_tag" ]]; then
      echo "${GRAY}no version tags found${RESET}"
      continue
    fi

    # Remove 'v' prefix for comparison
    local latest_version="${latest_tag#v}"

    # Detect changes (check even if up-to-date to show available imports)
    local changes=$(detect_collection_changes "$collection" "$collection_path" "$current_version" "$latest_version")

    # Compare versions
    if version_less_than "$current_version" "$latest_version"; then
      echo ""
      echo "  ${YELLOW}Update available:${RESET} ${GRAY}v$current_version${RESET} → ${GREEN}v$latest_version${RESET}"
      updates_available=true

      # Parse all changes by type and status
      local scripts_modified=$(echo "$changes" | grep "^SCRIPTS_MODIFIED:" | cut -d: -f2-)
      local scripts_new=$(echo "$changes" | grep "^SCRIPTS_NEW:" | cut -d: -f2-)
      local scripts_removed=$(echo "$changes" | grep "^SCRIPTS_REMOVED:" | cut -d: -f2-)
      local aliases_modified=$(echo "$changes" | grep "^ALIASES_MODIFIED:" | cut -d: -f2-)
      local aliases_new=$(echo "$changes" | grep "^ALIASES_NEW:" | cut -d: -f2-)
      local aliases_removed=$(echo "$changes" | grep "^ALIASES_REMOVED:" | cut -d: -f2-)
      local helpers_modified=$(echo "$changes" | grep "^HELPERS_MODIFIED:" | cut -d: -f2-)
      local helpers_new=$(echo "$changes" | grep "^HELPERS_NEW:" | cut -d: -f2-)
      local helpers_removed=$(echo "$changes" | grep "^HELPERS_REMOVED:" | cut -d: -f2-)
      local configs_modified=$(echo "$changes" | grep "^CONFIGS_MODIFIED:" | cut -d: -f2-)
      local configs_new=$(echo "$changes" | grep "^CONFIGS_NEW:" | cut -d: -f2-)
      local configs_removed=$(echo "$changes" | grep "^CONFIGS_REMOVED:" | cut -d: -f2-)

      # Display Scripts section
      if [[ -n "$scripts_modified" || -n "$scripts_new" || -n "$scripts_removed" ]]; then
        echo "  ${COLOR_S}Scripts${RESET}"
        if [[ -n "$scripts_modified" ]]; then
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${YELLOW}@${RESET} $file"
              fi
            done
          done <<<"$scripts_modified"
        fi
        if [[ -n "$scripts_new" ]]; then
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${GREEN}+${RESET} $file"
              fi
            done
          done <<<"$scripts_new"
        fi
        if [[ -n "$scripts_removed" ]]; then
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${RED}-${RESET} $file"
              fi
            done
          done <<<"$scripts_removed"
        fi
      fi

      # Display Aliases section
      if [[ -n "$aliases_modified" || -n "$aliases_new" || -n "$aliases_removed" ]]; then
        echo "  ${COLOR_A}Aliases${RESET}"
        if [[ -n "$aliases_modified" ]]; then
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${YELLOW}@${RESET} $file"
              fi
            done
          done <<<"$aliases_modified"
        fi
        if [[ -n "$aliases_new" ]]; then
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${GREEN}+${RESET} $file"
              fi
            done
          done <<<"$aliases_new"
        fi
        if [[ -n "$aliases_removed" ]]; then
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${RED}-${RESET} $file"
              fi
            done
          done <<<"$aliases_removed"
        fi
      fi

      # Display Helpers section
      if [[ -n "$helpers_modified" || -n "$helpers_new" || -n "$helpers_removed" ]]; then
        echo "  ${COLOR_H}Helpers${RESET}"
        if [[ -n "$helpers_modified" ]]; then
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${YELLOW}@${RESET} $file"
              fi
            done
          done <<<"$helpers_modified"
        fi
        if [[ -n "$helpers_new" ]]; then
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${GREEN}+${RESET} $file"
              fi
            done
          done <<<"$helpers_new"
        fi
        if [[ -n "$helpers_removed" ]]; then
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${RED}-${RESET} $file"
              fi
            done
          done <<<"$helpers_removed"
        fi
      fi

      # Display Configs section
      if [[ -n "$configs_modified" || -n "$configs_new" || -n "$configs_removed" ]]; then
        echo "  ${COLOR_C}Configs${RESET}"
        if [[ -n "$configs_modified" ]]; then
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${YELLOW}@${RESET} $file"
              fi
            done
          done <<<"$configs_modified"
        fi
        if [[ -n "$configs_new" ]]; then
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${GREEN}+${RESET} $file"
              fi
            done
          done <<<"$configs_new"
        fi
        if [[ -n "$configs_removed" ]]; then
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${RED}-${RESET} $file"
              fi
            done
          done <<<"$configs_removed"
        fi
      fi

      echo ""
    else
      # Version is up to date, but check for available imports
      # Parse all changes by type and status
      local scripts_modified=$(echo "$changes" | grep "^SCRIPTS_MODIFIED:" | cut -d: -f2-)
      local scripts_new=$(echo "$changes" | grep "^SCRIPTS_NEW:" | cut -d: -f2-)
      local aliases_modified=$(echo "$changes" | grep "^ALIASES_MODIFIED:" | cut -d: -f2-)
      local aliases_new=$(echo "$changes" | grep "^ALIASES_NEW:" | cut -d: -f2-)
      local helpers_modified=$(echo "$changes" | grep "^HELPERS_MODIFIED:" | cut -d: -f2-)
      local helpers_new=$(echo "$changes" | grep "^HELPERS_NEW:" | cut -d: -f2-)
      local configs_modified=$(echo "$changes" | grep "^CONFIGS_MODIFIED:" | cut -d: -f2-)
      local configs_new=$(echo "$changes" | grep "^CONFIGS_NEW:" | cut -d: -f2-)

      # Check if there are any available imports
      if [[ -n "$scripts_new" || -n "$aliases_new" || -n "$helpers_new" || -n "$configs_new" ]]; then
        echo "${GREEN}✓ up to date${RESET}"
        echo "  ${CYAN}Available to import:${RESET}"

        # Display available Scripts
        if [[ -n "$scripts_new" ]]; then
          echo "  ${COLOR_S}Scripts${RESET}"
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${CYAN}○${RESET} $file"
              fi
            done
          done <<<"$scripts_new"
        fi

        # Display available Aliases
        if [[ -n "$aliases_new" ]]; then
          echo "  ${COLOR_A}Aliases${RESET}"
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${CYAN}○${RESET} $file"
              fi
            done
          done <<<"$aliases_new"
        fi

        # Display available Helpers
        if [[ -n "$helpers_new" ]]; then
          echo "  ${COLOR_H}Helpers${RESET}"
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${CYAN}○${RESET} $file"
              fi
            done
          done <<<"$helpers_new"
        fi

        # Display available Configs
        if [[ -n "$configs_new" ]]; then
          echo "  ${COLOR_C}Configs${RESET}"
          while IFS=',' read -ra FILES; do
            for file in "${FILES[@]}"; do
              if [[ -n "$file" ]]; then
                echo "    ${CYAN}○${RESET} $file"
              fi
            done
          done <<<"$configs_new"
        fi

        echo "  ${GRAY}Run ${CYAN}'dr -col'${GRAY} to browse and import resources${RESET}"
        echo ""
      else
        echo "${GREEN}✓ up to date${RESET}"
      fi
    fi
  done

  cd "$orig_dir" || return 1

  if [[ "$updates_available" == "true" ]]; then
    echo ""
    echo "${BOLD}Updates Available${RESET}"
    echo "${GRAY}Run ${CYAN}'dr -col update <name>'${GRAY} to update a specific collection${RESET}"
  else
    echo ""
    echo "${BOLD}${GREEN}✓ All collections are up to date${RESET}"
  fi
}

cmd_col_update() {
  local collection_name="$1"

  # If no collection name provided, show interactive selection
  if [[ -z "$collection_name" ]]; then
    if [[ ! -f "$COLLECTIONS_CONF" ]]; then
      echo "${YELLOW}No collections installed${RESET}" >&2
      echo "" >&2
      echo "${GRAY}Run ${CYAN}'dr -col add <github-url>'${GRAY} to install a collection${RESET}" >&2
      return 1
    fi

    local collections=($(list_collection_names))

    if [[ ${#collections[@]} -eq 0 ]]; then
      echo "${YELLOW}No collections installed${RESET}" >&2
      echo "" >&2
      echo "${GRAY}Run ${CYAN}'dr -col add <github-url>'${GRAY} to install a collection${RESET}" >&2
      return 1
    fi

    echo "${BOLD}Select collection to update:${RESET}" >&2
    echo "" >&2

    local index=1
    for collection in "${collections[@]}"; do
      local version=$(get_collection_property "$collection" "version")
      echo "${GRAY}$index. ${CYAN}$collection ${RESET}${GRAY}(v$version)${RESET}" >&2
      ((index++))
    done

    echo "" >&2
    read -p "Choice (1-${#collections[@]}): " choice >&2

    # Validate choice
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt ${#collections[@]} ]]; then
      echo "${RED}Invalid choice${RESET}" >&2
      return 1
    fi

    # Get selected collection name
    collection_name="${collections[$((choice - 1))]}"
    echo "" >&2
  fi

  # Check if collection exists
  if ! collection_exists "$collection_name"; then
    echo "Error: Collection '$collection_name' not found" >&2
    echo "" >&2

    # Find similar collection names
    local similar=($(find_similar_collection_names "$collection_name"))

    if [[ ${#similar[@]} -gt 0 ]]; then
      echo "Did you mean:" >&2
      for suggestion in "${similar[@]}"; do
        echo "  • $suggestion" >&2
      done
      echo "" >&2
    fi

    echo "Run 'dr -col list' to see all installed collections" >&2
    return 1
  fi

  # Get collection properties
  local current_version=$(get_collection_property "$collection_name" "version")
  local collection_path=$(get_collection_property "$collection_name" "path")

  if [[ ! -d "$collection_path" ]]; then
    echo "Error: Collection directory not found: $collection_path" >&2
    return 1
  fi

  echo "Updating collection '$collection_name' (v$current_version)..."
  echo ""

  # Fetch updates (detailed errors from git_fetch_collection)
  if ! git_fetch_collection "$collection_path" >&2; then
    echo "" >&2
    echo "Update aborted due to fetch failure" >&2
    echo "" >&2
    echo "Resolve the issue above and try again:" >&2
    echo "  dr -col update $collection_name" >&2
    return 1
  fi

  # Get latest version tag
  local latest_tag=$(git_get_latest_tag "$collection_path")

  if [[ -z "$latest_tag" ]]; then
    echo "Error: No version tags found in collection" >&2
    return 1
  fi

  local latest_version="${latest_tag#v}"

  # Check if already up to date
  if ! version_less_than "$current_version" "$latest_version"; then
    echo "Collection is already up to date (v$current_version)"
    return 0
  fi

  echo "Update available: $current_version → $latest_version"
  echo ""

  # Confirm before proceeding
  read -p "Proceed with update? [y/N]: " confirm
  case "${confirm,,}" in
    y | yes) ;;
    *)
      echo "Update cancelled"
      return 0
      ;;
  esac
  echo ""

  # Checkout latest version
  if ! git_checkout_tag "$collection_path" "$latest_tag"; then
    echo "Error: Failed to checkout version $latest_version" >&2
    return 1
  fi

  # Get current imported files
  local imported_scripts=$(get_collection_property "$collection_name" "imported_scripts")
  local imported_aliases=$(get_collection_property "$collection_name" "imported_aliases")
  local imported_helpers=$(get_collection_property "$collection_name" "imported_helpers")
  local imported_configs=$(get_collection_property "$collection_name" "imported_configs")

  # Arrays to store new hashes after update
  local updated_scripts=()
  local updated_aliases=()
  local updated_helpers=()
  local updated_configs=()

  # Process scripts
  if [[ -n "$imported_scripts" ]]; then
    echo "Checking scripts..."
    while IFS=',' read -ra SCRIPTS; do
      for item in "${SCRIPTS[@]}"; do
        if [[ -z "$item" ]]; then continue; fi

        local filename="${item%%:*}"
        local original_hash="${item##*:}"
        local user_file="$BIN_DIR/$filename"

        if [[ ! -f "$user_file" ]]; then
          echo "  Warning: Imported file not found: $user_file" >&2
          continue
        fi

        # Calculate current hash of user's file
        local current_hash=$(calculate_file_hash "$user_file")

        # Check if user modified the file
        if [[ "$current_hash" == "$original_hash" ]]; then
          # Unmodified - simple update
          local result=$(handle_unmodified_file_update "$collection_name" "$filename" "scripts" "$collection_path")
          if [[ $? -eq 0 ]]; then
            updated_scripts+=("$result")
          else
            # User skipped - keep original
            updated_scripts+=("$item")
          fi
        else
          # Modified - conflict resolution
          local result=$(handle_modified_file_update "$collection_name" "$filename" "scripts" "$collection_path" "$original_hash")
          updated_scripts+=("$result")
        fi
      done
    done <<<"$imported_scripts"
  fi

  # Process aliases
  if [[ -n "$imported_aliases" ]]; then
    echo "Checking aliases..."
    while IFS=',' read -ra ALIASES; do
      for item in "${ALIASES[@]}"; do
        if [[ -z "$item" ]]; then continue; fi

        local filename="${item%%:*}"
        local original_hash="${item##*:}"
        local user_file="$DR_CONFIG/aliases/$filename"

        if [[ ! -f "$user_file" ]]; then
          echo "  Warning: Imported file not found: $user_file" >&2
          continue
        fi

        local current_hash=$(calculate_file_hash "$user_file")

        if [[ "$current_hash" == "$original_hash" ]]; then
          local result=$(handle_unmodified_file_update "$collection_name" "$filename" "aliases" "$collection_path")
          if [[ $? -eq 0 ]]; then
            updated_aliases+=("$result")
          else
            updated_aliases+=("$item")
          fi
        else
          local result=$(handle_modified_file_update "$collection_name" "$filename" "aliases" "$collection_path" "$original_hash")
          updated_aliases+=("$result")
        fi
      done
    done <<<"$imported_aliases"
  fi

  # Process helpers
  if [[ -n "$imported_helpers" ]]; then
    echo "Checking helpers..."
    while IFS=',' read -ra HELPERS; do
      for item in "${HELPERS[@]}"; do
        if [[ -z "$item" ]]; then continue; fi

        local filename="${item%%:*}"
        local original_hash="${item##*:}"
        local user_file="$DR_CONFIG/helpers/$filename"

        if [[ ! -f "$user_file" ]]; then
          echo "  Warning: Imported file not found: $user_file" >&2
          continue
        fi

        local current_hash=$(calculate_file_hash "$user_file")

        if [[ "$current_hash" == "$original_hash" ]]; then
          local result=$(handle_unmodified_file_update "$collection_name" "$filename" "helpers" "$collection_path")
          if [[ $? -eq 0 ]]; then
            updated_helpers+=("$result")
          else
            updated_helpers+=("$item")
          fi
        else
          local result=$(handle_modified_file_update "$collection_name" "$filename" "helpers" "$collection_path" "$original_hash")
          updated_helpers+=("$result")
        fi
      done
    done <<<"$imported_helpers"
  fi

  # Process configs
  if [[ -n "$imported_configs" ]]; then
    echo "Checking configs..."
    while IFS=',' read -ra CONFIGS; do
      for item in "${CONFIGS[@]}"; do
        if [[ -z "$item" ]]; then continue; fi

        local filename="${item%%:*}"
        local original_hash="${item##*:}"
        local user_file="$DR_CONFIG/configs/$filename"

        if [[ ! -f "$user_file" ]]; then
          echo "  Warning: Imported file not found: $user_file" >&2
          continue
        fi

        local current_hash=$(calculate_file_hash "$user_file")

        if [[ "$current_hash" == "$original_hash" ]]; then
          local result=$(handle_unmodified_file_update "$collection_name" "$filename" "configs" "$collection_path")
          if [[ $? -eq 0 ]]; then
            updated_configs+=("$result")
          else
            updated_configs+=("$item")
          fi
        else
          local result=$(handle_modified_file_update "$collection_name" "$filename" "configs" "$collection_path" "$original_hash")
          updated_configs+=("$result")
        fi
      done
    done <<<"$imported_configs"
  fi

  # Check for removed files (files that were imported but no longer exist in new version)
  echo ""
  echo "Checking for removed files..."

  # Check for removed scripts
  if [[ -n "$imported_scripts" ]]; then
    while IFS=',' read -ra SCRIPTS; do
      for item in "${SCRIPTS[@]}"; do
        if [[ -z "$item" ]]; then continue; fi

        local filename="${item%%:*}"
        local collection_file="$collection_path/scripts/$filename"
        local user_file="$BIN_DIR/$filename"

        # If file doesn't exist in new collection version but was imported
        if [[ ! -f "$collection_file" ]] && [[ -f "$user_file" ]]; then
          echo "${YELLOW}File removed from collection:${RESET} scripts/$filename"
          read -p "  Delete from your scripts? [y/N]: " delete_choice
          case "${delete_choice,,}" in
            y | yes)
              rm "$user_file"
              echo "  ${GREEN}✓${RESET} Deleted $user_file"
              # Don't add to updated_scripts array - it's removed
              ;;
            *)
              echo "  ${GRAY}Kept${RESET} $user_file"
              # Keep in tracking even though it's no longer in collection
              updated_scripts+=("$item")
              ;;
          esac
        fi
      done
    done <<<"$imported_scripts"
  fi

  # Check for removed aliases
  if [[ -n "$imported_aliases" ]]; then
    while IFS=',' read -ra ALIASES; do
      for item in "${ALIASES[@]}"; do
        if [[ -z "$item" ]]; then continue; fi

        local filename="${item%%:*}"
        local collection_file="$collection_path/aliases/$filename"
        local user_file="$DR_CONFIG/aliases/$filename"

        if [[ ! -f "$collection_file" ]] && [[ -f "$user_file" ]]; then
          echo "${YELLOW}File removed from collection:${RESET} aliases/$filename"
          read -p "  Delete from your aliases? [y/N]: " delete_choice
          case "${delete_choice,,}" in
            y | yes)
              rm "$user_file"
              echo "  ${GREEN}✓${RESET} Deleted $user_file"
              ;;
            *)
              echo "  ${GRAY}Kept${RESET} $user_file"
              updated_aliases+=("$item")
              ;;
          esac
        fi
      done
    done <<<"$imported_aliases"
  fi

  # Check for removed helpers
  if [[ -n "$imported_helpers" ]]; then
    while IFS=',' read -ra HELPERS; do
      for item in "${HELPERS[@]}"; do
        if [[ -z "$item" ]]; then continue; fi

        local filename="${item%%:*}"
        local collection_file="$collection_path/helpers/$filename"
        local user_file="$DR_CONFIG/helpers/$filename"

        if [[ ! -f "$collection_file" ]] && [[ -f "$user_file" ]]; then
          echo "${YELLOW}File removed from collection:${RESET} helpers/$filename"
          read -p "  Delete from your helpers? [y/N]: " delete_choice
          case "${delete_choice,,}" in
            y | yes)
              rm "$user_file"
              echo "  ${GREEN}✓${RESET} Deleted $user_file"
              ;;
            *)
              echo "  ${GRAY}Kept${RESET} $user_file"
              updated_helpers+=("$item")
              ;;
          esac
        fi
      done
    done <<<"$imported_helpers"
  fi

  # Check for removed configs
  if [[ -n "$imported_configs" ]]; then
    while IFS=',' read -ra CONFIGS; do
      for item in "${CONFIGS[@]}"; do
        if [[ -z "$item" ]]; then continue; fi

        local filename="${item%%:*}"
        local collection_file="$collection_path/configs/$filename"
        local user_file="$DR_CONFIG/configs/$filename"

        if [[ ! -f "$collection_file" ]] && [[ -f "$user_file" ]]; then
          echo "${YELLOW}File removed from collection:${RESET} configs/$filename"
          read -p "  Delete from your configs? [y/N]: " delete_choice
          case "${delete_choice,,}" in
            y | yes)
              rm "$user_file"
              echo "  ${GREEN}✓${RESET} Deleted $user_file"
              ;;
            *)
              echo "  ${GRAY}Kept${RESET} $user_file"
              updated_configs+=("$item")
              ;;
          esac
        fi
      done
    done <<<"$imported_configs"
  fi

  # Check for new files in collection
  echo ""
  echo "Checking for new files..."

  # New scripts
  if [[ -d "$collection_path/scripts" ]]; then
    while IFS= read -r -d '' file; do
      local rel_path="${file#$collection_path/scripts/}"
      if [[ ! "$imported_scripts" =~ $rel_path: ]]; then
        local result=$(handle_new_file_import "$collection_name" "$rel_path" "scripts" "$collection_path")
        if [[ $? -eq 0 ]] && [[ -n "$result" ]]; then
          updated_scripts+=("$result")
        fi
      fi
    done < <(find "$collection_path/scripts" -name "*.sh" -type f -print0 2>/dev/null)
  fi

  # New aliases
  if [[ -d "$collection_path/aliases" ]]; then
    while IFS= read -r -d '' file; do
      local rel_path="${file#$collection_path/aliases/}"
      if [[ ! "$imported_aliases" =~ $rel_path: ]]; then
        local result=$(handle_new_file_import "$collection_name" "$rel_path" "aliases" "$collection_path")
        if [[ $? -eq 0 ]] && [[ -n "$result" ]]; then
          updated_aliases+=("$result")
        fi
      fi
    done < <(find "$collection_path/aliases" -type f -print0 2>/dev/null)
  fi

  # New helpers
  if [[ -d "$collection_path/helpers" ]]; then
    while IFS= read -r -d '' file; do
      local rel_path="${file#$collection_path/helpers/}"
      if [[ ! "$imported_helpers" =~ $rel_path: ]]; then
        local result=$(handle_new_file_import "$collection_name" "$rel_path" "helpers" "$collection_path")
        if [[ $? -eq 0 ]] && [[ -n "$result" ]]; then
          updated_helpers+=("$result")
        fi
      fi
    done < <(find "$collection_path/helpers" -type f -print0 2>/dev/null)
  fi

  # New configs
  if [[ -d "$collection_path/configs" ]]; then
    while IFS= read -r -d '' file; do
      local rel_path="${file#$collection_path/configs/}"
      if [[ ! "$imported_configs" =~ $rel_path: ]]; then
        local result=$(handle_new_file_import "$collection_name" "$rel_path" "configs" "$collection_path")
        if [[ $? -eq 0 ]] && [[ -n "$result" ]]; then
          updated_configs+=("$result")
        fi
      fi
    done < <(find "$collection_path/configs" -type f -print0 2>/dev/null)
  fi

  # Update collections.conf with new version and hashes
  set_collection_property "$collection_name" "version" "$latest_version"
  set_collection_property "$collection_name" "imported_scripts" "$(
    IFS=,
    echo "${updated_scripts[*]}"
  )"
  set_collection_property "$collection_name" "imported_aliases" "$(
    IFS=,
    echo "${updated_aliases[*]}"
  )"
  set_collection_property "$collection_name" "imported_helpers" "$(
    IFS=,
    echo "${updated_helpers[*]}"
  )"
  set_collection_property "$collection_name" "imported_configs" "$(
    IFS=,
    echo "${updated_configs[*]}"
  )"

  echo ""
  echo "✓ Collection '$collection_name' updated to v$latest_version"
  echo ""
  echo "Run 'dr -col list' to view installed collections"
}

cmd_col_remove() {
  local collection_name="$1"

  # Validate collection name argument
  if [[ -z "$collection_name" ]]; then
    echo "Error: Collection name required" >&2
    echo "Usage: dr -col remove <collection-name>" >&2
    echo "" >&2
    echo "Run 'dr -col list' to see installed collections" >&2
    return 1
  fi

  # Check if collection exists
  if ! collection_exists "$collection_name"; then
    echo "Error: Collection '$collection_name' not found" >&2
    echo "" >&2

    # Find similar collection names
    local similar=($(find_similar_collection_names "$collection_name"))

    if [[ ${#similar[@]} -gt 0 ]]; then
      echo "Did you mean:" >&2
      for suggestion in "${similar[@]}"; do
        echo "  • $suggestion" >&2
      done
      echo "" >&2
    fi

    echo "Run 'dr -col list' to see all installed collections" >&2
    return 1
  fi

  # Get collection properties
  local collection_path=$(get_collection_property "$collection_name" "path")
  local imported_scripts=$(get_collection_property "$collection_name" "imported_scripts")
  local imported_aliases=$(get_collection_property "$collection_name" "imported_aliases")
  local imported_helpers=$(get_collection_property "$collection_name" "imported_helpers")
  local imported_configs=$(get_collection_property "$collection_name" "imported_configs")

  # Discover namespace directories dynamically (users can rename to control load order)
  local namespace_scripts=$(find_collection_namespace "$collection_name" "scripts" 2>/dev/null)
  local namespace_aliases=$(find_collection_namespace "$collection_name" "aliases" 2>/dev/null)
  local namespace_helpers=$(find_collection_namespace "$collection_name" "helpers" 2>/dev/null)
  local namespace_configs=$(find_collection_namespace "$collection_name" "configs" 2>/dev/null)

  # Build list of directories/files to remove
  local imported_locations=()

  # For scripts, remove entire namespace directory (if exists)
  if [[ -d "$BIN_DIR/$namespace_scripts" ]]; then
    imported_locations+=("  - $BIN_DIR/$namespace_scripts/ (entire directory)")
  elif [[ -n "$imported_scripts" ]]; then
    # Fallback for legacy non-namespaced installations
    while IFS=',' read -ra SCRIPTS; do
      for item in "${SCRIPTS[@]}"; do
        local filename="${item%%:*}"
        if [[ -n "$filename" ]]; then
          imported_locations+=("  - $BIN_DIR/$filename")
        fi
      done
    done <<<"$imported_scripts"
  fi

  # For aliases, remove entire namespace directory (if exists)
  if [[ -d "$DR_CONFIG/aliases/$namespace_aliases" ]]; then
    imported_locations+=("  - $DR_CONFIG/aliases/$namespace_aliases/ (entire directory)")
  elif [[ -n "$imported_aliases" ]]; then
    # Fallback for legacy non-namespaced installations
    while IFS=',' read -ra ALIASES; do
      for item in "${ALIASES[@]}"; do
        local filename="${item%%:*}"
        if [[ -n "$filename" ]]; then
          imported_locations+=("  - $DR_CONFIG/aliases/$filename")
        fi
      done
    done <<<"$imported_aliases"
  fi

  # For helpers, remove entire namespace directory (if exists)
  if [[ -d "$DR_CONFIG/helpers/$namespace_helpers" ]]; then
    imported_locations+=("  - $DR_CONFIG/helpers/$namespace_helpers/ (entire directory)")
  elif [[ -n "$imported_helpers" ]]; then
    # Fallback for legacy non-namespaced installations
    while IFS=',' read -ra HELPERS; do
      for item in "${HELPERS[@]}"; do
        local filename="${item%%:*}"
        if [[ -n "$filename" ]]; then
          imported_locations+=("  - $DR_CONFIG/helpers/$filename")
        fi
      done
    done <<<"$imported_helpers"
  fi

  # For configs, remove entire namespace directory (if exists)
  if [[ -d "$DR_CONFIG/configs/$namespace_configs" ]]; then
    imported_locations+=("  - $DR_CONFIG/configs/$namespace_configs/ (entire directory)")
  elif [[ -n "$imported_configs" ]]; then
    # Fallback for legacy non-namespaced installations
    while IFS=',' read -ra CONFIGS; do
      for item in "${CONFIGS[@]}"; do
        local filename="${item%%:*}"
        if [[ -n "$filename" ]]; then
          imported_locations+=("  - $DR_CONFIG/configs/$filename")
        fi
      done
    done <<<"$imported_configs"
  fi

  # Display warning
  echo "⚠️  This will remove tracking for '$collection_name'"

  if [[ ${#imported_locations[@]} -gt 0 ]]; then
    echo ""
    echo "The following will be removed:"
    for location in "${imported_locations[@]}"; do
      echo "$location"
    done
  else
    echo ""
    echo "No imported files to preserve."
  fi

  echo ""
  read -p "Continue? [y/N] " confirm

  case "${confirm,,}" in
    y | yes) ;;
    *)
      echo "Cancelled"
      return 0
      ;;
  esac

  # Remove namespace directories for all resource types
  if [[ -d "$BIN_DIR/$namespace_scripts" ]]; then
    rm -rf "$BIN_DIR/$namespace_scripts"
    echo "✓ Removed scripts directory: $BIN_DIR/$namespace_scripts"
  fi

  if [[ -d "$DR_CONFIG/aliases/$namespace_aliases" ]]; then
    rm -rf "$DR_CONFIG/aliases/$namespace_aliases"
    echo "✓ Removed aliases directory: $DR_CONFIG/aliases/$namespace_aliases"
  fi

  if [[ -d "$DR_CONFIG/helpers/$namespace_helpers" ]]; then
    rm -rf "$DR_CONFIG/helpers/$namespace_helpers"
    echo "✓ Removed helpers directory: $DR_CONFIG/helpers/$namespace_helpers"
  fi

  if [[ -d "$DR_CONFIG/configs/$namespace_configs" ]]; then
    rm -rf "$DR_CONFIG/configs/$namespace_configs"
    echo "✓ Removed configs directory: $DR_CONFIG/configs/$namespace_configs"
  fi

  # Remove collection directory
  if [[ -d "$collection_path" ]]; then
    rm -rf "$collection_path"
    echo "✓ Removed collection directory: $collection_path"
  fi

  # Remove tracking entry
  remove_collection_from_conf "$collection_name"
  echo "✓ Removed tracking entry for: $collection_name"

  echo ""
  echo "Collection '$collection_name' removed successfully"
}

cmd_col_interactive() {
  if [[ ! -f "$COLLECTIONS_CONF" ]]; then
    echo "No collections installed"
    echo ""
    echo "Run 'dr -col add <github-url>' to install a collection"
    return 0
  fi

  local collections=($(list_collection_names))

  if [[ ${#collections[@]} -eq 0 ]]; then
    echo "No collections installed"
    echo ""
    echo "Run 'dr -col add <github-url>' to install a collection"
    return 0
  fi

  # Display collections with update badges
  echo "Installed Collections:"
  echo ""

  local collection_status=()
  local index=1

  for collection in "${collections[@]}"; do
    local version=$(get_collection_property "$collection" "version")
    local url=$(get_collection_property "$collection" "url")
    local collection_path=$(get_collection_property "$collection" "path")

    # Check for updates
    local update_badge=""
    if [[ -d "$collection_path" ]]; then
      # Silently fetch updates
      git_fetch_collection "$collection_path" 2>/dev/null || true
      local latest_tag=$(git_get_latest_tag "$collection_path" 2>/dev/null)

      if [[ -n "$latest_tag" ]]; then
        local latest_version="${latest_tag#v}"
        if version_less_than "$version" "$latest_version"; then
          update_badge=" 🟢 (update available: v$latest_version)"
        fi
      fi
    fi

    echo "${GRAY}$index. ${BOLD}${CYAN}$collection ${RESET}(v$version) $update_badge"
    echo "   ${GRAY}URL: ${BLUE}$url${RESET}"
    echo ""

    collection_status+=("$collection")
    ((index++))
  done

  # Prompt for collection selection
  read -p "Select collection (1-${#collections[@]}) or [q]uit: " selection

  case "${selection,,}" in
    q | quit | "")
      echo "Cancelled"
      return 0
      ;;
    *)
      if ! [[ "$selection" =~ ^[0-9]+$ ]] || [[ $selection -lt 1 ]] || [[ $selection -gt ${#collections[@]} ]]; then
        echo "Error: Invalid selection" >&2
        return 1
      fi
      ;;
  esac

  # Get selected collection
  local selected_index=$((selection - 1))
  local selected_collection="${collection_status[$selected_index]}"
  local selected_version=$(get_collection_property "$selected_collection" "version")
  local selected_path=$(get_collection_property "$selected_collection" "path")

  # Check if update is available
  local latest_tag=$(git_get_latest_tag "$selected_path" 2>/dev/null)
  if [[ -n "$latest_tag" ]]; then
    local latest_version="${latest_tag#v}"
    if version_less_than "$selected_version" "$latest_version"; then
      echo ""
      echo "Update available for '$selected_collection': v$selected_version → v$latest_version"
      read -p "Update now? [y/N]: " update_choice

      case "${update_choice,,}" in
        y | yes)
          cmd_col_update "$selected_collection"
          return $?
          ;;
      esac
    fi
  fi

  clear
  # Browse and import resources
  echo ""
  echo "Selected: ${BOLD}${CYAN}$selected_collection ${GRAY}(v$selected_version)${RESET}"

  # Interactive resource selection (reuse existing function)
  local import_results=$(select_resources_to_import "$selected_collection")

  # Parse import results (use -f2- to keep hashes which also contain colons)
  local imported_scripts=$(echo "$import_results" | grep "^SCRIPTS:" | cut -d: -f2-)
  local imported_aliases=$(echo "$import_results" | grep "^ALIASES:" | cut -d: -f2-)
  local imported_helpers=$(echo "$import_results" | grep "^HELPERS:" | cut -d: -f2-)
  local imported_configs=$(echo "$import_results" | grep "^CONFIGS:" | cut -d: -f2-)

  # Get current tracking data
  local current_scripts=$(get_collection_property "$selected_collection" "imported_scripts")
  local current_aliases=$(get_collection_property "$selected_collection" "imported_aliases")
  local current_helpers=$(get_collection_property "$selected_collection" "imported_helpers")
  local current_configs=$(get_collection_property "$selected_collection" "imported_configs")

  # Merge new imports with existing (avoid duplicates)
  local merged_scripts="$current_scripts"
  local merged_aliases="$current_aliases"
  local merged_helpers="$current_helpers"
  local merged_configs="$current_configs"

  # Add new scripts
  if [[ -n "$imported_scripts" ]]; then
    while IFS=',' read -ra SCRIPTS; do
      for item in "${SCRIPTS[@]}"; do
        if [[ -n "$item" ]] && [[ ! "$merged_scripts" =~ ${item%%:*}: ]]; then
          if [[ -n "$merged_scripts" ]]; then
            merged_scripts="$merged_scripts,$item"
          else
            merged_scripts="$item"
          fi
        fi
      done
    done <<<"$imported_scripts"
  fi

  # Add new aliases
  if [[ -n "$imported_aliases" ]]; then
    while IFS=',' read -ra ALIASES; do
      for item in "${ALIASES[@]}"; do
        if [[ -n "$item" ]] && [[ ! "$merged_aliases" =~ ${item%%:*}: ]]; then
          if [[ -n "$merged_aliases" ]]; then
            merged_aliases="$merged_aliases,$item"
          else
            merged_aliases="$item"
          fi
        fi
      done
    done <<<"$imported_aliases"
  fi

  # Add new helpers
  if [[ -n "$imported_helpers" ]]; then
    while IFS=',' read -ra HELPERS; do
      for item in "${HELPERS[@]}"; do
        if [[ -n "$item" ]] && [[ ! "$merged_helpers" =~ ${item%%:*}: ]]; then
          if [[ -n "$merged_helpers" ]]; then
            merged_helpers="$merged_helpers,$item"
          else
            merged_helpers="$item"
          fi
        fi
      done
    done <<<"$imported_helpers"
  fi

  # Add new configs
  if [[ -n "$imported_configs" ]]; then
    while IFS=',' read -ra CONFIGS; do
      for item in "${CONFIGS[@]}"; do
        if [[ -n "$item" ]] && [[ ! "$merged_configs" =~ ${item%%:*}: ]]; then
          if [[ -n "$merged_configs" ]]; then
            merged_configs="$merged_configs,$item"
          else
            merged_configs="$item"
          fi
        fi
      done
    done <<<"$imported_configs"
  fi

  # Update tracking with merged imports
  set_collection_property "$selected_collection" "imported_scripts" "$merged_scripts"
  set_collection_property "$selected_collection" "imported_aliases" "$merged_aliases"
  set_collection_property "$selected_collection" "imported_helpers" "$merged_helpers"
  set_collection_property "$selected_collection" "imported_configs" "$merged_configs"

  echo ""
  echo "✓ Resource import completed"
  echo ""
  echo "Run 'dr -col list' to view installed collections"
}

# ──────────────────────────────────────────────────────────────
# Main Entry Point
# ──────────────────────────────────────────────────────────────

# This file is sourced by dr binary
# Commands are dispatched from dr based on arguments
