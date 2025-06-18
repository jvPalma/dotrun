# docker-cleanup

A utility script for cleaning up Docker containers, images, and networks to free up disk space.

## Usage

```bash
$ drun docker-cleanup [--force]
```

## Options

- `--force`: Skip confirmation prompt and clean up immediately

## Description

This script helps maintain a clean Docker environment by removing:

- All stopped containers
- All dangling images (untagged images)
- All unused networks
- Optionally, unused volumes (suggested manually)

The script includes safety prompts unless `--force` is used, making it safe for regular use.

## Examples

```bash
# Interactive cleanup (with confirmation)
$ drun docker-cleanup

# Force cleanup without prompts
$ drun docker-cleanup --force
```

## Safety Features

- Confirmation prompt before cleaning (unless --force)
- Only removes stopped containers (never running ones)
- Only removes dangling/unused resources
- Provides clear feedback on what was cleaned

## Requirements

- Docker must be installed and running
- User must have permissions to run Docker commands

## Team Benefits

When shared as part of a team collection, this script ensures all developers have a consistent way to clean up their Docker environments, reducing "works on my machine" issues caused by resource conflicts or disk space problems.