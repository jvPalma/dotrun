#!/usr/bin/env bash
### DOC
# Run generate, lint, type-check and format across one or many packages
# Usage:
#   codeCheck                    - run default scripts (generate, lint, type-check, format)
#   codeCheck build test         - run default scripts + build + test
#   codeCheck --only build test  - run only build and test
### DOC

set -euo pipefail

# Parse command line arguments
if [[ $# -gt 0 && "$1" == "--only" ]]; then
  # Only run specified scripts
  shift
  scripts=("$@")
else
  # Default scripts + any additional ones
  scripts=(generate lint type-check format)
  # Append any additional scripts from command line
  scripts+=("$@")
fi

# Validate we have at least one script
if [[ ${#scripts[@]} -eq 0 ]]; then
  echo "Error: No scripts specified"
  exit 1
fi

echo "Running scripts: ${scripts[*]}"
echo

table_file="/tmp/codecheck_table.md"
status_dir="/tmp/codecheck_status"

# Clean up function
cleanup() {
  rm -rf "$status_dir" "$table_file" /tmp/codecheck_processes 2>/dev/null || true
}
trap cleanup EXIT

# ── collect packages ────────────────────────────────────────────────────────────
if [[ -f package.json ]]; then
  pkgs=(.)
else
  mapfile -t pkgs < <(find . -mindepth 1 -maxdepth 1 -type d ! -path '*/node_modules/*' -exec test -f '{}/package.json' ';' -print)
fi
((${#pkgs[@]})) || {
  echo "no package.json found"
  exit 1
}

# ── initialize status directory ────────────────────────────────────────────────
mkdir -p "$status_dir"

# Function to get package name from package.json
get_package_name() {
  local pkg_dir=$1
  local pkg_json="$pkg_dir/package.json"

  if [[ -f "$pkg_json" ]]; then
    local name
    name=$(jq -r '.name // empty' "$pkg_json" 2>/dev/null)
    if [[ -n "$name" && "$name" != "null" ]]; then
      echo "$name"
      return
    fi
  fi

  # Fallback to directory name
  local fallback="${pkg_dir#./}"
  [[ "$fallback" == "." ]] && fallback="root"
  echo "$fallback"
}

# Initialize status files for each package
for pkg in "${pkgs[@]}"; do
  pkg_name=$(get_package_name "$pkg")
  # Use a safe filename by replacing problematic characters
  pkg_safe="${pkg_name//[\/\@\-]/_}"
  for idx in "${!scripts[@]}"; do
    echo "🕛" >"$status_dir/${pkg_safe}_${idx}"
  done
done

# Function to update the markdown table
update_table() {
  {
    # Generate dynamic header based on scripts
    printf "| **Package Name**"
    for script in "${scripts[@]}"; do
      printf " | **%s**" "$script"
    done
    printf " |\n"

    # Generate separator line
    printf "|%s" "$(printf -- "%-17s|" | tr ' ' '-')"
    for script in "${scripts[@]}"; do
      printf "%s" "$(printf -- "%-$((${#script} + 2))s|" | tr ' ' '-')"
    done
    printf "\n"

    # Generate data rows
    for pkg in "${pkgs[@]}"; do
      pkg_name=$(get_package_name "$pkg")
      pkg_safe="${pkg_name//[\/\@\-]/_}"

      printf "| %-15s" "$pkg_name"
      for idx in "${!scripts[@]}"; do
        local status
        if [[ -f "$status_dir/${pkg_safe}_${idx}" ]]; then
          status=$(cat "$status_dir/${pkg_safe}_${idx}")
        else
          status="🕛"
        fi
        local script_name=${scripts[$idx]}
        local col_width=${#script_name}
        [[ $col_width -lt 8 ]] && col_width=8 # Minimum width for status icons
        printf " | %-${col_width}s" "$status"
      done
      printf " |\n"
    done
  } >"$table_file"
}

# Function to display the table
display_table() {
  if command -v glow >/dev/null 2>&1; then
    glow "$table_file"
  else
    cat "$table_file"
  fi
}

# Function to update a specific cell
update_cell() {
  local pkg=$1 col_idx=$2 text=$3
  local pkg_name=$(get_package_name "$pkg")
  local pkg_safe="${pkg_name//[\/\@\-]/_}"
  local status_file="$status_dir/${pkg_safe}_${col_idx}"

  # Make sure the directory exists
  mkdir -p "$status_dir" 2>/dev/null || true

  echo "$text" >"$status_file"
}

# Function to run scripts for a package
run_pkg() {
  local pkg=$1
  local orig_dir
  orig_dir=$(pwd)

  cd "$pkg" || return 1

  local idx
  for idx in "${!scripts[@]}"; do
    local s
    s=${scripts[$idx]}

    if ! jq -e --arg s "$s" '.scripts[$s]?' package.json >/dev/null 2>&1; then
      update_cell "." "$idx" "🔘" # Use "." since we're now in the package directory
      continue
    fi

    update_cell "." "$idx" "⏳" # Use "." since we're now in the package directory
    local err_file
    err_file="/tmp/codecheck_${pkg//\//_}_${s}.err"

    if yarn "$s" >/dev/null 2>"$err_file"; then
      update_cell "." "$idx" "✅" # Use "." since we're now in the package directory
      rm -f "$err_file"
    else
      update_cell "." "$idx" "⛔" # Use "." since we're now in the package directory
      if [[ -s "$err_file" ]]; then
        local pkg_name
        pkg_name=$(get_package_name ".")
        echo "── Error in $pkg_name ($s) ──" >&2
        cat "$err_file" >&2
        echo >&2
      fi
      rm -f "$err_file"
    fi
  done

  cd "$orig_dir"
}

# Export functions and variables for subshells
export -f update_cell update_table display_table run_pkg get_package_name
export scripts table_file status_dir

# Convert pkgs array to string for export
pkgs_str=$(printf '%s\n' "${pkgs[@]}")
export pkgs_str

# Ensure status directory exists and is accessible by subshells
mkdir -p "$status_dir"
chmod 755 "$status_dir"

# Initial table display
update_table
clear
display_table

# Run each package in parallel
pids=()
process_dir="/tmp/codecheck_processes"
mkdir -p "$process_dir"

for p in "${pkgs[@]}"; do
  pkg_name=$(get_package_name "$p")
  pkg_safe="${pkg_name//[\/\@\-]/_}"
  # Create a process marker file
  touch "$process_dir/$pkg_safe.running"

  (
    # Reconstruct pkgs array in subshell
    mapfile -t pkgs <<<"$pkgs_str"
    run_pkg "$p"
    # Remove the process marker when done
    rm -f "$process_dir/$pkg_safe.running"
  ) &
  pids+=($!)
done

# Start a background process to periodically refresh the display
(
  while true; do
    sleep 2
    # Check if any process marker files still exist
    if ls "$process_dir"/*.running >/dev/null 2>&1; then
      update_table
      clear
      display_table
    else
      break
    fi
  done
) &
refresh_pid=$!

# Wait for all background processes to complete
for pid in "${pids[@]}"; do
  wait "$pid"
done

# Stop the refresh process
kill "$refresh_pid" 2>/dev/null || true
wait "$refresh_pid" 2>/dev/null || true

# Clean up process directory
rm -rf "$process_dir"

# Final display
clear
echo "🎉 All packages processed!"
echo
update_table
display_table
