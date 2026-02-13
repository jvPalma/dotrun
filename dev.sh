#!/usr/bin/env bash
clear
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
TOOL_DIR="$HOME/.local/share/dotrun"
BIN_LINK_DIR="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Show help
show_help() {
  awk '/^### DOC/,/^### DOC/ {if (!/^### DOC/) print}' "$0"
  exit 0
}

# Handle --help flag
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  show_help
fi

# Logging functions
info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

success() {
  echo -e "${GREEN}✓${NC} $1"
}

warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

error() {
  echo -e "${RED}✗${NC} $1"
}
# Main upgrade function
main() {
  echo ""
  echo "=========================================="
  echo "  DotRun Tool Files Upgrade Script"
  echo "=========================================="
  echo ""

  info "Upgrading DotRun tool files in $TOOL_DIR"
  echo ""

  # Verify we're running from DotRun project directory
  if [[ ! -f "$SCRIPT_DIR/core/shared/dotrun/dr" ]]; then
    error "Cannot find 'dr' binary at core/shared/dotrun/dr"
    error "Please run this script from the DotRun project root"
    exit 1
  fi

  if [[ ! -d "$SCRIPT_DIR/core/shared" ]]; then
    error "Cannot find 'core/shared' directory"
    error "Please run this script from the DotRun project root"
    exit 1
  fi

  # Create tool directory if it doesn't exist
  if [[ ! -d "$TOOL_DIR" ]]; then
    warning "Tool directory does not exist: $TOOL_DIR"
    info "Creating directory..."
    mkdir -p "$TOOL_DIR"
    success "Created $TOOL_DIR"
  fi

  # Step 1: Copy dr binary
  info "Step 1/7: Updating dr binary..."
  ln -sf "$SCRIPT_DIR/core/shared/dotrun/dr" "$TOOL_DIR/dr"
  chmod +x "$TOOL_DIR/dr"
  success "Binary updated: $TOOL_DIR/dr"

  # Step 2: Copy .dr_config_loader
  info "Step 2/7: Updating config loader..."
  ln -sf "$SCRIPT_DIR/core/shared/dotrun/.dr_config_loader" "$TOOL_DIR/.dr_config_loader"
  success "Config loader updated: $TOOL_DIR/.dr_config_loader"

  # Step 3: Copy core directory
  info "Step 3/7: Updating core files..."

  # Create core directory structure
  mkdir -p "$TOOL_DIR/core/templates"

  # Symlink core files
  if [[ -d "$SCRIPT_DIR/core/shared/dotrun/core" ]]; then
    for file in "$SCRIPT_DIR/core/shared/dotrun/core"/*.sh; do
      [[ -f "$file" ]] || continue
      filename=$(basename "$file")
      ln -sf "$file" "$TOOL_DIR/core/$filename"
    done

    # Symlink template files if they exist
    if [[ -d "$SCRIPT_DIR/core/shared/dotrun/core/templates" ]]; then
      for file in "$SCRIPT_DIR/core/shared/dotrun/core/templates"/*; do
        [[ -f "$file" ]] || continue
        filename=$(basename "$file")
        ln -sf "$file" "$TOOL_DIR/core/templates/$filename"
      done
    fi

    # Symlink help-messages directory (deep tree — symlink the whole dir)
    if [[ -d "$SCRIPT_DIR/core/shared/dotrun/core/help-messages" ]]; then
      # Remove old copies/symlink to replace cleanly
      rm -rf "$TOOL_DIR/core/help-messages"
      ln -sf "$SCRIPT_DIR/core/shared/dotrun/core/help-messages" "$TOOL_DIR/core/help-messages"
    fi

    success "Core files updated"
  fi

  # Step 4: Copy helpers directory
  info "Step 4/7: Updating helper files..."

  # Create helpers directory
  mkdir -p "$TOOL_DIR/helpers"

  # Symlink helper files
  if [[ -d "$SCRIPT_DIR/core/shared/dotrun/helpers" ]]; then
    for file in "$SCRIPT_DIR/core/shared/dotrun/helpers"/*; do
      [[ -f "$file" ]] || continue
      filename=$(basename "$file")
      ln -sf "$file" "$TOOL_DIR/helpers/$filename"
    done
    success "Helper files updated"
  fi

  # Step 5: Copy VERSION file from correct location
  info "Step 5/7: Updating VERSION file..."
  if [[ -f "$SCRIPT_DIR/core/shared/dotrun/VERSION" ]]; then
    ln -sf "$SCRIPT_DIR/core/shared/dotrun/VERSION" "$TOOL_DIR/VERSION"
    success "VERSION file updated: $TOOL_DIR/VERSION"
  else
    warning "VERSION file not found at core/shared/dotrun/VERSION"
  fi

  # Step 6: Copy shell integration files
  info "Step 6/7: Updating shell integration files..."

  # Create shell directory structure
  mkdir -p "$TOOL_DIR/shell/bash"
  mkdir -p "$TOOL_DIR/shell/zsh"
  mkdir -p "$TOOL_DIR/shell/fish"

  # Clean stale symlinks in shell directories (from removed source files)
  for dir in "$TOOL_DIR/shell/bash" "$TOOL_DIR/shell/zsh" "$TOOL_DIR/shell/fish"; do
    find "$dir" -maxdepth 1 -type l ! -exec test -e {} \; -delete 2>/dev/null
  done

  # Symlink bash files (loop through each file to ensure proper symlink creation)
  if [[ -d "$SCRIPT_DIR/core/shared/dotrun/shell/bash" ]]; then
    for file in "$SCRIPT_DIR/core/shared/dotrun/shell/bash"/*; do
      [[ -f "$file" ]] || continue
      filename=$(basename "$file")
      ln -sf "$file" "$TOOL_DIR/shell/bash/$filename"
    done
    success "Bash integration files updated ($(find "$SCRIPT_DIR/core/shared/dotrun/shell/bash" -maxdepth 1 -type f | wc -l) files)"
  fi

  # Symlink zsh files (loop through each file to ensure proper symlink creation)
  if [[ -d "$SCRIPT_DIR/core/shared/dotrun/shell/zsh" ]]; then
    for file in "$SCRIPT_DIR/core/shared/dotrun/shell/zsh"/*; do
      [[ -f "$file" ]] || continue
      filename=$(basename "$file")
      ln -sf "$file" "$TOOL_DIR/shell/zsh/$filename"
    done
    # Symlink zsh completions subdir (fpath-based discovery for compinit)
    if [[ -d "$SCRIPT_DIR/core/shared/dotrun/shell/zsh/completions" ]]; then
      mkdir -p "$TOOL_DIR/shell/zsh/completions"
      for file in "$SCRIPT_DIR/core/shared/dotrun/shell/zsh/completions"/*; do
        [[ -e "$file" ]] || continue
        filename=$(basename "$file")
        ln -sf "$file" "$TOOL_DIR/shell/zsh/completions/$filename"
      done
    fi
    success "Zsh integration files updated ($(find "$SCRIPT_DIR/core/shared/dotrun/shell/zsh" -maxdepth 1 -type f | wc -l) files)"
  fi

  # Symlink fish files (loop through each file to ensure proper symlink creation)
  if [[ -d "$SCRIPT_DIR/core/shared/dotrun/shell/fish" ]]; then
    for file in "$SCRIPT_DIR/core/shared/dotrun/shell/fish"/*; do
      [[ -f "$file" ]] || continue
      filename=$(basename "$file")
      ln -sf "$file" "$TOOL_DIR/shell/fish/$filename"
    done
    success "Fish integration files updated ($(find "$SCRIPT_DIR/core/shared/dotrun/shell/fish" -maxdepth 1 -type f | wc -l) files)"
  fi

  # Step 7: Create/update symlink
  info "Step 7/7: Updating binary symlink..."

  mkdir -p "$BIN_LINK_DIR"

  echo "=========================================="
  echo "       dev setup Complete! ✓"
  echo "=========================================="
  echo ""

}

# Run main function
main "$@"
