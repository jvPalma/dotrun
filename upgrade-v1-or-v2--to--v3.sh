#!/usr/bin/env bash
### DOC
# upgrade.sh - Upgrade DotRun tool files in ~/.local/share/dotrun
#
# This script updates ONLY the tool files (binary and shell integration files)
# in ~/.local/share/dotrun/ without touching your user content in ~/.config/dotrun/.
#
# WHAT THIS SCRIPT DOES:
# ✓ Copies the dr binary to ~/.local/share/dotrun/dr
# ✓ Updates shell integration files (bash, zsh, fish completions, loaders)
# ✓ Updates the .dr_config_loader
# ✓ Preserves your scripts, aliases, and configs in ~/.config/dotrun/
# ✓ Creates symlink from ~/.local/bin/dr to the binary
#
# WHAT THIS SCRIPT DOES NOT DO:
# ✗ Does not modify ~/.config/dotrun/ (your user content)
# ✗ Does not modify your scripts
# ✗ Does not modify your aliases or configs
# ✗ Does not modify your .drrc file
#
# WHEN TO USE:
# - When testing DotRun development changes
# - When upgrading to a new version manually
# - When you want to update the tool without reinstalling everything
#
# USAGE:
#   ./upgrade.sh              # Upgrade tool files
#   ./upgrade.sh --help       # Show this help
#
# NOTE: This is useful for development and testing. For production upgrades,
#       use the full installer: ./install.sh
### DOC

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
  cp "$SCRIPT_DIR/core/shared/dotrun/dr" "$TOOL_DIR/dr"
  chmod +x "$TOOL_DIR/dr"

  # Copy VERSION file if it exists
  if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
    cp "$SCRIPT_DIR/VERSION" "$TOOL_DIR/VERSION"
    success "Binary and VERSION file updated: $TOOL_DIR/dr"
  else
    warning "VERSION file not found in project root"
    success "Binary updated: $TOOL_DIR/dr"
  fi

  # Step 2: Copy .dr_config_loader
  info "Step 2/5: Updating config loader..."
  cp "$SCRIPT_DIR/core/shared/dotrun/.dr_config_loader" "$TOOL_DIR/.dr_config_loader"
  success "Config loader updated: $TOOL_DIR/.dr_config_loader"

  # Step 3: Copy shell integration files
  info "Step 3/5: Updating shell integration files..."

  # Create shell directory structure
  mkdir -p "$TOOL_DIR/shell/bash"
  mkdir -p "$TOOL_DIR/shell/zsh"
  mkdir -p "$TOOL_DIR/shell/fish"

  # Copy bash files
  if [[ -d "$SCRIPT_DIR/core/shared/dotrun/shell/bash" ]]; then
    cp -r "$SCRIPT_DIR/core/shared/dotrun/shell/bash"/* "$TOOL_DIR/shell/bash/"
    success "Bash integration files updated"
  fi

  # Copy zsh files
  if [[ -d "$SCRIPT_DIR/core/shared/dotrun/shell/zsh" ]]; then
    cp -r "$SCRIPT_DIR/core/shared/dotrun/shell/zsh"/* "$TOOL_DIR/shell/zsh/"
    success "Zsh integration files updated"
  fi

  # Copy fish files
  if [[ -d "$SCRIPT_DIR/core/shared/dotrun/shell/fish" ]]; then
    cp -r "$SCRIPT_DIR/core/shared/dotrun/shell/fish"/* "$TOOL_DIR/shell/fish/"
    success "Fish integration files updated"
  fi

  # Step 4: Copy Core and Helpers files
  info "Step 4/5: Updating core and helper files..."

  # Create Core directory structure
  mkdir -p "$TOOL_DIR/core"

  # Copy Core files
  if [[ -d "$SCRIPT_DIR/core/shared/dotrun/core" ]]; then
    cp -r "$SCRIPT_DIR/core/shared/dotrun/core"/* "$TOOL_DIR/core/"
    success "Core files updated"
  fi

  # Create Helpers directory structure
  mkdir -p "$TOOL_DIR/helpers"

  # Copy Helpers files
  if [[ -d "$SCRIPT_DIR/core/shared/dotrun/helpers" ]]; then
    cp -r "$SCRIPT_DIR/core/shared/dotrun/helpers"/* "$TOOL_DIR/helpers/"
    success "Helper files updated"
  fi

  # Step 5: Create/update symlink
  info "Step 5/5: Updating binary symlink..."

  mkdir -p "$BIN_LINK_DIR"

  # Remove old symlink if exists
  if [[ -L "$BIN_LINK_DIR/dr" ]]; then
    rm "$BIN_LINK_DIR/dr"
  elif [[ -f "$BIN_LINK_DIR/dr" ]]; then
    warning "Found non-symlink file at $BIN_LINK_DIR/dr"
    warning "Moving to $BIN_LINK_DIR/dr.backup"
    mv "$BIN_LINK_DIR/dr" "$BIN_LINK_DIR/dr.backup"
  fi

  # Create new symlink
  ln -s "$TOOL_DIR/dr" "$BIN_LINK_DIR/dr"
  success "Symlink created: $BIN_LINK_DIR/dr -> $TOOL_DIR/dr"

  echo ""
  echo "=========================================="
  echo "       Upgrade Complete! ✓"
  echo "=========================================="
  echo ""

  info "Tool files have been upgraded in: $TOOL_DIR"
  info "Your user content remains unchanged in: ~/.config/dotrun/"
  echo ""

  # Verify dr is accessible
  if command -v dr &>/dev/null; then
    DR_VERSION=$(dr --version 2>/dev/null || echo "unknown")
    success "dr command is accessible (version: $DR_VERSION)"
  else
    warning "dr command not found in PATH"
    warning "Make sure ~/.local/bin is in your PATH"
    echo ""
    echo "  Add to your shell config (~/.bashrc or ~/.zshrc):"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi

  echo ""
  info "To apply shell integration changes, reload your shell or run:"
  echo "  source ~/.drrc"
  echo ""

  # Check for old structure and provide migration instructions
  show_migration_instructions
}

# Show migration instructions for old DotRun structure
show_migration_instructions() {
  local CONFIG_DIR="$HOME/.config/dotrun"
  local needs_migration=false

  # Check if any old structure exists
  if [[ -d "$CONFIG_DIR/bin" ]] || [[ -d "$CONFIG_DIR/aliases/.d.aliases" ]] \
    || [[ -d "$CONFIG_DIR/config" ]] || [[ -f "$CONFIG_DIR/.drun_config_loader" ]]; then
    needs_migration=true
  fi

  if [[ "$needs_migration" == false ]]; then
    return
  fi

  echo ""
  echo "=========================================="
  echo -e "${YELLOW}  MIGRATION REQUIRED${NC}"
  echo "=========================================="
  echo ""
  warning "Old DotRun directory structure detected!"
  echo ""
  info "Please migrate your files to the new structure:"
  echo ""

  # Scripts migration
  if [[ -d "$CONFIG_DIR/bin" ]]; then
    echo -e "${BLUE}📁 Scripts Directory:${NC}"
    echo -e "  ${YELLOW}OLD:${NC} ~/.config/dotrun/bin/"
    echo -e "  ${GREEN}NEW:${NC} ~/.config/dotrun/scripts/"
    echo -e "  ${BLUE}Action:${NC} mv ~/.config/dotrun/bin ~/.config/dotrun/scripts"
    echo ""
  fi

  # Aliases migration
  if [[ -d "$CONFIG_DIR/aliases/.d.aliases" ]] || [[ -f "$CONFIG_DIR/aliases/.aliases" ]] || [[ -d "$CONFIG_DIR/aliases/shell" ]]; then
    echo -e "${BLUE}📝 Aliases Files:${NC}"

    if [[ -d "$CONFIG_DIR/aliases/.d.aliases" ]]; then
      echo -e "  ${YELLOW}OLD:${NC} ~/.config/dotrun/aliases/.d.aliases/*"
      echo -e "  ${GREEN}NEW:${NC} ~/.config/dotrun/aliases/*.aliases"
      echo -e "  ${BLUE}Action:${NC} mv ~/.config/dotrun/aliases/.d.aliases/* ~/.config/dotrun/aliases/"
      echo -e "  ${BLUE}Action:${NC} rmdir ~/.config/dotrun/aliases/.d.aliases"
      echo ""
    fi

    if [[ -f "$CONFIG_DIR/aliases/.aliases" ]]; then
      echo -e "  ${YELLOW}OLD:${NC} ~/.config/dotrun/aliases/.aliases"
      echo -e "  ${GREEN}NEW:${NC} ~/.config/dotrun/aliases/10.main.aliases ${BLUE}(recommended)${NC}"
      echo -e "  ${BLUE}Action:${NC} mv ~/.config/dotrun/aliases/.aliases ~/.config/dotrun/aliases/10.main.aliases"
      echo ""
    fi

    if [[ -d "$CONFIG_DIR/aliases/shell" ]]; then
      echo -e "  ${RED}REMOVE:${NC} ~/.config/dotrun/aliases/shell/ ${RED}(deprecated)${NC}"
      echo -e "  ${BLUE}Action:${NC} rm -rf ~/.config/dotrun/aliases/shell"
      echo ""
    fi
  fi

  # Configs migration
  if [[ -d "$CONFIG_DIR/config" ]]; then
    echo -e "${BLUE}⚙️  Config Files:${NC}"
    echo -e "  ${YELLOW}OLD:${NC} ~/.config/dotrun/config/"
    echo -e "  ${GREEN}NEW:${NC} ~/.config/dotrun/configs/"
    echo -e "  ${BLUE}Action:${NC} mv ~/.config/dotrun/config ~/.config/dotrun/configs"
    echo ""

    if [[ -d "$CONFIG_DIR/config/.dotrun_config.d" ]]; then
      echo -e "  ${YELLOW}OLD:${NC} ~/.config/dotrun/config/.dotrun_config.d/*"
      echo -e "  ${GREEN}NEW:${NC} ~/.config/dotrun/configs/*.config"
      echo -e "  ${BLUE}Action:${NC} Move files from .dotrun_config.d/ to configs/ and add .config extension"
      echo ""
    fi

    if [[ -f "$CONFIG_DIR/config/.dotrun_config" ]]; then
      echo -e "  ${YELLOW}OLD:${NC} ~/.config/dotrun/config/.dotrun_config"
      echo -e "  ${GREEN}NEW:${NC} ~/.config/dotrun/configs/10.main.config ${BLUE}(recommended)${NC}"
      echo -e "  ${BLUE}Action:${NC} mv ~/.config/dotrun/config/.dotrun_config ~/.config/dotrun/configs/10.main.config"
      echo ""
    fi

    if [[ -f "$CONFIG_DIR/config/.dotrun_config.secure" ]]; then
      echo -e "  ${YELLOW}OLD:${NC} ~/.config/dotrun/config/.dotrun_config.secure"
      echo -e "  ${GREEN}NEW:${NC} ~/.config/dotrun/configs/20.secure.config ${BLUE}(recommended)${NC}"
      echo -e "  ${BLUE}Action:${NC} mv ~/.config/dotrun/config/.dotrun_config.secure ~/.config/dotrun/configs/20.secure.config"
      echo ""
    fi

    if [[ -d "$CONFIG_DIR/config/shell" ]]; then
      echo -e "  ${RED}REMOVE:${NC} ~/.config/dotrun/config/shell/ ${RED}(deprecated)${NC}"
      echo -e "  ${BLUE}Action:${NC} rm -rf ~/.config/dotrun/config/shell"
      echo ""
    fi
  fi

  # Docs migration
  if [[ -d "$CONFIG_DIR/docs" ]]; then
    echo -e "${BLUE}📚 Documentation:${NC}"
    echo -e "  ${YELLOW}DEPRECATED:${NC} ~/.config/dotrun/docs/"
    echo -e "  ${BLUE}Action:${NC} Move to a location of your choice or to scripts/docs/"
    echo ""
  fi

  # Deprecated files
  local deprecated_files=(
    ".drun_config_loader"
    ".gitignore"
    "drun_completion.bash"
    "drun_completion.fish"
    "drun_completion.zsh"
    "example_commands.txt"
    "README.md"
  )

  local found_deprecated=false
  for file in "${deprecated_files[@]}"; do
    if [[ -f "$CONFIG_DIR/$file" ]]; then
      if [[ "$found_deprecated" == false ]]; then
        echo -e "${BLUE}🗑️  Deprecated Files (safe to remove):${NC}"
        found_deprecated=true
      fi
      echo -e "  ${RED}✗${NC} ~/.config/dotrun/$file"
    fi
  done

  if [[ "$found_deprecated" == true ]]; then
    echo ""
    echo -e "  ${BLUE}Action:${NC} Remove all deprecated files:"
    echo -e "  cd ~/.config/dotrun && rm -f .drun_config_loader .gitignore"
    echo -e "  rm -f drun_completion.{bash,fish,zsh} example_commands.txt README.md"
    echo ""
  fi

  echo "=========================================="
  echo -e "${YELLOW}⚠  Important Notes:${NC}"
  echo "=========================================="
  echo ""
  echo -e "  ${BLUE}•${NC} All files inside ${YELLOW}~/.config/dotrun/bin${NC} keep same organization"
  echo -e "  ${BLUE}•${NC} Config files in ${YELLOW}.dotrun_config.d${NC} should have ${GREEN}.config${NC} extension"
  echo -e "  ${BLUE}•${NC} Alias files should have ${GREEN}.aliases${NC} extension"
  echo -e "  ${BLUE}•${NC} Backup your files before migrating!"
  echo ""
  echo -e "${GREEN}💡 Tip:${NC} Run these commands one by one and verify each step."
  echo ""
}

# Run main function
main "$@"
