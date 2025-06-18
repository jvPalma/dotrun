#!/usr/bin/env bash
# helpers/filters.sh – reusable include/exclude logic

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016

# Folders we never traverse (relative path segments)
EXCL_FOLDERS=(
  "__pycache__" ".vsix" "dist" "build" "coverage" "storybook-static" ".next"
  "releases" "palma" "moasacks" "generated" "fragments" "deploy"
  ".git" "node_modules" ".yarn"
)

# File­name patterns to skip
EXCL_FILES=(
  "README.md" "LICENSE" ".env" "yarn.lock" "package-lock.json"
  "*.egg-info" "tsconfig.json" "tsup.config.ts" "turbo.json" "graphql.ts"
  "*.out" "jest.*" "jest."
)

# shellcheck disable=SC2034
global_exclude_patterns=(
  "${EXCL_FOLDERS[@]}"
  "${EXCL_FILES[@]}"
)
# ------------------------------------------------------------------
# gpt_should_exclude <absolute-path>
#   returns 0 (true)  if path must be skipped
#            1 (false) otherwise
#   Requires global  SCAN_ROOT  (absolute project root)
# ------------------------------------------------------------------
gpt_should_exclude() {
  local abs="$1"
  # shellcheck disable=SC2295
  local rel="${abs#$SCAN_ROOT/}" # strip leading root/
  local base="$(basename "$rel")"
  local dir="$(dirname "$rel")"

  # folder test
  for pat in "${EXCL_FOLDERS[@]}"; do
    [[ "$dir" == *"/$pat"* || "$dir" == "$pat"* ]] && return 0
  done
  # file test (basename only)
  for pat in "${EXCL_FILES[@]}"; do
    [[ "$base" == "$pat" ]] && return 0
  done
  return 1
}
