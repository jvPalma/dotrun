#!/usr/bin/env bash
# Collection management helpers for DotRun - REDESIGNED
# Simplified, interactive collections system with GitHub URL registry

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016

# ──────────────────────────────────────────────────────────────
# Configuration and Constants
# ──────────────────────────────────────────────────────────────

DR_CONFIG="${DR_CONFIG:-$HOME/.config/dotrun}"
BIN_DIR="${BIN_DIR:-$DR_CONFIG/bin}"
DRUN_CONF="$HOME/.dr.conf"
CACHE_DIR="$DR_CONFIG/.cache/collections"

source "$DR_CONFIG/helpers/pkg.sh"
validatePkg git

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# ──────────────────────────────────────────────────────────────
# URL Management Functions
# ──────────────────────────────────────────────────────────────

# Validate GitHub URL format
validate_github_url() {
  local url="$1"

  # Check basic format
  if [[ ! "$url" =~ ^https://github\.com/[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$ ]]; then
    echo "Error: Invalid GitHub URL format" >&2
    echo "Expected format: https://github.com/user/repo" >&2
    return 1
  fi

  # Ensure .git suffix is present
  if [[ ! "$url" =~ \.git$ ]]; then
    url="${url}.git"
  fi

  echo "$url"
  return 0
}

# Initialize .dr.conf if it doesn't exist
init_drun_conf() {
  if [[ ! -f "$DRUN_CONF" ]]; then
    cat > "$DRUN_CONF" << 'EOF'
# DotRun Collections Configuration
# Add GitHub repository URLs for your script collections
#
# Format:
# [collections]
# https://github.com/user/repo.git
# https://github.com/company/scripts.git

[collections]
EOF
    echo "Created configuration file: $DRUN_CONF"
  fi
}

# Add collection URL to config
add_collection_url() {
  local url="$1"

  if [[ -z "$url" ]]; then
    echo "Error: GitHub URL required" >&2
    echo "Usage: dr collections add <github-url>" >&2
    return 1
  fi

  # Validate and normalize URL
  local validated_url
  if ! validated_url=$(validate_github_url "$url"); then
    return 1
  fi

  # Initialize config if needed
  init_drun_conf

  # Check if URL already exists
  if grep -Fxq "$validated_url" "$DRUN_CONF" 2>/dev/null; then
    echo "Collection URL already exists in config"
    return 0
  fi

  # Ensure [collections] section exists
  if ! grep -q "^\[collections\]" "$DRUN_CONF"; then
    echo "" >> "$DRUN_CONF"
    echo "[collections]" >> "$DRUN_CONF"
  fi

  # Add URL after [collections] section
  awk -v url="$validated_url" '
    /^\[collections\]/ { in_section=1; print; next }
    in_section && /^\[/ { print url; in_section=0 }
    { print }
    END { if (in_section) print url }
  ' "$DRUN_CONF" > "$DRUN_CONF.tmp" && mv "$DRUN_CONF.tmp" "$DRUN_CONF"

  echo "✓ Collection URL added to $DRUN_CONF"
  return 0
}

# List collection URLs from config
list_collection_urls() {
  init_drun_conf

  # Extract URLs from [collections] section
  local urls=()
  local in_section=0

  while IFS= read -r line; do
    if [[ "$line" =~ ^\[collections\] ]]; then
      in_section=1
      continue
    fi

    if [[ "$line" =~ ^\[ ]]; then
      in_section=0
      continue
    fi

    if [[ $in_section -eq 1 && "$line" =~ ^https:// ]]; then
      urls+=("$line")
    fi
  done < "$DRUN_CONF"

  if [[ ${#urls[@]} -eq 0 ]]; then
    echo "No collections configured"
    echo "Add collections with: dr collections add <github-url>"
    return 0
  fi

  echo "Configured collections:"
  local i=1
  for url in "${urls[@]}"; do
    # Extract repo name from URL
    local repo_name=$(basename "$url" .git)
    local owner=$(echo "$url" | sed 's|https://github.com/\([^/]*\)/.*|\1|')
    echo "  $i) $owner/$repo_name"
    echo "     $url"
    ((i++))
  done

  return 0
}

# Remove collection URL by number
remove_collection_url() {
  local number="$1"

  if [[ -z "$number" ]] || ! [[ "$number" =~ ^[0-9]+$ ]]; then
    echo "Error: Valid number required" >&2
    echo "Usage: dr collections remove <number>" >&2
    echo "Run 'dr collections list' to see numbers" >&2
    return 1
  fi

  init_drun_conf

  # Get the URL at the specified index
  local urls=()
  local in_section=0

  while IFS= read -r line; do
    if [[ "$line" =~ ^\[collections\] ]]; then
      in_section=1
      continue
    fi

    if [[ "$line" =~ ^\[ ]]; then
      in_section=0
      continue
    fi

    if [[ $in_section -eq 1 && "$line" =~ ^https:// ]]; then
      urls+=("$line")
    fi
  done < "$DRUN_CONF"

  if [[ $number -lt 1 || $number -gt ${#urls[@]} ]]; then
    echo "Error: Invalid number. Must be between 1 and ${#urls[@]}" >&2
    return 1
  fi

  local url_to_remove="${urls[$((number-1))]}"

  # Show what will be removed
  local repo_name=$(basename "$url_to_remove" .git)
  local owner=$(echo "$url_to_remove" | sed 's|https://github.com/\([^/]*\)/.*|\1|')
  echo "Removing: $owner/$repo_name"
  echo "URL: $url_to_remove"

  read -p "Are you sure? [y/N]: " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Removal cancelled"
    return 1
  fi

  # Remove the URL from config
  grep -Fxv "$url_to_remove" "$DRUN_CONF" > "$DRUN_CONF.tmp" && mv "$DRUN_CONF.tmp" "$DRUN_CONF"

  echo "✓ Collection URL removed"
  return 0
}

# ──────────────────────────────────────────────────────────────
# Cache Management
# ──────────────────────────────────────────────────────────────

# Clone repository to cache
clone_to_cache() {
  local url="$1"

  # Generate hash for cache directory
  local hash=$(echo -n "$url" | md5sum | cut -d' ' -f1)
  local cache_path="$CACHE_DIR/$hash"

  # Clean cache if it already exists
  if [[ -d "$cache_path" ]]; then
    rm -rf "$cache_path"
  fi

  echo "Fetching collection..."

  # Clone repository
  if ! git clone --depth 1 "$url" "$cache_path" 2>/dev/null; then
    echo "Error: Failed to clone repository" >&2
    echo "URL: $url" >&2
    return 1
  fi

  echo "$cache_path"
  return 0
}

# Clear all cache
clear_cache() {
  if [[ -d "$CACHE_DIR" ]]; then
    rm -rf "${CACHE_DIR:?}"/*
    echo "✓ Cache cleared"
  fi
  return 0
}

# ──────────────────────────────────────────────────────────────
# Interactive Collection Flow
# ──────────────────────────────────────────────────────────────

# Main interactive menu
interactive_collection_menu() {
  echo "========================================"
  echo "  DotRun Collections Manager"
  echo "========================================"
  echo

  # Step 1: Select collection
  local selected_url
  if ! selected_url=$(select_collection); then
    return 1
  fi

  # Clone to cache
  local cache_path
  if ! cache_path=$(clone_to_cache "$selected_url"); then
    return 1
  fi

  echo "✓ Collection cloned to cache"
  echo

  # Step 2: Select resource type
  local resource_type
  if ! resource_type=$(select_resource_type "$cache_path"); then
    clear_cache
    return 1
  fi

  # Step 3: Select specific resources
  select_resources "$cache_path" "$resource_type"
  local result=$?

  # Clean up cache
  clear_cache

  return $result
}

# Step 1: Select collection from saved URLs
select_collection() {
  local urls=()
  local in_section=0

  init_drun_conf

  # Read URLs from config
  while IFS= read -r line; do
    if [[ "$line" =~ ^\[collections\] ]]; then
      in_section=1
      continue
    fi

    if [[ "$line" =~ ^\[ ]]; then
      in_section=0
      continue
    fi

    if [[ $in_section -eq 1 && "$line" =~ ^https:// ]]; then
      urls+=("$line")
    fi
  done < "$DRUN_CONF"

  if [[ ${#urls[@]} -eq 0 ]]; then
    echo "No collections configured" >&2
    echo "Add collections with: dr collections add <github-url>" >&2
    return 1
  fi

  echo "[1] Select Collection:"
  local i=1
  for url in "${urls[@]}"; do
    local repo_name=$(basename "$url" .git)
    local owner=$(echo "$url" | sed 's|https://github.com/\([^/]*\)/.*|\1|')
    echo "  $i) $owner/$repo_name ($url)"
    ((i++))
  done
  echo
  echo "  a) Add new collection"
  echo "  r) Remove collection"
  echo "  q) Quit"
  echo

  while true; do
    read -r -p "Select [1-${#urls[@]}/a/r/q]: " choice

    case "$choice" in
      q|Q)
        echo "Cancelled"
        return 1
        ;;
      a|A)
        read -r -p "Enter GitHub URL: " new_url
        if add_collection_url "$new_url"; then
          echo "Collection added. Restarting menu..."
          echo
          select_collection
          return $?
        fi
        continue
        ;;
      r|R)
        list_collection_urls
        echo
        read -r -p "Enter number to remove: " remove_num
        if remove_collection_url "$remove_num"; then
          echo "Collection removed. Restarting menu..."
          echo
          select_collection
          return $?
        fi
        continue
        ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -le ${#urls[@]} ]]; then
          echo "${urls[$((choice-1))]}"
          return 0
        fi
        echo "Invalid selection. Please try again."
        ;;
    esac
  done
}

# Step 2: Select resource type
select_resource_type() {
  local cache_path="$1"

  echo "[2] Select Resource Type:"

  # Check which resource types are available
  local available_types=()
  [[ -d "$cache_path/bin" ]] && available_types+=("bin")
  [[ -d "$cache_path/aliases" ]] && available_types+=("aliases")
  [[ -d "$cache_path/helpers" ]] && available_types+=("helpers")
  [[ -d "$cache_path/configs" ]] && available_types+=("configs")

  if [[ ${#available_types[@]} -eq 0 ]]; then
    echo "Error: No recognized resource types found in repository" >&2
    echo "Expected directories: bin/, aliases/, helpers/, configs/" >&2
    return 1
  fi

  local i=1
  local type_map=()

  for type in "${available_types[@]}"; do
    case "$type" in
      bin)
        echo "  $i) Scripts (bin/)"
        type_map+=("bin")
        ;;
      aliases)
        echo "  $i) Aliases (aliases/)"
        type_map+=("aliases")
        ;;
      helpers)
        echo "  $i) Helpers (helpers/)"
        type_map+=("helpers")
        ;;
      configs)
        echo "  $i) Configs (configs/)"
        type_map+=("configs")
        ;;
    esac
    ((i++))
  done

  echo
  echo "  b) Back"
  echo "  q) Quit"
  echo

  while true; do
    read -r -p "Select [1-${#type_map[@]}/b/q]: " choice

    case "$choice" in
      q|Q)
        echo "Cancelled"
        return 1
        ;;
      b|B)
        echo "Going back..."
        interactive_collection_menu
        return $?
        ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -le ${#type_map[@]} ]]; then
          echo "${type_map[$((choice-1))]}"
          return 0
        fi
        echo "Invalid selection. Please try again."
        ;;
    esac
  done
}

# Step 3: Select specific resources to import
select_resources() {
  local cache_path="$1"
  local resource_type="$2"
  local source_dir="$cache_path/$resource_type"

  echo
  echo "[3] Available ${resource_type^}:"

  # Find all resources
  local resources=()
  if [[ "$resource_type" == "bin" ]]; then
    while IFS= read -r -d '' file; do
      local rel_path="${file#"$source_dir"/}"
      rel_path="${rel_path%.sh}"
      resources+=("$rel_path")
    done < <(find "$source_dir" -name "*.sh" -type f -print0 2>/dev/null | sort -z)
  else
    while IFS= read -r -d '' file; do
      local rel_path="${file#"$source_dir"/}"
      resources+=("$rel_path")
    done < <(find "$source_dir" -type f -print0 2>/dev/null | sort -z)
  fi

  if [[ ${#resources[@]} -eq 0 ]]; then
    echo "  No resources found in $resource_type/"
    return 1
  fi

  # Display resources with numbers
  local i=1
  for resource in "${resources[@]}"; do
    echo "  $i) $resource"
    ((i++))
  done

  echo
  echo "  *) Select by number (e.g., 1,3)"
  echo "  a) Add all"
  echo "  b) Back"
  echo "  q) Quit"
  echo

  while true; do
    read -r -p "Select [numbers/a/b/q]: " choice

    case "$choice" in
      q|Q)
        echo "Cancelled"
        return 1
        ;;
      b|B)
        select_resource_type "$cache_path"
        return $?
        ;;
      a|A)
        # Import all resources
        local imported=0
        for resource in "${resources[@]}"; do
          if import_resource "$cache_path" "$resource_type" "$resource"; then
            ((imported++))
          fi
        done
        echo
        echo "Successfully added $imported ${resource_type}!"
        [[ "$resource_type" == "bin" ]] && echo "Run with: dr <scriptname>"
        return 0
        ;;
      *)
        # Parse comma-separated numbers
        IFS=',' read -ra selections <<< "$choice"
        local imported=0
        local valid=1

        for sel in "${selections[@]}"; do
          sel=$(echo "$sel" | tr -d ' ') # Trim whitespace
          if [[ ! "$sel" =~ ^[0-9]+$ ]] || [[ $sel -lt 1 || $sel -gt ${#resources[@]} ]]; then
            echo "Invalid selection: $sel"
            valid=0
            break
          fi
        done

        if [[ $valid -eq 1 ]]; then
          for sel in "${selections[@]}"; do
            sel=$(echo "$sel" | tr -d ' ')
            local resource="${resources[$((sel-1))]}"
            if import_resource "$cache_path" "$resource_type" "$resource"; then
              ((imported++))
            fi
          done
          echo
          echo "Successfully added $imported ${resource_type}!"
          [[ "$resource_type" == "bin" ]] && echo "Run with: dr <scriptname>"
          return 0
        fi
        ;;
    esac
  done
}

# Import a single resource to local DotRun
import_resource() {
  local cache_path="$1"
  local resource_type="$2"
  local resource_name="$3"

  local source_file
  case "$resource_type" in
    bin)
      source_file="$cache_path/bin/${resource_name}.sh"
      local target_file="$BIN_DIR/${resource_name}.sh"
      ;;
    aliases)
      source_file="$cache_path/aliases/${resource_name}"
      local target_file="$DR_CONFIG/aliases/${resource_name}"
      ;;
    helpers)
      source_file="$cache_path/helpers/${resource_name}"
      local target_file="$DR_CONFIG/helpers/${resource_name}"
      ;;
    configs)
      source_file="$cache_path/configs/${resource_name}"
      local target_file="$DR_CONFIG/configs/${resource_name}"
      ;;
  esac

  if [[ ! -f "$source_file" ]]; then
    echo "Error: Resource not found: $source_file" >&2
    return 1
  fi

  echo "Adding $resource_name..."

  # Check if target exists
  if [[ -f "$target_file" ]]; then
    echo "  Warning: $resource_name already exists"
    read -p "  [O]verwrite, [R]ename, [S]kip? " -r
    case "${REPLY,,}" in
      o)
        # Overwrite
        ;;
      r)
        # Find available renamed version
        local i=1
        local base_name=$(basename "$target_file")
        local dir_name=$(dirname "$target_file")
        local ext="${base_name##*.}"
        local name="${base_name%.*}"

        while [[ -f "$dir_name/${name}-${i}.$ext" ]]; do
          ((i++))
        done
        target_file="$dir_name/${name}-${i}.$ext"
        resource_name="${name}-${i}"
        echo "  Renaming to: $resource_name"
        ;;
      *)
        echo "  Skipped"
        return 0
        ;;
    esac
  fi

  # Create target directory
  mkdir -p "$(dirname "$target_file")"

  # Copy file
  cp "$source_file" "$target_file"

  # Make executable if it's a script
  if [[ "$resource_type" == "bin" ]]; then
    chmod +x "$target_file"
  fi

  echo "  ✓ Copied to $(dirname "$target_file")/${resource_name}${resource_type == "bin" && echo ".sh" || echo ""}"
  [[ "$resource_type" == "bin" ]] && echo "  ✓ Made executable"

  return 0
}

# ──────────────────────────────────────────────────────────────
# YADM Integration (kept from original)
# ──────────────────────────────────────────────────────────────

# Initialize DotRun to work with existing yadm setup
yadm_init() {
  local yadm_repo_root

  # Check if yadm is available and configured
  if ! command -v yadm >/dev/null 2>&1; then
    echo "Error: yadm not found. Please install yadm first." >&2
    return 1
  fi

  # Get yadm repository root
  if ! yadm_repo_root=$(yadm rev-parse --show-toplevel 2>/dev/null); then
    echo "Error: Not in a yadm-managed directory. Run 'yadm init' first." >&2
    return 1
  fi

  echo "Setting up DotRun to work with yadm repository..."
  echo "YADM repo root: $yadm_repo_root"

  # Create DotRun directory structure within yadm repo
  local yadm_drun_dir="$yadm_repo_root/.config/dotrun"

  if [[ -d "$yadm_drun_dir" ]]; then
    echo "DotRun directory already exists in yadm repo: $yadm_drun_dir"
  else
    echo "Creating DotRun directory in yadm repo..."
    mkdir -p "$yadm_drun_dir"/{bin,helpers,aliases,configs}

    # Create symlink from current config to yadm-managed location
    if [[ -d "$DR_CONFIG" && "$DR_CONFIG" != "$yadm_drun_dir" ]]; then
      echo "Migrating existing DotRun config to yadm..."

      # Copy existing content
      [[ -d "$DR_CONFIG/bin" ]] && cp -r "$DR_CONFIG/bin"/* "$yadm_drun_dir/bin/" 2>/dev/null || true
      [[ -d "$DR_CONFIG/helpers" ]] && cp -r "$DR_CONFIG/helpers"/* "$yadm_drun_dir/helpers/" 2>/dev/null || true
      [[ -d "$DR_CONFIG/aliases" ]] && cp -r "$DR_CONFIG/aliases"/* "$yadm_drun_dir/aliases/" 2>/dev/null || true
      [[ -d "$DR_CONFIG/configs" ]] && cp -r "$DR_CONFIG/configs"/* "$yadm_drun_dir/configs/" 2>/dev/null || true

      # Backup old config
      mv "$DR_CONFIG" "$DR_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
      echo "  ✓ Backed up existing config"
    fi

    # Create symlink
    ln -sf "$yadm_drun_dir" "$DR_CONFIG"
    echo "  ✓ Created symlink: $DR_CONFIG -> $yadm_drun_dir"
  fi

  # Create .gitignore for cache
  local gitignore_file="$yadm_drun_dir/.gitignore"
  if [[ ! -f "$gitignore_file" ]]; then
    cat > "$gitignore_file" << 'EOF'
# DotRun .gitignore
# Cache should not be committed
.cache/
*.tmp
*.bak
EOF
    echo "  ✓ Created .gitignore for cache"
  fi

  # Add to yadm
  yadm add "$yadm_drun_dir"
  echo "  ✓ Added DotRun directory to yadm"

  echo
  echo "DotRun is now integrated with yadm!"
  echo "Your personal scripts will be version controlled with your dotfiles."
  echo
  echo "Next steps:"
  echo "  1. Add your scripts: dr add myscript"
  echo "  2. Add collections: dr collections add <github-url>"
  echo "  3. Import resources: dr collections"
  echo "  4. Commit changes: yadm commit -m 'Add DotRun setup'"

  return 0
}
