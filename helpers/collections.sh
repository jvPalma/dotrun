#!/usr/bin/env bash
# Collection management helpers for DotRun
# Handles import/export of script collections from git repositories

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016

# Ensure required variables are set (when not sourced from main drun script)
DRUN_CONFIG="${DRUN_CONFIG:-$HOME/.config/dotrun}"
BIN_DIR="${BIN_DIR:-$DRUN_CONFIG/bin}"
DOC_DIR="${DOC_DIR:-$DRUN_CONFIG/docs}"

source "$DRUN_CONFIG/helpers/pkg.sh"
source "$DRUN_CONFIG/helpers/git.sh"

validatePkg git
validatePkg curl

# Collection metadata file
COLLECTION_METADATA=".drun-collection.yml"
COLLECTIONS_DIR="$DRUN_CONFIG/collections"

# Ensure collections directory exists
mkdir -p "$COLLECTIONS_DIR"

# ──────────────────────────────────────────────────────────────
# Collection Metadata Management
# ──────────────────────────────────────────────────────────────

# Create collection metadata file
create_collection_metadata() {
  local name="$1"
  local description="$2"
  local author="${3:-$(git config user.name 2>/dev/null || echo "Unknown")}"
  local version="${4:-1.0.0}"
  local metadata_file="$5"

  cat > "$metadata_file" << EOF
# DotRun Collection Metadata
name: "$name"
description: "$description"
author: "$author"
version: "$version"
created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
type: "drun-collection"

# Scripts included in this collection
scripts:
  # Example:
  # - name: "example-script"
  #   path: "bin/example-script.sh"
  #   description: "An example script"

# Dependencies (other collections this depends on)
dependencies: []

# Environment compatibility
environments:
  - "dev"
  - "staging" 
  - "prod"

# Team information (optional)
team:
  repo: ""
  contact: ""
EOF
}

# Parse collection metadata
parse_collection_metadata() {
  local metadata_file="$1"
  local key="$2"
  
  if [[ ! -f "$metadata_file" ]]; then
    echo "Error: Collection metadata not found: $metadata_file" >&2
    return 1
  fi
  
  # Simple YAML parser for basic key extraction
  grep "^$key:" "$metadata_file" | sed 's/^[^:]*: *"\?\([^"]*\)"\?$/\1/'
}

# Validate collection structure
validate_collection() {
  local collection_dir="$1"
  
  # Check for required metadata file
  if [[ ! -f "$collection_dir/$COLLECTION_METADATA" ]]; then
    echo "Error: Collection metadata file missing: $COLLECTION_METADATA" >&2
    return 1
  fi
  
  # Check for bin directory
  if [[ ! -d "$collection_dir/bin" ]]; then
    echo "Error: Collection bin directory missing" >&2
    return 1
  fi
  
  # Validate metadata format
  local name description
  name=$(parse_collection_metadata "$collection_dir/$COLLECTION_METADATA" "name")
  description=$(parse_collection_metadata "$collection_dir/$COLLECTION_METADATA" "description")
  
  if [[ -z "$name" || -z "$description" ]]; then
    echo "Error: Collection metadata incomplete (missing name or description)" >&2
    return 1
  fi
  
  return 0
}

# ──────────────────────────────────────────────────────────────
# Collection Import/Export
# ──────────────────────────────────────────────────────────────

# Import collection from git URL or local path
import_collection() {
  local source="$1"
  local target_name="$2"
  local temp_dir
  
  if [[ -z "$source" ]]; then
    echo "Error: Source URL or path required" >&2
    return 1
  fi
  
  # Create temporary directory for import
  temp_dir=$(mktemp -d)
  trap "rm -rf '$temp_dir'" EXIT
  
  echo "Importing collection from: $source"
  
  # Handle different source types
  if [[ "$source" =~ ^https?:// ]] || [[ "$source" =~ ^git@ ]]; then
    # Git repository URL
    echo "Cloning repository..."
    if ! git clone --depth 1 "$source" "$temp_dir/repo" 2>/dev/null; then
      echo "Error: Failed to clone repository: $source" >&2
      return 1
    fi
    local source_dir="$temp_dir/repo"
  elif [[ -d "$source" ]]; then
    # Local directory
    local source_dir="$source"
  else
    echo "Error: Invalid source. Must be git URL or local directory path" >&2
    return 1
  fi
  
  # Validate collection structure
  if ! validate_collection "$source_dir"; then
    return 1
  fi
  
  # Get collection name from metadata or use provided name
  local collection_name
  if [[ -n "$target_name" ]]; then
    collection_name="$target_name"
  else
    collection_name=$(parse_collection_metadata "$source_dir/$COLLECTION_METADATA" "name")
    collection_name=${collection_name// /-}  # Replace spaces with dashes
    collection_name=${collection_name,,}     # Convert to lowercase
  fi
  
  local target_dir="$COLLECTIONS_DIR/$collection_name"
  
  # Check if collection already exists
  if [[ -d "$target_dir" ]]; then
    echo "Warning: Collection '$collection_name' already exists at $target_dir"
    read -p "Overwrite existing collection? [y/N]: " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Import cancelled"
      return 1
    fi
    rm -rf "$target_dir"
  fi
  
  # Copy collection
  echo "Installing collection '$collection_name'..."
  mkdir -p "$target_dir"
  cp -r "$source_dir"/* "$target_dir/"
  
  # Install scripts to main bin directory with collection prefix
  if [[ -d "$source_dir/bin" ]]; then
    local scripts_installed=0
    while IFS= read -r -d '' script_file; do
      local script_name=$(basename "$script_file" .sh)
      local prefixed_name="${collection_name}/${script_name}"
      local target_script="$BIN_DIR/${collection_name}/${script_name}.sh"
      
      # Create collection subdirectory in bin
      mkdir -p "$(dirname "$target_script")"
      
      # Copy script with executable permissions
      cp "$script_file" "$target_script"
      chmod +x "$target_script"
      
      echo "  ✓ Installed script: $prefixed_name"
      ((scripts_installed++))
    done < <(find "$source_dir/bin" -name "*.sh" -type f -print0)
    
    echo "Successfully imported collection '$collection_name' with $scripts_installed scripts"
  fi
  
  # Copy documentation if it exists
  if [[ -d "$source_dir/docs" ]]; then
    local docs_target="$DOC_DIR/$collection_name"
    mkdir -p "$docs_target"
    cp -r "$source_dir/docs"/* "$docs_target/"
    echo "  ✓ Imported documentation"
  fi
  
  return 0
}

# Preview collection contents without importing
preview_collection() {
  local source="$1"
  local temp_dir
  
  if [[ -z "$source" ]]; then
    echo "Error: Source URL or path required" >&2
    return 1
  fi
  
  # Create temporary directory for preview
  temp_dir=$(mktemp -d)
  trap "rm -rf '$temp_dir'" EXIT
  
  echo "Fetching collection from: $source"
  
  # Handle different source types
  if [[ "$source" =~ ^https?:// ]] || [[ "$source" =~ ^git@ ]]; then
    # Git repository URL
    echo "Cloning repository..."
    if ! git clone --depth 1 "$source" "$temp_dir/repo" 2>/dev/null; then
      echo "Error: Failed to clone repository: $source" >&2
      return 1
    fi
    local source_dir="$temp_dir/repo"
  elif [[ -d "$source" ]]; then
    # Local directory
    local source_dir="$source"
  else
    echo "Error: Invalid source. Must be git URL or local directory path" >&2
    return 1
  fi
  
  # Validate collection structure
  if ! validate_collection "$source_dir"; then
    return 1
  fi
  
  # Get collection metadata
  local collection_name description version
  collection_name=$(parse_collection_metadata "$source_dir/$COLLECTION_METADATA" "name")
  description=$(parse_collection_metadata "$source_dir/$COLLECTION_METADATA" "description")
  version=$(parse_collection_metadata "$source_dir/$COLLECTION_METADATA" "version")
  
  echo
  echo "📦 Collection: $collection_name"
  echo "📝 Description: $description"
  [[ -n "$version" ]] && echo "🏷️  Version: $version"
  echo
  echo "📂 Available Scripts:"
  
  # Display scripts in drun -L format
  if [[ -d "$source_dir/bin" ]]; then
    local script_count=0
    find "$source_dir/bin" -name "*.sh" -type f | sort | while IFS= read -r script_file; do
      local rel_path="${script_file#"$source_dir/bin/"}"
      local script_name="${rel_path%.sh}"
      local doc_file="$source_dir/docs/${script_name}.md"
      
      # Check for category-based docs
      if [[ "$script_name" == */* ]]; then
        doc_file="$source_dir/docs/${script_name}.md"
      fi
      
      # Extract description from documentation
      local desc=""
      if [[ -f "$doc_file" ]]; then
        # Try to get description from first paragraph after title
        desc=$(awk '/^#/ {next} /^$/ {next} {print; exit}' "$doc_file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//')
        [[ -z "$desc" ]] && desc=$(grep -E "^(Description|##)" "$doc_file" 2>/dev/null | head -1 | sed 's/^[#[:space:]]*//')
      fi
      
      [[ -z "$desc" ]] && desc="No description available"
      
      # Format like drun -L
      printf "  %-30s %s\n" "$script_name" "$desc"
      ((script_count++))
    done
    
    echo
    echo "Total scripts: $(find "$source_dir/bin" -name "*.sh" -type f | wc -l)"
  else
    echo "  No scripts found"
  fi
  
  echo
  echo "To import this collection:"
  echo "  drun import $source"
  echo
  echo "To import a specific script:"
  echo "  drun import $source --pick <script-name>"
  
  return 0
}

# Import a single script from a collection
import_single_script() {
  local source="$1"
  local script_name="$2"
  local target_collection="${3:-imported}"
  local temp_dir
  
  if [[ -z "$source" || -z "$script_name" ]]; then
    echo "Error: Source and script name required" >&2
    return 1
  fi
  
  # Create temporary directory for import
  temp_dir=$(mktemp -d)
  trap "rm -rf '$temp_dir'" EXIT
  
  echo "Fetching collection from: $source"
  
  # Handle different source types
  if [[ "$source" =~ ^https?:// ]] || [[ "$source" =~ ^git@ ]]; then
    # Git repository URL
    if ! git clone --depth 1 "$source" "$temp_dir/repo" 2>/dev/null; then
      echo "Error: Failed to clone repository: $source" >&2
      return 1
    fi
    local source_dir="$temp_dir/repo"
  elif [[ -d "$source" ]]; then
    # Local directory
    local source_dir="$source"
  else
    echo "Error: Invalid source. Must be git URL or local directory path" >&2
    return 1
  fi
  
  # Validate collection structure
  if ! validate_collection "$source_dir"; then
    return 1
  fi
  
  # Find the requested script
  local script_file="$source_dir/bin/${script_name}.sh"
  if [[ ! -f "$script_file" ]]; then
    echo "Error: Script '$script_name' not found in collection" >&2
    echo "Available scripts:"
    find "$source_dir/bin" -name "*.sh" -type f | sed "s|$source_dir/bin/||; s|\.sh$||" | sort
    return 1
  fi
  
  # Create target directories
  local target_script_dir="$BIN_DIR/$target_collection"
  local target_docs_dir="$DOC_DIR/$target_collection"
  
  mkdir -p "$target_script_dir/$(dirname "$script_name")" 2>/dev/null || true
  mkdir -p "$target_docs_dir/$(dirname "$script_name")" 2>/dev/null || true
  
  # Copy the script
  local target_script="$target_script_dir/${script_name}.sh"
  cp "$script_file" "$target_script"
  chmod +x "$target_script"
  
  # Copy documentation if it exists
  local doc_file="$source_dir/docs/${script_name}.md"
  if [[ -f "$doc_file" ]]; then
    local target_doc="$target_docs_dir/${script_name}.md"
    cp "$doc_file" "$target_doc"
    echo "  ✓ Imported documentation"
  fi
  
  echo "✓ Successfully imported script: $target_collection/$script_name"
  echo "Run with: drun $target_collection/$script_name"
  
  return 0
}

# Export collection to specified directory
export_collection() {
  local collection_name="$1"
  local export_path="$2"
  local include_git="${3:-false}"
  
  if [[ -z "$collection_name" || -z "$export_path" ]]; then
    echo "Error: Collection name and export path required" >&2
    return 1
  fi
  
  # Check if collection exists in bin directory
  local collection_bin_dir="$BIN_DIR/$collection_name"
  if [[ ! -d "$collection_bin_dir" ]]; then
    echo "Error: Collection '$collection_name' not found in $collection_bin_dir" >&2
    return 1
  fi
  
  echo "Exporting collection '$collection_name' to: $export_path"
  
  # Create export directory
  mkdir -p "$export_path"
  
  # Create bin directory and copy scripts
  local export_bin_dir="$export_path/bin"
  mkdir -p "$export_bin_dir"
  cp -r "$collection_bin_dir"/* "$export_bin_dir/"
  
  # Copy documentation if it exists
  local collection_docs_dir="$DOC_DIR/$collection_name"
  if [[ -d "$collection_docs_dir" ]]; then
    local export_docs_dir="$export_path/docs"
    mkdir -p "$export_docs_dir"
    cp -r "$collection_docs_dir"/* "$export_docs_dir/"
    echo "  ✓ Exported documentation"
  fi
  
  # Check if collection metadata exists
  local collection_metadata="$COLLECTIONS_DIR/$collection_name/$COLLECTION_METADATA"
  if [[ -f "$collection_metadata" ]]; then
    cp "$collection_metadata" "$export_path/"
    echo "  ✓ Exported metadata"
  else
    # Create basic metadata
    create_collection_metadata "$collection_name" "Exported DotRun collection" "" "1.0.0" "$export_path/$COLLECTION_METADATA"
    echo "  ✓ Created basic metadata"
  fi
  
  # Initialize git repository if requested
  if [[ "$include_git" == "true" ]]; then
    (
      cd "$export_path"
      git init
      git add .
      git commit -m "Initial commit: Export collection '$collection_name'"
      echo "  ✓ Initialized git repository"
    )
  fi
  
  echo "Successfully exported collection '$collection_name'"
  return 0
}

# List available collections
list_collections() {
  local show_details="${1:-false}"
  
  echo "Available collections:"
  
  if [[ ! -d "$COLLECTIONS_DIR" ]] || [[ -z "$(ls -A "$COLLECTIONS_DIR" 2>/dev/null)" ]]; then
    echo "  No collections installed"
    return 0
  fi
  
  for collection_dir in "$COLLECTIONS_DIR"/*; do
    if [[ -d "$collection_dir" ]]; then
      local collection_name=$(basename "$collection_dir")
      local metadata_file="$collection_dir/$COLLECTION_METADATA"
      
      if [[ "$show_details" == "true" && -f "$metadata_file" ]]; then
        local description version author
        description=$(parse_collection_metadata "$metadata_file" "description")
        version=$(parse_collection_metadata "$metadata_file" "version")
        author=$(parse_collection_metadata "$metadata_file" "author")
        
        echo "  📦 $collection_name (v$version)"
        echo "     Description: $description"
        echo "     Author: $author"
        
        # Count scripts
        local script_count=0
        if [[ -d "$BIN_DIR/$collection_name" ]]; then
          script_count=$(find "$BIN_DIR/$collection_name" -name "*.sh" -type f | wc -l)
        fi
        echo "     Scripts: $script_count"
        echo
      else
        echo "  📦 $collection_name"
      fi
    fi
  done
}

# Remove collection
remove_collection() {
  local collection_name="$1"
  local force="${2:-false}"
  
  if [[ -z "$collection_name" ]]; then
    echo "Error: Collection name required" >&2
    return 1
  fi
  
  local collection_dir="$COLLECTIONS_DIR/$collection_name"
  local collection_bin_dir="$BIN_DIR/$collection_name"
  local collection_docs_dir="$DOC_DIR/$collection_name"
  
  # Check if collection exists
  if [[ ! -d "$collection_dir" && ! -d "$collection_bin_dir" ]]; then
    echo "Error: Collection '$collection_name' not found" >&2
    return 1
  fi
  
  if [[ "$force" != "true" ]]; then
    echo "This will remove the collection '$collection_name' and all its scripts."
    read -p "Are you sure? [y/N]: " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Removal cancelled"
      return 1
    fi
  fi
  
  # Remove collection files
  [[ -d "$collection_dir" ]] && rm -rf "$collection_dir"
  [[ -d "$collection_bin_dir" ]] && rm -rf "$collection_bin_dir"
  [[ -d "$collection_docs_dir" ]] && rm -rf "$collection_docs_dir"
  
  echo "Successfully removed collection '$collection_name'"
  return 0
}

# ──────────────────────────────────────────────────────────────
# YADM Integration
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
    mkdir -p "$yadm_drun_dir"/{bin,docs,helpers,collections}
    
    # Create symlink from current config to yadm-managed location
    if [[ -d "$DRUN_CONFIG" && "$DRUN_CONFIG" != "$yadm_drun_dir" ]]; then
      echo "Migrating existing DotRun config to yadm..."
      
      # Copy existing content
      if [[ -d "$DRUN_CONFIG/bin" ]]; then
        cp -r "$DRUN_CONFIG/bin"/* "$yadm_drun_dir/bin/" 2>/dev/null || true
      fi
      if [[ -d "$DRUN_CONFIG/docs" ]]; then
        cp -r "$DRUN_CONFIG/docs"/* "$yadm_drun_dir/docs/" 2>/dev/null || true
      fi
      if [[ -d "$DRUN_CONFIG/helpers" ]]; then
        cp -r "$DRUN_CONFIG/helpers"/* "$yadm_drun_dir/helpers/" 2>/dev/null || true
      fi
      
      # Backup old config
      mv "$DRUN_CONFIG" "$DRUN_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
      echo "  ✓ Backed up existing config"
    fi
    
    # Create symlink
    ln -sf "$yadm_drun_dir" "$DRUN_CONFIG"
    echo "  ✓ Created symlink: $DRUN_CONFIG -> $yadm_drun_dir"
  fi
  
  # Create .gitignore for collections (they should be managed separately)
  local gitignore_file="$yadm_drun_dir/.gitignore"
  if [[ ! -f "$gitignore_file" ]]; then
    cat > "$gitignore_file" << 'EOF'
# DotRun .gitignore
# Collections are managed separately and should not be committed to personal dotfiles
collections/
*.tmp
*.bak
EOF
    echo "  ✓ Created .gitignore for collections"
  fi
  
  # Add to yadm
  yadm add "$yadm_drun_dir"
  echo "  ✓ Added DotRun directory to yadm"
  
  echo
  echo "DotRun is now integrated with yadm!"
  echo "Your personal scripts will be version controlled with your dotfiles."
  echo "Collections can be imported separately and are excluded from your personal repo."
  echo
  echo "Next steps:"
  echo "  1. Add your scripts: drun add myscript"
  echo "  2. Import team collections: drun import <team-repo-url>"
  echo "  3. Commit changes: yadm commit -m 'Add DotRun setup'"
  
  return 0
}