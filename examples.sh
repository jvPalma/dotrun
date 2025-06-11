#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLES_DIR="$SCRIPT_DIR/examples"
DRUN_CONFIG="${DRUN_CONFIG:-$HOME/.config/dotrun}"
BIN_DIR="$DRUN_CONFIG/bin"
DOC_DIR="$DRUN_CONFIG/docs"
DOC_TOKEN="### DOC"

# Colors
GREEN='\033[1;32m'
GRAY='\033[0;37m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Ensure target directories exist
mkdir -p "$BIN_DIR" "$DOC_DIR"

# Function to extract first DOC line from a script
extract_doc_line() {
  local file="$1"
  if [[ -f "$file" ]]; then
    awk "/^$DOC_TOKEN/ { getline; if(\$0 !~ /^$DOC_TOKEN/) print \$0; exit }" "$file" 2>/dev/null | sed 's/^# *//' || echo "No description"
  else
    echo "No description"
  fi
}

# Function to find and collect examples
collect_examples() {
  local examples=()
  local descriptions=()

  if [[ ! -d "$EXAMPLES_DIR" ]]; then
    echo -e "${RED}❌ Examples directory not found: $EXAMPLES_DIR${RESET}" >&2
    echo -e "${YELLOW}💡 Make sure you're running this from the dotrun repository${RESET}" >&2
    return 1
  fi

  # Find all example scripts (looking for bin.sh files in subdirectories)
  while IFS= read -r -d '' example_dir; do
    local bin_file="$example_dir/bin.sh"
    if [[ -f "$bin_file" ]]; then
      # Extract relative path from examples directory
      local rel_path="${example_dir#"$EXAMPLES_DIR"/}"

      # Get first line of DOC section
      local doc_line
      doc_line=$(extract_doc_line "$bin_file")

      examples+=("$rel_path")
      descriptions+=("$doc_line")
    fi
  done < <(find "$EXAMPLES_DIR" -mindepth 1 -maxdepth 2 -type d -print0 | sort -z)

  if [[ ${#examples[@]} -eq 0 ]]; then
    echo -e "${RED}❌ No example scripts found in $EXAMPLES_DIR${RESET}" >&2
    echo -e "${YELLOW}💡 Examples should have structure: examples/category/script/bin.sh${RESET}" >&2
    return 1
  fi

  # Return arrays via global variables
  declare -g -a EXAMPLES=("${examples[@]}")
  declare -g -a DESCRIPTIONS=("${descriptions[@]}")
}

# Function to show what would be created for a given example
show_example_details() {
  local example_name="$1"
  local example_path="$EXAMPLES_DIR/$example_name"

  echo -e "${BLUE}Details for $example_name:${RESET}"
  echo "Would create:"

  # Main script
  echo -e "${GREEN}- bin/$example_name.sh${RESET} ${GRAY}[from examples/$example_name/bin.sh]${RESET}"

  # Documentation
  if [[ -f "$example_path/README.md" ]]; then
    echo -e "${GREEN}- docs/$example_name.md${RESET} ${GRAY}[from examples/$example_name/README.md]${RESET}"
  fi

  # Helper files
  if [[ -d "$example_path/helpers" ]]; then
    while IFS= read -r -d '' helper; do
      local helper_rel="${helper#"$example_path"/helpers/}"
      echo -e "${GREEN}- helpers/$example_name/$helper_rel${RESET} ${GRAY}[from examples/$example_name/helpers/$helper_rel]${RESET}"
    done < <(find "$example_path/helpers" -type f -print0 2>/dev/null)
  fi
}

# Interactive selection interface
interactive_selection() {
  local selected=0
  local total=${#EXAMPLES[@]}

  while true; do
    clear
    echo -e "${BLUE}🚀 DotRun Example Explorer${RESET}"
    echo "────────────────────────────────────────"
    echo -e "${GRAY}Use ↑/↓ or j/k to navigate, Enter to select, q to quit${RESET}"
    echo ""

    # Display options
    for i in "${!EXAMPLES[@]}"; do
      local prefix="  "

      if [[ $i -eq $selected ]]; then
        prefix="> "
      else
        prefix="  "
      fi
      echo -e "$prefix${GREEN}${EXAMPLES[$i]}${RESET} ${GRAY}${DESCRIPTIONS[$i]}${RESET}"
    done

    echo ""
    echo "────────────────────────────────────────"
    show_example_details "${EXAMPLES[$selected]}"

    # Get user input - handle both regular keys and escape sequences
    read -rsn1 key

    # Handle escape sequences for arrow keys
    if [[ $key == $'\033' ]]; then
      # Read the complete escape sequence without timeout
      read -rsn2 key_seq
      case "$key_seq" in
      '[A') # Up arrow
        if [[ $selected -gt 0 ]]; then
          selected=$((selected - 1))
        fi
        ;;
      '[B') # Down arrow
        if [[ $selected -lt $((total - 1)) ]]; then
          selected=$((selected + 1))
        fi
        ;;
      '[C' | '[D') # Right/Left arrows - ignore
        ;;
      esac
    else
      case "$key" in
      'q' | 'Q')
        clear
        echo -e "${YELLOW}👋 Goodbye!${RESET}"
        return 0
        ;;
      'k') # vim-style up
        if [[ $selected -gt 0 ]]; then
          selected=$((selected - 1))
        fi
        ;;
      'j') # vim-style down
        if [[ $selected -lt $((total - 1)) ]]; then
          selected=$((selected + 1))
        fi
        ;;
      '') # Enter
        clear
        install_example "${EXAMPLES[$selected]}"
        return 0
        ;;
      esac
    fi
  done
}

# Function to install an example
install_example() {
  local example_name="$1"
  local example_path="$EXAMPLES_DIR/$example_name"

  echo -e "${BLUE}🚀 Installing example: $example_name${RESET}"

  # Check if target already exists
  local target_bin="$BIN_DIR/$example_name.sh"
  if [[ -f "$target_bin" ]]; then
    echo -e "${YELLOW}⚠️  Script already exists: bin/$example_name.sh${RESET}"
    read -p "Overwrite? (y/N): " -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}⏭️  Installation cancelled${RESET}"
      return 0
    fi
  fi

  # Create directories
  local target_doc="$DOC_DIR/$example_name.md"
  mkdir -p "$(dirname "$target_bin")"
  mkdir -p "$(dirname "$target_doc")"

  # Copy main script
  if [[ -f "$example_path/bin.sh" ]]; then
    cp "$example_path/bin.sh" "$target_bin"
    chmod +x "$target_bin"
    echo -e "${GREEN}✅ Created: bin/$example_name.sh${RESET}"
  else
    echo -e "${RED}❌ Source script not found: $example_path/bin.sh${RESET}"
    return 1
  fi

  # Copy documentation
  if [[ -f "$example_path/README.md" ]]; then
    cp "$example_path/README.md" "$target_doc"
    echo -e "${GREEN}✅ Created: docs/$example_name.md${RESET}"
  fi

  # Copy helper files
  if [[ -d "$example_path/helpers" ]]; then
    local helpers_target="$DRUN_CONFIG/helpers/$example_name"
    mkdir -p "$helpers_target"

    while IFS= read -r -d '' helper; do
      local helper_rel="${helper#"$example_path"/helpers/}"
      local helper_target="$helpers_target/$helper_rel"
      mkdir -p "$(dirname "$helper_target")"
      cp "$helper" "$helper_target"
      chmod +x "$helper_target" 2>/dev/null || true
      echo -e "${GREEN}✅ Created: helpers/$example_name/$helper_rel${RESET}"
    done < <(find "$example_path/helpers" -type f -print0 2>/dev/null)
  fi

  echo ""
  echo -e "${GREEN}🎉 Successfully installed example: $example_name${RESET}"
  echo -e "${YELLOW}💡 Run with: drun $example_name${RESET}"
  echo -e "${YELLOW}📖 View docs: drun docs $example_name${RESET}"

  # Offer to run immediately
  echo ""
  read -p "Run the script now? (y/N): " -r run_now
  if [[ $run_now =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🏃 Running: drun $example_name${RESET}"
    echo "────────────────────────────────────────"
    if command -v drun >/dev/null 2>&1; then
      drun "$example_name"
    else
      echo -e "${RED}❌ drun command not found in PATH${RESET}"
      echo -e "${YELLOW}💡 You may need to restart your shell or source your profile${RESET}"
    fi
  fi
}

# Function to list all examples without interaction
list_examples() {
  if ! collect_examples; then
    return 1
  fi

  echo -e "${BLUE}📋 Available Examples:${RESET}"
  echo "────────────────────────────────────────"

  for i in "${!EXAMPLES[@]}"; do
    echo -e "${GREEN}${EXAMPLES[$i]}${RESET} ${GRAY}- ${DESCRIPTIONS[$i]}${RESET}"
  done

  echo ""
  echo -e "${YELLOW}💡 Run './examples.sh' for interactive installation${RESET}"
}

# Main function
main() {
  case "${1:-}" in
  -l | --list)
    list_examples
    ;;
  -h | --help)
    echo "DotRun Example Explorer"
    echo ""
    echo "Usage:"
    echo "  ./examples.sh           Interactive example browser"
    echo "  ./examples.sh -l        List all available examples"
    echo "  ./examples.sh -h        Show this help"
    echo ""
    echo "This script explores the examples/ directory and allows you to"
    echo "install example scripts into your DotRun configuration."
    ;;
  "")
    if ! collect_examples; then
      exit 1
    fi
    interactive_selection
    ;;
  *)
    echo -e "${RED}❌ Unknown option: $1${RESET}" >&2
    echo -e "${YELLOW}💡 Run './examples.sh -h' for help${RESET}" >&2
    exit 1
    ;;
  esac
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
