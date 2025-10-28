#!/usr/bin/env bash

# DotRun Installer - Maximum Compatibility Edition
# Supports: Linux, macOS, Windows (WSL/Git Bash/Cygwin), BSD variants
# Works with: bash, zsh, fish shells

set -euo pipefail

INSTALL_CFG_PATH=${XDG_CONFIG_HOME:-$HOME/.config}
INSTALL_HOME="$HOME"

# ------------------------------------------------------------------
# Utility Functions
# ------------------------------------------------------------------

# Logging functions for better output
log_info() {
  printf "\033[1;34m[INFO]\033[0m %s\n" "$*"
}

log_warn() {
  printf "\033[1;33m[WARN]\033[0m %s\n" "$*" >&2
}

log_error() {
  printf "\033[1;31m[ERROR]\033[0m %s\n" "$*" >&2
}

log_success() {
  printf "\033[1;32m[SUCCESS]\033[0m %s\n" "$*"
}

# Detect operating system
detect_os() {
  case "$(uname -s)" in
    Linux*) echo "linux" ;;
    Darwin*) echo "macos" ;;
    CYGWIN*) echo "windows" ;;
    MINGW*) echo "windows" ;;
    MSYS*) echo "windows" ;;
    *BSD) echo "bsd" ;;
    FreeBSD*) echo "freebsd" ;;
    OpenBSD*) echo "openbsd" ;;
    NetBSD*) echo "netbsd" ;;
    DragonFly*) echo "dragonfly" ;;
    *)
      # Additional detection for Git Bash on Windows
      if [ -n "${MSYSTEM:-}" ]; then
        echo "windows"
      else
        echo "unknown"
      fi
      ;;
  esac
}

# Detect current shell
detect_shell() {
  # Check environment variables first (but not BASH_VERSION since bash scripts always set it)
  if [ -n "${FISH_VERSION:-}" ]; then
    echo "fish"
    return
  elif [ -n "${ZSH_VERSION:-}" ]; then
    echo "zsh"
    return
  fi

  # Check parent process chain to find the actual shell
  local ppid shell_name

  # Get parent process ID
  ppid="$(ps -p $$ -o ppid= 2>/dev/null | tr -d ' ')"

  # Check up to 3 levels of parent processes to find the shell
  for _ in 1 2 3; do
    if [ -n "$ppid" ] && [ "$ppid" != "1" ]; then
      shell_name="$(ps -p "$ppid" -o comm= 2>/dev/null)"
      case "$shell_name" in
        fish*)
          echo "fish"
          return
          ;;
        zsh*)
          echo "zsh"
          return
          ;;
        bash*)
          echo "bash"
          return
          ;;
      esac
      # Move up to parent's parent
      ppid="$(ps -p "$ppid" -o ppid= 2>/dev/null | tr -d ' ')"
    else
      break
    fi
  done

  # Fallback to SHELL environment variable
  case "${SHELL:-}" in
    *fish*) echo "fish" ;;
    *zsh*) echo "zsh" ;;
    *bash*) echo "bash" ;;
    *) echo "bash" ;; # Ultimate fallback
  esac
}

# Check if directory is writable
is_writable() {
  local dir="$1"
  [ -d "$dir" ] && [ -w "$dir" ]
}

# Check if directory is in PATH
is_in_path() {
  local dir="$1"
  case ":$PATH:" in
    *":$dir:"*) return 0 ;;
    *) return 1 ;;
  esac
}

# Get user's preferred shell config file
get_shell_config() {
  local shell="$1"
  case "$shell" in
    fish)
      echo "$INSTALL_HOME/.config/fish/config.fish"
      ;;
    zsh)
      if [ -f "$INSTALL_HOME/.zshrc" ]; then
        echo "$INSTALL_HOME/.zshrc"
      else
        echo "$INSTALL_HOME/.zprofile"
      fi
      ;;
    bash)
      if [ -f "$INSTALL_HOME/.bashrc" ]; then
        echo "$INSTALL_HOME/.bashrc"
      elif [ -f "$INSTALL_HOME/.bash_profile" ]; then
        echo "$INSTALL_HOME/.bash_profile"
      else
        echo "$INSTALL_HOME/.profile"
      fi
      ;;
    *)
      echo "$INSTALL_HOME/.profile"
      ;;
  esac
}

# Function to calculate file checksum (cross-platform)
get_checksum() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | cut -d' ' -f1
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$file" | cut -d' ' -f2
  else
    # Fallback to basic file comparison
    wc -c <"$file"
  fi
}

# Recursively copy files from source to destination
# Only copies if destination file doesn't exist (unless force_override is true)
copy_core_files_recursively() {
  local src="$1"
  local dst="$2"
  local force_override="${3:-false}"
  local section_name="${4:-files}"

  if [ ! -d "$src" ]; then
    log_warn "Source directory not found: $src"
    return 0
  fi

  log_info "📂 Copying $section_name from $(basename "$src")/"

  # Find all files recursively
  while IFS= read -r -d '' src_file; do
    # Calculate relative path from src
    local rel_path="${src_file#$src/}"
    local dst_file="$dst/$rel_path"

    # Create directory structure if needed
    mkdir -p "$(dirname "$dst_file")"

    if [ -f "$dst_file" ]; then
      # File exists - check if different
      if [ "$force_override" = "true" ]; then
        local src_checksum dst_checksum
        src_checksum="$(get_checksum "$src_file")"
        dst_checksum="$(get_checksum "$dst_file")"

        if [ "$src_checksum" != "$dst_checksum" ]; then
          log_info "  ✓ $rel_path (overwritten)"
          cp "$src_file" "$dst_file"
          # Preserve executable permissions
          if [ -x "$src_file" ]; then
            chmod +x "$dst_file"
          fi
        else
          log_info "  ✓ $rel_path (unchanged)"
        fi
      else
        log_info "  - $rel_path (skipped - already exists)"
      fi
    else
      # File doesn't exist - copy it
      log_info "  + $rel_path (new)"
      cp "$src_file" "$dst_file"
      # Preserve executable permissions
      if [ -x "$src_file" ]; then
        chmod +x "$dst_file"
      fi
    fi
  done < <(find "$src" -type f -print0)
}

# ------------------------------------------------------------------
# Main Installation Logic
# ------------------------------------------------------------------
main() {
  local os_type shell_type force_override=false

  # Check for force override argument
  if [ "${1:-}" = "--force" ] || [ "${1:-}" = "-f" ] || [ "${1:-}" = "override" ]; then
    force_override=true
    log_info "Force override mode enabled - will overwrite modified files"
  fi

  log_info "Starting DotRun installation..."

  # Detect environment
  os_type="$(detect_os)"
  shell_type="$(detect_shell)"

  log_info "Detected OS: $os_type"
  log_info "Detected shell: $shell_type"

  # ------------------------------------------------------------------
  # 1. Setup directories and variables
  # ------------------------------------------------------------------

  local script_dir src_dir

  # Get absolute path of script directory (works across platforms)
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Check if we're running from a proper dotrun repository
  # Note: dr binary may be in core/installPath/.core for legacy or root for legacy
  if [ -d "$script_dir/core" ]; then
    # Running from local repository with new or legacy structure
    src_dir="$script_dir"
    log_info "Using local repository at $src_dir"
  else
    # Running via curl - need to download repository
    log_info "No local repository found - downloading from GitHub..."

    # Create temporary directory for download
    temp_dir="$(mktemp -d)"

    # Download and extract repository
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "https://github.com/jvPalma/dotrun/archive/master.tar.gz" | tar -xz -C "$temp_dir" --strip-components=1
    elif command -v wget >/dev/null 2>&1; then
      wget -qO- "https://github.com/jvPalma/dotrun/archive/master.tar.gz" | tar -xz -C "$temp_dir" --strip-components=1
    else
      log_error "Neither curl nor wget found. Please install one of them or clone the repository manually."
      exit 1
    fi

    # Verify download succeeded - check for core directory
    if [ ! -d "$temp_dir/core" ]; then
      log_error "Failed to download repository from GitHub"
      exit 1
    fi

    src_dir="$temp_dir"
    log_success "Repository downloaded to $src_dir"

    # Set trap to cleanup temp directory
    cleanup_temp() {
      if [ -n "${temp_dir:-}" ] && [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
      fi
    }
    trap cleanup_temp EXIT
  fi

  # ------------------------------------------------------------------
  # 2. Setup directory structure for tool files and user content
  # ------------------------------------------------------------------

  local shared_dir="$HOME/.local/share/dotrun"
  local config_dir="$HOME/.config/dotrun"

  # Create shared directory for tool files
  if [ -d "$shared_dir" ] && [ "$(find "$shared_dir" -mindepth 1 -print -quit 2>/dev/null)" ]; then
    log_warn "$shared_dir already exists and is not empty"
    log_info "Will only copy new files (no overwriting unless --force)"
  else
    log_info "Creating shared directory: $shared_dir"
    mkdir -p "$shared_dir"
  fi

  # Create config directory for user content
  if [ -d "$config_dir" ] && [ "$(find "$config_dir" -mindepth 1 -print -quit 2>/dev/null)" ]; then
    log_warn "$config_dir already exists and is not empty"
    log_info "Will only copy new files (no overwriting unless --force)"
  else
    log_info "Creating configuration directory: $config_dir"
    mkdir -p "$config_dir"
  fi

  # Copy tool files from core/shared/dotrun/ to ~/.local/share/dotrun/
  local core_shared_path="$src_dir/core/shared/dotrun"
  if [ -d "$core_shared_path" ]; then
    copy_core_files_recursively "$core_shared_path" "$shared_dir" "$force_override" "tool files"
    log_success "Tool files synchronized to $shared_dir"
  else
    log_warn "Core shared path not found: $core_shared_path"
    log_info "Checking fallback path (legacy structure)..."

    # Fallback to legacy structure if new structure doesn't exist yet
    local legacy_core_path="$src_dir/core/installPath/.core"
    if [ -d "$legacy_core_path" ]; then
      copy_core_files_recursively "$legacy_core_path" "$shared_dir" "$force_override" "tool files (legacy)"
      log_success "Tool files synchronized from legacy path"
    else
      log_error "Neither new nor legacy core path found"
      exit 1
    fi
  fi

  # Copy user content directories from core/config/dotrun/ to ~/.config/dotrun/
  local core_config_path="$src_dir/core/config/dotrun"
  if [ -d "$core_config_path" ]; then
    copy_core_files_recursively "$core_config_path" "$config_dir" "$force_override" "user content"
    log_success "User content directories synchronized to $config_dir"
  else
    log_warn "Core config path not found: $core_config_path"
    log_info "Creating empty user content directories..."

    # Create empty user content directories
    mkdir -p "$config_dir/scripts"
    mkdir -p "$config_dir/aliases"
    mkdir -p "$config_dir/configs"
    mkdir -p "$config_dir/helpers"
    log_success "Created empty user content directories"
  fi

  # ------------------------------------------------------------------
  # V3.0 Structure Validation
  # ------------------------------------------------------------------

  # Verify critical v3.0 files exist
  local dr_config_loader="$shared_dir/.dr_config_loader"
  if [ ! -f "$dr_config_loader" ]; then
    log_error "Critical v3.0 file missing: .dr_config_loader"
    log_error "Expected at: $dr_config_loader"
    exit 1
  fi

  # Verify dr binary exists
  local dr_binary="$shared_dir/dr"
  if [ ! -f "$dr_binary" ]; then
    log_error "Critical v3.0 file missing: dr binary"
    log_error "Expected at: $dr_binary"
    exit 1
  fi

  # Verify helpers directory exists with loadHelpers.sh
  local helpers_loader="$shared_dir/helpers/loadHelpers.sh"
  if [ ! -f "$helpers_loader" ]; then
    log_error "Critical v3.0 file missing: helpers/loadHelpers.sh"
    log_error "Expected at: $helpers_loader"
    exit 1
  fi

  # Verify core directory files exist
  local core_aliases="$shared_dir/core/aliases.sh"
  if [ ! -f "$core_aliases" ]; then
    log_error "Critical v3.0 file missing: core/aliases.sh"
    log_error "Expected at: $core_aliases"
    exit 1
  fi

  local core_collections="$shared_dir/core/collections.sh"
  if [ ! -f "$core_collections" ]; then
    log_error "Critical v3.0 file missing: core/collections.sh"
    log_error "Expected at: $core_collections"
    exit 1
  fi

  local core_config="$shared_dir/core/config.sh"
  if [ ! -f "$core_config" ]; then
    log_error "Critical v3.0 file missing: core/config.sh"
    log_error "Expected at: $core_config"
    exit 1
  fi

  local core_template="$shared_dir/core/templates/script.sh"
  if [ ! -f "$core_template" ]; then
    log_error "Critical v3.0 file missing: core/templates/script.sh"
    log_error "Expected at: $core_template"
    exit 1
  fi

  # Verify VERSION file exists
  local version_file="$shared_dir/VERSION"
  if [ ! -f "$version_file" ]; then
    log_error "Critical v3.0 file missing: VERSION"
    log_error "Expected at: $version_file"
    exit 1
  fi

  log_success "✓ V3.0 structure validated (all critical files present)"

  # ------------------------------------------------------------------
  # 3. Install binary via symlink
  # ------------------------------------------------------------------

  # Binary installation paths
  local bin_dir="$HOME/.local/bin"
  local dr_source="$shared_dir/dr"
  local dr_target="$bin_dir/dr"

  # Create bin directory if it doesn't exist
  if [ ! -d "$bin_dir" ]; then
    mkdir -p "$bin_dir"
    log_info "Created directory: $bin_dir"
  fi

  # Check if we can write to bin directory
  if ! is_writable "$bin_dir" 2>/dev/null; then
    log_error "Cannot write to $bin_dir - installation failed"
    exit 1
  fi

  # Ensure source binary is executable
  chmod +x "$dr_source"

  # Remove old binary/symlink if exists
  if [ -e "$dr_target" ] || [ -L "$dr_target" ]; then
    log_info "Removing existing dr binary/symlink at $dr_target"
    rm -f "$dr_target"
  fi

  # Create symlink to binary in shared directory
  ln -sf "$dr_source" "$dr_target"
  log_success "Created symlink: $dr_target -> $dr_source"

  # Check if bin directory is in PATH
  if ! is_in_path "$bin_dir"; then
    log_warn "$bin_dir is not in your PATH"
    log_info "The installer will add it to your PATH via .drrc"
  fi

  # ------------------------------------------------------------------
  # 4. Setup shell integration
  # ------------------------------------------------------------------

  local drrc_file="$HOME/.drrc"
  local shell_config
  shell_config="$(get_shell_config "$shell_type")"

  # Copy .drrc from core/home folder if it doesn't exist
  local drrc_source="$src_dir/core/home/.drrc"
  if [ ! -f "$drrc_file" ]; then
    if [ -f "$drrc_source" ]; then
      log_info "Copying .drrc from core/home/"
      cp "$drrc_source" "$drrc_file"
      log_success "Created $drrc_file"
    else
      log_error "Source file not found: $drrc_source"
      exit 1
    fi
  else
    log_info "$drrc_file already exists"
  fi

  # Special handling for Fish completion - copy to fish completions directory
  if [ "$shell_type" = "fish" ]; then
    local fish_completion_src="$shared_dir/shell/fish/dr_completion.fish"
    local fish_completion_dir="$INSTALL_CFG_PATH/fish/completions"
    local fish_completion_dst="$fish_completion_dir/dr.fish"

    if [ -f "$fish_completion_src" ]; then
      if [ ! -d "$fish_completion_dir" ]; then
        mkdir -p "$fish_completion_dir"
        log_info "Created Fish completions directory: $fish_completion_dir"
      fi

      if [ -f "$fish_completion_dst" ]; then
        if [ "$force_override" = "true" ]; then
          cp "$fish_completion_src" "$fish_completion_dst"
          log_info "Updated Fish completion at $fish_completion_dst"
        else
          log_info "Fish completion already exists at $fish_completion_dst"
        fi
      else
        cp "$fish_completion_src" "$fish_completion_dst"
        log_success "Installed Fish completion to $fish_completion_dst"
      fi
    else
      log_warn "Fish completion source not found at $fish_completion_src"
    fi
  fi

  # ------------------------------------------------------------------
  # 5. Shell-specific integration advice
  # ------------------------------------------------------------------

  local integration_cmd fish_instructions=""
  local display_bin_dir=$(echo "$bin_dir" | sed "s|^$HOME|~|")
  local display_drrc_file=$(echo "$drrc_file" | sed "s|^$HOME|~|")

  case "$shell_type" in
    fish)
      # Fish needs special handling since it doesn't source bash files
      fish_instructions="true"
      integration_cmd="# Fish shell integration (see special instructions below)"
      ;;
    *)
      integration_cmd="echo 'source $display_drrc_file' >> $shell_config"
      ;;
  esac

  # Check if already integrated
  local already_integrated=false
  if [ -f "$shell_config" ] && grep -q "\.drrc" "$shell_config" 2>/dev/null; then
    already_integrated=true
  fi

  # ------------------------------------------------------------------
  # 6. Final status and instructions
  # ------------------------------------------------------------------

  echo
  log_success "DotRun installation completed!"
  echo
  printf "  📁 Tool files:       %s\n" "$shared_dir"
  printf "  📂 User content:     %s\n" "$config_dir"
  printf "  🔧 Binary location:  %s -> %s\n" "$dr_target" "$dr_source"
  printf "  🐚 Detected shell:   %s\n" "$shell_type"
  printf "  💻 Operating system: %s\n" "$os_type"
  echo

  if [ "$already_integrated" = "true" ]; then
    log_info "Shell integration already configured"
  elif [ "$fish_instructions" = "true" ]; then
    log_info "For Fish shell, add these lines to your $shell_config:"
    echo
    printf "  \033[1;36m# Add dr to PATH\033[0m\n"
    printf "  \033[1;36mset -gx PATH \"%s\" \$PATH\033[0m\n" "${display_bin_dir}"
    echo
    printf "  \033[1;36m# Fish completion is automatically loaded from ~/.config/fish/completions/dr.fish\033[0m\n"
    printf "  \033[1;36m# (already installed during setup)\033[0m\n"
    echo
  else
    log_info "To complete setup, add this to your shell config:"
    echo
    printf "  \033[1;36m%s\033[0m\n" "$integration_cmd"
    echo
    printf "  Or manually add: \033[1;36msource %s\033[0m\n" "${display_drrc_file}"
  fi

  echo
  if [ "$fish_instructions" = "true" ]; then
    log_info "To start using dr immediately in Fish:"
    printf "  \033[1;36mset -gx PATH \"%s\" \$PATH\033[0m\n" "${display_bin_dir}"
    printf "  \033[1;36mdr --help\033[0m\n"
  else
    log_info "To start using dr immediately:"
    printf "  \033[1;36msource %s\033[0m\n" "${display_drrc_file}"
    printf "  \033[1;36mdr --help\033[0m\n"
  fi
  echo

  # Test if dr is accessible
  if command -v dr >/dev/null 2>&1; then
    log_success "dr is ready to use!"
  else
    log_warn "dr not found in PATH. You may need to restart your shell or source $drrc_file"
  fi

  # Show force override option
  if [ "$force_override" = "false" ]; then
    echo
    log_info "To force override existing files, run:"
    printf "  \033[1;36m./install.sh --force\033[0m\n"
    echo
  fi

}

# ------------------------------------------------------------------
# Error handling and cleanup
# ------------------------------------------------------------------

cleanup() {
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    log_error "Installation failed with exit code $exit_code"
  fi
  exit $exit_code
}

trap cleanup EXIT

# Run main function
main "$@"
