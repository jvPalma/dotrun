# DotRun CLI - Complete Command Reference

## Table of Contents

1. [Core Commands](#core-commands)
2. [Script Commands](#script-commands)
3. [Alias Commands](#alias-commands)
4. [Config Commands](#config-commands)
5. [Collection Commands](#collection-commands)
6. [Environment Variables](#environment-variables)

---

## Core Commands

### `dr` (no args)

Display help and usage information.

### `dr -l [folder/]`

List scripts in tree view (names only).

- Optional `folder/` scope to filter by directory

### `dr -L [folder/]`

List scripts with descriptions (from `### DOC` blocks).

- Extracts one-line description from first DOC block

### `dr -r` / `dr reload`

Reload shell configuration. Applies changes to aliases and configs.

### `dr -v` / `dr --version`

Display version number.

### `dr -h` / `dr --help`

Display comprehensive help.

---

## Script Commands

Scripts are the default namespace. Use `dr -s` or `dr scripts` prefix for explicit mode.

### `dr <name> [args...]`

Execute script with arguments.

```bash
dr deploy --env prod
dr git/cleanup --dry-run
```

### `dr set <name>`

Create or edit script. Opens in `$EDITOR`.

```bash
dr set deploy              # ~/.config/dotrun/scripts/deploy.sh
dr set git/sync            # ~/.config/dotrun/scripts/git/sync.sh
dr set devops/ci/build     # Deeply nested script
```

### `dr help <name>`

Show script documentation (content between 2nd and 3rd `### DOC` markers).

```bash
dr help deploy
dr help git/cleanup
```

### `dr move <source> <destination>`

Rename or move script.

```bash
dr move oldName newName           # Rename
dr move script folder/script      # Move to subfolder
dr move git/old git/new           # Rename within folder
```

### `dr rm <name>`

Remove script (with confirmation).

```bash
dr rm deploy
dr rm git/cleanup
```

---

## Alias Commands

Aliases namespace: `dr -a` or `dr aliases`

### `dr -a <name>` / `dr -a set <name>`

Create or edit alias file.

```bash
dr -a 01-git              # ~/.config/dotrun/aliases/01-git.aliases
dr -a docker/compose      # Nested alias file
```

### `dr -a -l [folder/]`

List aliases (tree view, names only).

### `dr -a -L [folder/]`

List aliases with descriptions.

### `dr -a help <name>`

Show alias file documentation.

### `dr -a move <source> <destination>`

Move/rename alias file.

### `dr -a rm <name>`

Remove alias file.

### `dr -a init`

Initialize aliases directory structure.

### Alias File Format

```bash
# ~/.config/dotrun/aliases/01-git.aliases
# File header comment (shown by dr -a help)

alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
```

---

## Config Commands

Configs namespace: `dr -c` or `dr config`

### `dr -c <name>` / `dr -c set <name>`

Create or edit config file (environment exports).

```bash
dr -c 01-paths            # ~/.config/dotrun/configs/01-paths.config
dr -c api/credentials     # Nested config file
```

### `dr -c -l [folder/]`

List configs (tree view, names only).

### `dr -c -L [folder/]`

List configs with descriptions.

### `dr -c help <name>`

Show config file documentation.

### `dr -c move <source> <destination>`

Move/rename config file.

### `dr -c rm <name>`

Remove config file.

### `dr -c init`

Initialize configs directory structure.

### Config File Format

```bash
# ~/.config/dotrun/configs/01-api.config
# API credentials and endpoints

export API_KEY="your-api-key"
export API_URL="https://api.example.com"
export DEBUG_MODE="false"
```

---

## Collection Commands

Collections namespace: `dr -col` or `dr collections`

### `dr -col`

Interactive collection browser.

### `dr -col init`

Initialize collection structure in current directory.
Creates: `dotrun.collection.yml`, `scripts/`, `aliases/`, `helpers/`, `configs/`

### `dr -col add <url>`

Install collection from Git URL.

```bash
dr -col add https://github.com/team/scripts.git
dr -col add git@github.com:user/dotfiles.git
```

### `dr -col list`

Show installed collections with version info and imported resource counts.

### `dr -col sync`

Check for available updates (non-destructive).

### `dr -col update [name]`

Update collection with conflict resolution.

- Prompts for modified files: Keep, Overwrite, Diff, Merge, Backup

### `dr -col remove <name>`

Remove collection tracking (keeps imported files).

### `dr -col --help`

Detailed collections help.

### Collection Metadata Format

```yaml
# dotrun.collection.yml
name: "my-collection" # Required: Unique identifier
version: "1.0.0" # Required: Semantic version
description: "Description" # Required
author: "Author Name" # Required
repository: "https://..." # Required: Git URL
license: "MIT" # Optional
homepage: "https://..." # Optional
dependencies: [] # Optional: Other collections
```

---

## Environment Variables

| Variable             | Default                                        | Description                      |
| -------------------- | ---------------------------------------------- | -------------------------------- |
| `DR_CONFIG`          | `~/.config/dotrun`                             | Base configuration directory     |
| `DR_LOAD_HELPERS`    | `~/.local/share/dotrun/helpers/loadHelpers.sh` | Helper loading function path     |
| `EDITOR`             | `code` or `nano`                               | Editor for create/edit commands  |
| `DR_HELPERS_VERBOSE` | `0`                                            | Enable verbose helper loading    |
| `DR_HELPERS_QUIET`   | `1`                                            | Suppress non-error helper output |

---

## Command Syntax Patterns

### Dual Syntax Support

All namespaces support both flag and word syntax:

```bash
dr -s set deploy      # Flag syntax
dr scripts set deploy # Word syntax

dr -a -l              # Flag syntax
dr aliases list       # Word syntax

dr -c set api         # Flag syntax
dr config set api     # Word syntax

dr -col add url       # Flag syntax
dr collections add url # Word syntax
```

### Path Patterns

Scripts, aliases, and configs support nested paths:

```bash
dr set folder/subfolder/script    # Creates nested structure
dr -a category/subcategory        # Nested aliases
dr -c domain/subdomain            # Nested configs
```

### Naming Rules

- Allowed: `a-zA-Z0-9`, underscore `_`, dash `-`, forward slash `/`
- Forbidden: Spaces, special characters
- Extensions added automatically: `.sh`, `.aliases`, `.config`
