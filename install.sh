#!/usr/bin/env bash

# DotRun Installer - Maximum Compatibility Edition
# Supports: Linux, macOS, Windows (WSL/Git Bash/Cygwin), BSD variants
# Works with: bash, zsh, fish shells

set -euo pipefail

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

get_message() {
  [[ "$2" -gt 0 ]] && indent_str="   " || indent_str=" "

  case "$1" in
  "overwritten") echo "\033[1;34m[INFO]\033[0m$indent_str\033[1;33m✓\033[0m %s \033[0;37m(overwritten)\033[0m\n" ;;
  "unchanged") echo "\033[1;34m[INFO]\033[0m$indent_str\033[1;32m✓\033[0m %s \033[0;37m(unchanged)\033[0m\n" ;;
  "new file") echo "\033[1;34m[INFO]\033[0m$indent_str\033[1;32m+\033[0m %s \033[0;37m(new file)\033[0m\n" ;;
  "file differs") echo "\033[1;34m[INFO]\033[0m$indent_str\033[1;33m⚠\033[0m %s \033[0;37m(File differs from source)\033[0m\n" ;;
  "skipped") echo "\033[1;34m[INFO]\033[0m$indent_str\033[1;90m-\033[0m %s \033[0;37m(skipped)\033[0m\n" ;;
  *) echo "unknown" ;;
  esac
}

# Detect operating system
detect_os() {
  case "$(uname -s)" in
  Linux*) echo "linux" ;;
  Darwin*) echo "macos" ;;
  CYGWIN*) echo "windows" ;;
  MINGW*) echo "windows" ;;
  MSYS*) echo "windows" ;;
  FreeBSD*) echo "freebsd" ;;
  OpenBSD*) echo "openbsd" ;;
  NetBSD*) echo "netbsd" ;;
  *) echo "unknown" ;;
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

# Cross-platform file copying with intelligent file management
copy_files() {
  local src="$1"
  local dst="$2"
  local force_override="${3:-false}"
  local modified_files_detected=false

  log_info "Setting up DotRun directories and files"

  # Define target directories
  local target_dirs=("bin" "docs" "helpers")

  # Create target directories if they don't exist
  for dir in "${target_dirs[@]}"; do
    local target_dir="$dst/$dir"
    if [ ! -d "$target_dir" ]; then
      log_info "Creating directory: $target_dir"
      mkdir -p "$target_dir"
    fi
  done

  # Files to exclude from copying (installation/project files)
  local exclude_patterns=(
    "install.sh"
    ".gitignore"
    ".git"
    "*.out"
    "*.md"
    ".github"
    "LICENSE"
    "CHANGELOG.md"
    "test_shell_detect.sh"
  )

  # Hello example files (only copied on clean installs)
  local hello_files=(
    "bin/hello.sh"
    "docs/hello.md"
  )

  # Files to include at root level (only these specific files)
  local root_files=(
    "drun_completion"
    "README.md"
  )

  # Function to check if this is a clean install
  is_clean_install() {
    local config_dir="$1"

    # Check if config directory doesn't exist or is empty
    if [ ! -d "$config_dir" ]; then
      return 0 # Clean install
    fi

    # Check if bin/ directory exists and has any non-hello scripts
    local bin_dir="$config_dir/bin"
    if [ -d "$bin_dir" ]; then
      # Count files that are not hello examples
      local non_hello_count
      non_hello_count=$(find "$bin_dir" -type f -name "*.sh" ! -name "hello.sh" | wc -l)
      if [ "$non_hello_count" -gt 0 ]; then
        return 1 # Not clean, user has other scripts
      fi
    fi

    return 0 # Clean install
  }

  # Function to check if file is a hello example
  is_hello_file() {
    local file_path="$1"
    for hello_file in "${hello_files[@]}"; do
      if [[ "$file_path" == *"$hello_file" ]]; then
        return 0
      fi
    done
    return 1
  }

  # Function to check if file should be excluded
  should_exclude() {
    local file="$1"
    local basename_file
    basename_file="$(basename "$file")"

    for pattern in "${exclude_patterns[@]}"; do
      case "$basename_file" in
      "$pattern") return 0 ;;
      esac
    done
    return 1
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

  # Detect if this is a clean install
  local clean_install
  if is_clean_install "$dst"; then
    clean_install=true
    log_info "Clean install detected - will include hello examples"
  else
    clean_install=false
    log_info "Existing installation detected - skipping hello examples"
  fi

  # Process each target directory
  for dir in "${target_dirs[@]}"; do
    local src_dir="$src/$dir"
    local dst_dir="$dst/$dir"

    if [ ! -d "$src_dir" ]; then
      log_warn "Source directory $src_dir not found, skipping"
      continue
    fi

    log_info "📂 $dir/"

    # Find all files in source directory
    while IFS= read -r -d '' src_file; do
      # Skip if file should be excluded
      if should_exclude "$src_file"; then
        continue
      fi

      # Calculate relative path from src_dir
      local rel_path="${src_file#$src_dir/}"
      local full_rel_path="$dir/$rel_path"
      local dst_file="$dst_dir/$rel_path"

      # Skip hello files unless it's a clean install or force override
      if is_hello_file "$full_rel_path"; then
        if [ "$clean_install" = "false" ] && [ "$force_override" = "false" ]; then
          printf "$(get_message "skipped" 1)" "$rel_path (example file, use --force to copy)"
          continue
        fi
      fi

      # Create directory structure if needed
      mkdir -p "$(dirname "$dst_file")"

      if [ -f "$dst_file" ]; then
        # File exists, check if content is different
        local src_checksum dst_checksum
        src_checksum="$(get_checksum "$src_file")"
        dst_checksum="$(get_checksum "$dst_file")"

        if [ "$src_checksum" != "$dst_checksum" ]; then
          modified_files_detected=true
          if [ "$force_override" = "true" ]; then
            printf "$(get_message "overwritten" 1)" "$rel_path"
            cp "$src_file" "$dst_file"
            # Preserve executable permissions
            if [ -x "$src_file" ]; then
              chmod +x "$dst_file"`
            fi
          else
            printf "$(get_message "file differs" 1)" "$rel_path"
          fi
        else
          printf "$(get_message "unchanged" 1)" "$rel_path"
        fi
      else
        # File doesn't exist, copy it
        printf "$(get_message "new file" 1)" "$rel_path"
        cp "$src_file" "$dst_file"

        # Preserve executable permissions
        if [ -x "$src_file" ]; then
          chmod +x "$dst_file"
        fi
      fi
    done < <(find "$src_dir" -type f -print0)
  done

  # Copy specific root-level files
  for file in "${root_files[@]}"; do
    local src_file="$src/$file"
    local dst_file="$dst/$file"

    if [ -f "$src_file" ]; then
      if [ -f "$dst_file" ]; then
        # File exists, check if content is different
        local src_checksum dst_checksum
        src_checksum="$(get_checksum "$src_file")"
        dst_checksum="$(get_checksum "$dst_file")"

        if [ "$src_checksum" != "$dst_checksum" ]; then
          modified_files_detected=true
          if [ "$force_override" = "true" ]; then
            printf "$(get_message "overwritten" 0)" "$file"
            cp "$src_file" "$dst_file"
          else
            printf "$(get_message "file differs" 0)" "$file"
          fi
        else
          printf "$(get_message "unchanged" 0)" "$file"
        fi
      else
        # File doesn't exist, copy it
        printf "$(get_message "new file" 0)" "$file"
        cp "$src_file" "$dst_file"
      fi
    fi
  done

  # Return status indicating if modifications were detected
  if [ "$modified_files_detected" = "true" ] && [ "$force_override" = "false" ]; then
    return 1 # Indicate modifications were detected but not overridden
  else
    return 0 # All good
  fi
}

# Check if directory is writable
is_writable() {
  local dir="$1"
  [ -d "$dir" ] && [ -w "$dir" ]
}

# Get user's preferred shell config file
get_shell_config() {
  local shell="$1"
  case "$shell" in
  fish)
    echo "$HOME/.config/fish/config.fish"
    ;;
  zsh)
    if [ -f "$HOME/.zshrc" ]; then
      echo "$HOME/.zshrc"
    else
      echo "$HOME/.zprofile"
    fi
    ;;
  bash)
    if [ -f "$HOME/.bashrc" ]; then
      echo "$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      echo "$HOME/.bash_profile"
    else
      echo "$HOME/.profile"
    fi
    ;;
  *)
    echo "$HOME/.profile"
    ;;
  esac
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

  local script_dir src_dir cfg_dir bin_dest target_dir

  # Get absolute path of script directory (works across platforms)
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  src_dir="$script_dir"

  # Use XDG Base Directory specification where possible
  if [ "$os_type" = "windows" ]; then
    cfg_dir="${APPDATA:-$HOME/AppData/Roaming}/dotrun"
  else
    cfg_dir="${XDG_CONFIG_HOME:-$HOME/.config}/dotrun"
  fi

  # Default binary installation paths by OS
  case "$os_type" in
  macos)
    bin_dest="/usr/local/bin"
    ;;
  windows)
    bin_dest="$HOME/bin"
    ;;
  *)
    bin_dest="$HOME/.local/bin"
    ;;
  esac

  log_info "Config directory: $cfg_dir"
  log_info "Binary destination: $bin_dest"

  # ------------------------------------------------------------------
  # 2. Setup configuration directory
  # ------------------------------------------------------------------

  if [ -d "$cfg_dir" ] && [ "$(find "$cfg_dir" -mindepth 1 -print -quit 2>/dev/null)" ]; then
    log_warn "$cfg_dir already exists and is not empty"
    log_info "Will only copy new files (no overwriting)"
  else
    log_info "Creating configuration directory: $cfg_dir"
    mkdir -p "$cfg_dir"
  fi

  # Copy files using our intelligent file management function
  if ! copy_files "$src_dir" "$cfg_dir" "$force_override"; then
    # Modified files were detected but not overridden
    echo
    log_warn "Some files from the source differ from your current configuration."
    log_warn "This could be intentional (your customizations) or you may want to update them."
    echo
    log_info "To override modified files, rerun with:"
    printf "  \033[1;36m./install.sh --force\033[0m\n"
    printf "  \033[1;36m./install.sh override\033[0m\n"
    printf "  \033[1;36m./install.sh -f\033[0m\n"
    echo
  fi
  log_success "DotRun files synchronized successfully"

  # ------------------------------------------------------------------
  # 3. Install binary
  # ------------------------------------------------------------------

  target_dir="${DOTRUN_BIN_DIR:-$bin_dest}"

  # Check if we can write to target directory
  if ! is_writable "$target_dir" 2>/dev/null; then
    log_warn "Cannot write to $target_dir, using $HOME/.local/bin instead"
    target_dir="$HOME/.local/bin"
    mkdir -p "$target_dir"
  fi

  # Install the binary directly from source (not from config directory)
  local drun_source="$src_dir/drun"
  local drun_target="$target_dir/drun"

  if [ -f "$drun_source" ]; then
    # Use cp instead of install for compatibility
    cp "$drun_source" "$drun_target"
    chmod +x "$drun_target"
    log_success "drun binary installed to $drun_target"
  else
    log_error "Source binary not found: $drun_source"
    exit 1
  fi

  # ------------------------------------------------------------------
  # 4. Setup shell integration
  # ------------------------------------------------------------------

  local drunrc_file="$HOME/.drunrc"
  local shell_config
  shell_config="$(get_shell_config "$shell_type")"

  # Create .drunrc if it doesn't exist
  if [ ! -f "$drunrc_file" ]; then
    log_info "Creating $drunrc_file"

    cat >"$drunrc_file" <<EOF
# DotRun Configuration
export DRUN_CONFIG="$cfg_dir"

# Add drun binary to PATH if not already present
case ":\$PATH:" in
    *":$target_dir:"*) ;;
    *) export PATH="$target_dir:\$PATH" ;;
esac

# Load shell completion if available
if [ -f "\$DRUN_CONFIG/drun_completion" ]; then
    source "\$DRUN_CONFIG/drun_completion"
fi
EOF
    log_success "Created $drunrc_file"
  else
    log_info "$drunrc_file already exists, skipping creation"
  fi

  # ------------------------------------------------------------------
  # 5. Shell-specific integration advice
  # ------------------------------------------------------------------

  local integration_cmd
  case "$shell_type" in
  fish)
    integration_cmd="echo 'source $drunrc_file' >> $shell_config"
    ;;
  *)
    integration_cmd="echo 'source $drunrc_file' >> $shell_config"
    ;;
  esac

  # Check if already integrated
  local already_integrated=false
  if [ -f "$shell_config" ] && grep -q "\.drunrc" "$shell_config" 2>/dev/null; then
    already_integrated=true
  fi

  # ------------------------------------------------------------------
  # 6. Final status and instructions
  # ------------------------------------------------------------------

  echo
  log_success "DotRun installation completed!"
  echo
  printf "  📁 Config directory: %s\n" "$cfg_dir"
  printf "  🔧 Binary location:  %s\n" "$drun_target"
  printf "  🐚 Detected shell:   %s\n" "$shell_type"
  printf "  💻 Operating system: %s\n" "$os_type"
  echo

  if [ "$already_integrated" = "true" ]; then
    log_info "Shell integration already configured"
  else
    log_info "To complete setup, add this to your shell config:"
    echo
    printf "  \033[1;36m%s\033[0m\n" "$integration_cmd"
    echo
    printf "  Or manually add: \033[1;36msource %s\033[0m\n" "$drunrc_file"
  fi

  echo
  log_info "To start using drun immediately:"
  printf "  \033[1;36msource %s\033[0m\n" "$drunrc_file"
  printf "  \033[1;36mdrun --help\033[0m\n"
  echo

  # Test if drun is accessible
  if command -v drun >/dev/null 2>&1; then
    log_success "drun is ready to use!"
  else
    log_warn "drun not found in PATH. You may need to restart your shell or source $drunrc_file"
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
