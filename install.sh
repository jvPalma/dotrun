#!/usr/bin/env bash

# DotRun Installer - Maximum Compatibility Edition
# Supports: Linux, macOS, Windows (WSL/Git Bash/Cygwin), BSD variants
# Works with: bash, zsh, fish shells

set -euo pipefail

INSTALL_CFG_PATH=${XDG_CONFIG_HOME:-$HOME/.config}

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

# Cross-platform file copying with intelligent file management
copy_files() {
  local src="$1"
  local dst="$2"
  local force_override="${3:-false}"
  local modified_files_detected=false
  
  # Arrays to track modified files (declared as global so main can access them)
  modified_files=()
  modified_src_files=()

  log_info "Setting up DotRun directories and files"

  # Define target directories
  local target_dirs=("bin" "helpers" "collections")

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
  )

  # Files to include at root level (only these specific files)
  local root_files=(
    "dr_completion.bash"
    "dr_completion.zsh"
    "dr_completion.fish"
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
              chmod +x "$dst_file"
            fi
          else
            printf "$(get_message "file differs" 1)" "$rel_path"
            # Track modified files for later reporting
            modified_files+=("$dst_file")
            modified_src_files+=("$src_file")
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
            # Track modified files for later reporting
            modified_files+=("$dst_file")
            modified_src_files+=("$src_file")
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

  # Note: Fish completion is now handled via the .core folder
  # The copy_core_files_recursively function above will copy it to ~/.config/dotrun/.core/
  # Fish shell users should source it from there or it will be symlinked during shell integration

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

  # Verify source binary exists in shared directory
  if [ ! -f "$dr_source" ]; then
    log_error "Source binary not found at $dr_source"
    log_error "Expected to find it in ~/.local/share/dotrun/ after tool files setup"
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

      # Update .drrc to point to new loader location
      # The .dr_config_loader should be in ~/.local/share/dotrun/
      sed -i.bak "s|\.config/dotrun/\.core/\.dr_config_loader|.local/share/dotrun/.dr_config_loader|g" "$drrc_file" 2>/dev/null \
        || sed -i '' "s|\.config/dotrun/\.core/\.dr_config_loader|.local/share/dotrun/.dr_config_loader|g" "$drrc_file" 2>/dev/null
      rm -f "$drrc_file.bak"

      log_success "Created $drrc_file with updated paths"
    else
      log_error "Source file not found: $drrc_source"
      exit 1
    fi
  else
    log_info "$drrc_file already exists"

    # Check if it needs to be updated to new paths
    if grep -q "\.config/dotrun/\.core/\.dr_config_loader" "$drrc_file" 2>/dev/null; then
      log_info "Updating $drrc_file to use new directory structure"
      sed -i.bak "s|\.config/dotrun/\.core/\.dr_config_loader|.local/share/dotrun/.dr_config_loader|g" "$drrc_file" 2>/dev/null \
        || sed -i '' "s|\.config/dotrun/\.core/\.dr_config_loader|.local/share/dotrun/.dr_config_loader|g" "$drrc_file" 2>/dev/null
      rm -f "$drrc_file.bak"
      log_success "Updated $drrc_file paths"
    fi
  fi

  # Special handling for Fish completion - copy to fish completions directory
  if [ "$shell_type" = "fish" ]; then
    local fish_completion_src="$shared_dir/shell/fish/dr_completion.fish"
    local fish_completion_dir="$INSTALL_CFG_PATH/fish/completions"
    local fish_completion_dst="$fish_completion_dir/dr.fish"

    # Fallback to legacy path if new structure doesn't exist
    if [ ! -f "$fish_completion_src" ]; then
      fish_completion_src="$shared_dir/dr_completion.fish"
    fi

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

  # Create .drun_config_loader if it doesn't exist
  local config_loader_file="$cfg_dir/.drun_config_loader"
  if [ ! -f "$config_loader_file" ]; then
    log_info "Creating $config_loader_file"

    cat >"$config_loader_file" <<'EOF'
#!/usr/bin/env bash

source "$DRUN_CONFIG/helpers/pkg.sh"

# DotRun Configuration
# This file is managed by DotRun. Manual edits may be overwritten.
# Use 'drun config set/get/unset' commands to manage configuration.

#* =================== SHELL CONFIGURATIONS ====== *#
export CURRENT_SHELL=$(detect_shell)

# Add drun binary to PATH if not already present
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

SHELL_COMPLETION="$DRUN_CONFIG/drun_completion"
SHELL_CONFIGS="$DRUN_CONFIG/config/shell"
SHELL_ALIASES="$DRUN_CONFIG/aliases/shell"

[[ $CURRENT_SHELL == "bash" ]] && {
  SHELL_COMPLETION="$SHELL_COMPLETION.bash"
  SHELL_CONFIGS="$SHELL_CONFIGS/bash_config"
  SHELL_ALIASES="$SHELL_ALIASES/bash_aliases"
}

[[ $CURRENT_SHELL == "zsh" ]] && {
  SHELL_COMPLETION="$SHELL_COMPLETION.zsh"
  SHELL_CONFIGS="$SHELL_CONFIGS/zsh_config"
  SHELL_ALIASES="$SHELL_ALIASES/zsh_aliases"
}

[[ $CURRENT_SHELL == "fish" ]] && {
  SHELL_COMPLETION="$SHELL_COMPLETION.fish"
  SHELL_CONFIGS="$SHELL_CONFIGS/fish_config"
  SHELL_ALIASES="$SHELL_ALIASES/fish_aliases"
}

if [ -f "$SHELL_COMPLETION" ]; then
  source "$SHELL_COMPLETION"
fi

if [ -f "$SHELL_ALIASES" ]; then
  source "$SHELL_ALIASES"
fi

if [ -f "$SHELL_CONFIGS" ]; then
  source "$SHELL_CONFIGS"
fi

EOF
    chmod +x "$config_loader_file"
    log_success "Created $config_loader_file"
  else
    log_info "$config_loader_file already exists, skipping creation"
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

  # If there were files with differences, show override commands
  if [ "$binary_differs" = "true" ] || [ ${#modified_files[@]} -gt 0 ]; then
    echo
    log_warn "Some files were not updated due to existing modifications"
    log_info "To selectively override files, use these commands:"
    echo
    
    # Show binary override commands if needed
    if [ "$binary_differs" = "true" ] && [ ${#override_files[@]} -gt 0 ]; then
      for file in "${override_files[@]}"; do
        local display_M_dst=$(echo "$file" | sed "s|^$HOME|~|")
        local display_M_src=$(echo "$drun_source" | sed "s|^$HOME|~|")
        printf "  \033[1;36mcp %s %s\033[0m\n" "$display_M_src" "$display_M_dst"
      done
    fi
    
    # Show other file override commands from the copy process
    if [ ${#modified_files[@]} -gt 0 ]; then
      for i in "${!modified_files[@]}"; do
        local src_file="${modified_src_files[$i]}"
        local dst_file="${modified_files[$i]}"
        local display_M_dst=$(echo "$dst_file" | sed "s|^$HOME|~|")
        local display_M_src=$(echo "$src_file" | sed "s|^$HOME|~|")
        printf "  \033[1;36mcp %s %s\033[0m\n" "$display_M_src" "$display_M_dst"
      done
    fi
    
    echo
    log_info "Or to override all modified files at once:"
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
