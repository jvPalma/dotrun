# Backup Scripts

Collection of backup and file management scripts for personal and development use.

## Daily Document Backup

Simple daily backup script for important documents and configuration files.

```bash
#!/usr/bin/env bash
### DOC
# Daily backup of important documents and configs
### DOC
set -euo pipefail

# Configuration
BACKUP_DIR="$HOME/Backups/$(date +%Y-%m-%d)"
DOCUMENTS="$HOME/Documents"
CONFIG_DIR="$HOME/.config"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Starting daily backup to $BACKUP_DIR"

# Backup documents
if [ -d "$DOCUMENTS" ]; then
    echo "Backing up Documents..."
    cp -r "$DOCUMENTS" "$BACKUP_DIR/Documents"
fi

# Backup important config files
echo "Backing up configurations..."
mkdir -p "$BACKUP_DIR/config"

# Backup specific config directories
for config in dotrun fish git; do
    if [ -d "$CONFIG_DIR/$config" ]; then
        cp -r "$CONFIG_DIR/$config" "$BACKUP_DIR/config/"
    fi
done

# Backup dotfiles
for dotfile in .bashrc .zshrc .gitconfig .drunrc; do
    if [ -f "$HOME/$dotfile" ]; then
        cp "$HOME/$dotfile" "$BACKUP_DIR/"
    fi
done

echo "✅ Daily backup completed at $(date)"
echo "📁 Backup location: $BACKUP_DIR"
```

**Usage:** `drun add backup/daily && drun backup/daily`

---

## Project Backup

Backup script for development projects with git repository handling.

```bash
#!/usr/bin/env bash
### DOC
# Backup development projects with git status
### DOC
set -euo pipefail

source "$DRUN_CONFIG/helpers/git.sh"

# Configuration
PROJECTS_DIR="$HOME/projects"
BACKUP_ROOT="$HOME/Backups/projects"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

mkdir -p "$BACKUP_DIR"

echo "🚀 Starting project backup to $BACKUP_DIR"

# Find all git repositories
while IFS= read -r -d '' repo_dir; do
    repo_name=$(basename "$repo_dir")
    echo "📦 Processing: $repo_name"

    cd "$repo_dir"

    # Check git status
    if git status --porcelain | grep -q .; then
        echo "  ⚠️  Uncommitted changes detected"
        git status --short
    fi

    # Check if branch is ahead of remote
    if git status | grep -q "ahead"; then
        echo "  📤 Unpushed commits detected"
    fi

    # Create backup
    cp -r "$repo_dir" "$BACKUP_DIR/$repo_name"
    echo "  ✅ Backed up successfully"

done < <(find "$PROJECTS_DIR" -name ".git" -type d -print0 | sed 's|/.git||g' | tr '\n' '\0')

echo "✅ Project backup completed: $BACKUP_DIR"
```

**Usage:** `drun add backup/projects && drun backup/projects`

---

## Configuration Sync

Sync important configuration files to a backup location.

```bash
#!/usr/bin/env bash
### DOC
# Sync configuration files for dotfiles management
### DOC
set -euo pipefail

# Configuration files to sync
declare -A CONFIG_FILES=(
    ["$HOME/.drunrc"]="shell/drunrc"
    ["$HOME/.gitconfig"]="git/gitconfig"
    ["$HOME/.config/fish/config.fish"]="shell/config.fish"
    ["$HOME/.config/dotrun"]="dotrun/"
)

SYNC_DIR="${1:-$HOME/dotfiles-backup}"
mkdir -p "$SYNC_DIR"

echo "🔄 Syncing configurations to $SYNC_DIR"

for src in "${!CONFIG_FILES[@]}"; do
    dest="$SYNC_DIR/${CONFIG_FILES[$src]}"

    if [ -e "$src" ]; then
        echo "📋 Syncing: $(basename "$src")"
        mkdir -p "$(dirname "$dest")"

        if [ -d "$src" ]; then
            cp -r "$src" "$dest"
        else
            cp "$src" "$dest"
        fi
    else
        echo "⚠️  Not found: $src"
    fi
done

echo "✅ Configuration sync completed"
echo "📁 Files synced to: $SYNC_DIR"
```

**Usage:** `drun add backup/config-sync && drun backup/config-sync [destination]`

---

## Selective Directory Backup

Backup specific directories with exclusion patterns.

```bash
#!/usr/bin/env bash
### DOC
# Selective backup with exclusion patterns
### DOC
set -euo pipefail

# Default exclusions (can be customized)
EXCLUDES=(
    "node_modules"
    ".git"
    "dist"
    "build"
    ".next"
    "coverage"
    "*.log"
    ".DS_Store"
    "Thumbs.db"
)

# Function to build exclude arguments
build_excludes() {
    local exclude_args=()
    for pattern in "${EXCLUDES[@]}"; do
        exclude_args+=("--exclude=$pattern")
    done
    echo "${exclude_args[@]}"
}

# Main backup function
backup_directory() {
    local source="$1"
    local destination="$2"
    local name="$(basename "$source")"

    echo "📦 Backing up: $name"
    echo "   Source: $source"
    echo "   Destination: $destination"

    # Create destination directory
    mkdir -p "$destination"

    # Use tar with exclusions for better control
    tar $(build_excludes) -cf - -C "$(dirname "$source")" "$(basename "$source")" | \
        tar -xf - -C "$destination"

    echo "✅ Backup completed for $name"
}

# Usage
if [ $# -lt 2 ]; then
    echo "Usage: $0 <source_directory> <backup_destination>"
    echo "Example: $0 ~/projects ~/Backups/projects-$(date +%Y%m%d)"
    exit 1
fi

SOURCE="$1"
DESTINATION="$2"

if [ ! -d "$SOURCE" ]; then
    echo "❌ Source directory does not exist: $SOURCE"
    exit 1
fi

backup_directory "$SOURCE" "$DESTINATION"
```

**Usage:** `drun add backup/selective && drun backup/selective ~/projects ~/Backups/projects`
