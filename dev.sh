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

  # Step 1: Copy dr binary and VERSION file
  info "Step 1/5: Updating dr binary and version file..."
  ln -sf "$SCRIPT_DIR/core/shared/dotrun/dr" "$TOOL_DIR/dr"
  chmod +x "$TOOL_DIR/dr"

  # Copy VERSION file if it exists
  if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
    ln -sf "$SCRIPT_DIR/VERSION" "$TOOL_DIR/VERSION"
    success "Binary and VERSION file updated: $TOOL_DIR/dr"
  else
    warning "VERSION file not found in project root"
    success "Binary updated: $TOOL_DIR/dr"
  fi

  # Step 2: Copy .dr_config_loader
  info "Step 2/5: Updating config loader..."
  ln -sf "$SCRIPT_DIR/core/shared/dotrun/.dr_config_loader" "$TOOL_DIR/.dr_config_loader"
  success "Config loader updated: $TOOL_DIR/.dr_config_loader"

  # Step 3: Copy shell integration files
  info "Step 3/5: Updating shell integration files..."

  # Create shell directory structure
  mkdir -p "$TOOL_DIR/shell/bash"
  mkdir -p "$TOOL_DIR/shell/zsh"
  mkdir -p "$TOOL_DIR/shell/fish"

  # Symlink bash files (loop through each file to ensure proper symlink creation)
  if [[ -d "$SCRIPT_DIR/core/shared/dotrun/shell/bash" ]]; then
    for file in "$SCRIPT_DIR/core/shared/dotrun/shell/bash"/*; do
      [[ -f "$file" ]] || continue
      filename=$(basename "$file")
      ln -sf "$file" "$TOOL_DIR/shell/bash/$filename"
    done
    success "Bash integration files updated ($(ls -1 "$SCRIPT_DIR/core/shared/dotrun/shell/bash" | wc -l) files)"
  fi

  # Symlink zsh files (loop through each file to ensure proper symlink creation)
  if [[ -d "$SCRIPT_DIR/core/shared/dotrun/shell/zsh" ]]; then
    for file in "$SCRIPT_DIR/core/shared/dotrun/shell/zsh"/*; do
      [[ -f "$file" ]] || continue
      filename=$(basename "$file")
      ln -sf "$file" "$TOOL_DIR/shell/zsh/$filename"
    done
    success "Zsh integration files updated ($(ls -1 "$SCRIPT_DIR/core/shared/dotrun/shell/zsh" | wc -l) files)"
  fi

  # Symlink fish files (loop through each file to ensure proper symlink creation)
  if [[ -d "$SCRIPT_DIR/core/shared/dotrun/shell/fish" ]]; then
    for file in "$SCRIPT_DIR/core/shared/dotrun/shell/fish"/*; do
      [[ -f "$file" ]] || continue
      filename=$(basename "$file")
      ln -sf "$file" "$TOOL_DIR/shell/fish/$filename"
    done
    success "Fish integration files updated ($(ls -1 "$SCRIPT_DIR/core/shared/dotrun/shell/fish" | wc -l) files)"
  fi

  # Step 4: Create/update symlink
  info "Step 4/5: Updating binary symlink..."

  mkdir -p "$BIN_LINK_DIR"

  echo "=========================================="
  echo "       dev setup Complete! ✓"
  echo "=========================================="
  echo ""

}

# Run main function
main "$@"
