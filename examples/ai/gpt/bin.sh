#!/usr/bin/env bash
### DOC
#   Get code from location passed and generate analysis-ready report
### DOC
## add command: drun add gpt

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
set -euo pipefail

source "$DRUN_CONFIG/helpers/pkg.sh"
source "$DRUN_CONFIG/helpers/filters.sh"

# shellcheck disable=SC2154
echo "${global_exclude_patterns[*]}"

validatePkg tree
validatePkg git

# Set editor (fallback to nano)
EDITOR="${EDITOR:-nano}"

# Function: recursively process directory contents
gpt_process_directory() {
  local base="$1"
  local relative_path="${2:-.}"

  for item in "$base"/*; do

    [ -e "$item" ] || continue
    local item_basename
    item_basename=$(basename "$item")
    local relative_item_path="$relative_path/$item_basename"

    gpt_should_exclude "$item" && continue

    if [ -d "$item" ]; then
      if [ -z "$(find "$item" -maxdepth 0 -type d -empty)" ]; then
        gpt_process_directory "$item" "$relative_item_path"
      else
        echo "${relative_item_path}/ - <empty_folder>" >>"$gpt_log_file"
      fi
    elif [ -f "$item" ]; then
      # size limits
      lines=$(wc -l <"$item")
      ((lines > 2000)) && continue
      long_line=$(awk '{ if (length > m) m = length } END { print m }' "$item")
      ((long_line > 500)) && continue

      {
        echo ""
        echo "---- ${relative_item_path} ----"
        cat "$item"
        echo ""
        echo ""
      } >>"$gpt_log_file"
    fi
  done
}

main() {

  local input_dir
  if [[ $# -lt 1 ]]; then
    input_dir="$(pwd)"
  else
    input_dir="$1"
  fi
  export SCAN_ROOT="$(realpath "$input_dir")" # <<<  used by gpt_should_exclude

  gpt_log_file="$(pwd)/gpt.out"

  # Clean previous log file
  echo "Cleaning output file: $gpt_log_file"
  echo "== Project Tree ==" >"$gpt_log_file"

  # Combine patterns for `tree`
  local pattern
  pattern=$(
    IFS="|"
    echo "${global_exclude_patterns[*]}"
  )

  # Dump project structure
  if ! tree -a -I "$pattern" "$input_dir" >>"$gpt_log_file"; then
    echo "Error generating tree structure. Ensure 'tree' is installed and folder exists."
    exit 1
  fi

  # ─── Language histogram via detect_lang() ─────────────────────
  declare -A FILE_CT LINE_CT
  while IFS= read -r -d '' f; do

    gpt_should_exclude "$f" && continue

    # honour size/line caps
    lines=$(wc -l <"$f")
    ((lines > 2000)) && continue
    long_line=$(awk '{ if (length > m) m = length } END { print m }' "$f")
    ((long_line > 500)) && continue

    lang=$(detect_lang "$f")
    [[ -z $lang ]] && continue

    FILE_CT["$lang"]=$((${FILE_CT["$lang"]:-0} + 1))
    LINE_CT["$lang"]=$((${LINE_CT["$lang"]:-0} + lines))

  done < <(find "$input_dir" -type f -print0)

  {
    echo -e "\n\n== Language Histogram =="
    for lang in "${!FILE_CT[@]}"; do
      printf "%-12s %4d files %7d lines\n" \
        "$lang" "${FILE_CT[$lang]}" "${LINE_CT[$lang]}"
    done | sort -k4,4nr # sort by lines descending
  } >>"$gpt_log_file"

  echo -e "\n\n== File Contents ==" >>"$gpt_log_file"

  # Replace single threaded walk call
  gpt_process_directory "$input_dir"
  #  export -f gpt_should_exclude gpt_process_directory
  #  find "$input_dir" -type d -print0 | xargs -0 -I{} -P"$(nproc)" bash -c 'gpt_process_directory "$0"' {}

  echo "Done. Log saved to: $gpt_log_file"
  sleep 0.5

  # Open in editor
  "$EDITOR" "$gpt_log_file"
}

main "$@"
