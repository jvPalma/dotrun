#!/usr/bin/env bash
# Help messages for: file operation collection errors
# Usage: file-errors.sh <error-type> [dynamic-vars...]

BOLD=$'\e[1m'
CYAN=$'\e[36m'
GREEN=$'\e[32m'
PURPLE=$'\e[35m'
RED=$'\e[31m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
GRAY=$'\e[90m'
RESET=$'\e[0m'

error_type="${1:-}"
shift

case "$error_type" in
  metadata-not-found)
    collection_dir="$1"
    cat >&2 <<EOF
${RED}Error:${RESET} Collection metadata file not found

${GRAY}Expected file location:${RESET}
  ${YELLOW}$collection_dir/dotrun.collection.yml${RESET}
  or
  ${YELLOW}$collection_dir/dotrun.collection.yaml${RESET}

This repository is not a valid DotRun collection.

${GRAY}To create a DotRun collection:${RESET}
  1. Navigate to your repository directory
  2. Run: ${CYAN}dr -col init${RESET}
EOF
    ;;
  missing-fields)
    # Receives fields as remaining args
    cat >&2 <<EOF
${RED}Error:${RESET} Invalid collection metadata - missing required fields

${GRAY}Missing fields:${RESET}
EOF
    for field in "$@"; do
      echo "  • $field" >&2
    done
    cat >&2 <<EOF

${GRAY}Required metadata format (dotrun.collection.yml):${RESET}

  name: my-collection           ${GRAY}# Unique identifier${RESET}
  version: 1.0.0                ${GRAY}# Semantic version (X.Y.Z)${RESET}
  description: Brief summary    ${GRAY}# What this collection provides${RESET}
  author: Your Name             ${GRAY}# Collection creator${RESET}
  repository: https://github.com/user/repo  ${GRAY}# Git repository URL${RESET}
EOF
    ;;
  cannot-read-source)
    source_file="$1"
    cat >&2 <<EOF
${RED}Error:${RESET} Cannot read source file (permission denied)
File: ${YELLOW}$source_file${RESET}

${GRAY}Troubleshooting:${RESET}
  1. Check file permissions: ${CYAN}ls -la $source_file${RESET}
  2. Fix permissions: ${CYAN}chmod +r $source_file${RESET}
EOF
    ;;
  cannot-create-dir)
    dest_dir="$1"
    cat >&2 <<EOF
${RED}Error:${RESET} Cannot create destination directory (permission denied)
Directory: ${YELLOW}$dest_dir${RESET}

${GRAY}Troubleshooting:${RESET}
  1. Check directory permissions: ${CYAN}ls -ld $(dirname "$dest_dir")${RESET}
  2. Verify ownership: ${CYAN}ls -ld $(dirname "$dest_dir")${RESET}
  3. Fix permissions: ${CYAN}chmod +w $(dirname "$dest_dir")${RESET}
  4. Or use sudo if this is a system directory
EOF
    ;;
  cannot-write-dir)
    dest_dir="$1"
    cat >&2 <<EOF
${RED}Error:${RESET} Cannot write to destination directory (permission denied)
Directory: ${YELLOW}$dest_dir${RESET}

${GRAY}Troubleshooting:${RESET}
  1. Check directory permissions: ${CYAN}ls -ld $dest_dir${RESET}
  2. Fix permissions: ${CYAN}chmod +w $dest_dir${RESET}
EOF
    ;;
  copy-failed)
    source_file="$1"
    dest_file="$2"
    cat >&2 <<EOF
${RED}Error:${RESET} Failed to copy file (permission denied or disk full)
Source: ${YELLOW}$source_file${RESET}
Destination: ${YELLOW}$dest_file${RESET}

${GRAY}Troubleshooting:${RESET}
  1. Check disk space: ${CYAN}df -h $(dirname "$dest_file")${RESET}
  2. Check destination permissions: ${CYAN}ls -la $dest_file${RESET}
  3. Try manual copy: ${CYAN}cp $source_file $dest_file${RESET}
EOF
    ;;
  chmod-failed)
    dest_file="$1"
    cat >&2 <<EOF
${RED}Error:${RESET} Failed to make script executable (permission denied)
File: ${YELLOW}$dest_file${RESET}

${GRAY}Troubleshooting:${RESET}
  1. Check file permissions: ${CYAN}ls -la $dest_file${RESET}
  2. Try manual chmod: ${CYAN}chmod +x $dest_file${RESET}
  3. Verify file ownership: ${CYAN}ls -l $dest_file${RESET}
EOF
    ;;
  parse-metadata-failed)
    cat >&2 <<EOF
${RED}Error:${RESET} Failed to parse collection metadata
EOF
    ;;
  collection-exists)
    collection_name="$1"
    existing_url="$2"
    existing_version="$3"
    cat >&2 <<EOF
${RED}Error:${RESET} Collection ${CYAN}'$collection_name'${RESET} already exists
${YELLOW}Existing collection:${RESET}
  ${GRAY}URL:${RESET} ${CYAN}$existing_url${RESET}
  ${GRAY}Version:${RESET} ${CYAN}$existing_version${RESET}

${GRAY}Run ${CYAN}'dr -col list'${GRAY} to view all installed collections${RESET}
${GRAY}Run ${CYAN}'dr -col remove $collection_name'${GRAY} to remove existing collection first${RESET}
EOF
    ;;
esac
