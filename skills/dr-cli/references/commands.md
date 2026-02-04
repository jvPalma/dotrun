# DotRun CLI - Command Reference

> Load this for complete command syntax. Quick Reference in SKILL.md covers 90% of cases.

## Scripts (default namespace)

| Command               | Purpose                        |
| --------------------- | ------------------------------ |
| `dr <name> [args]`    | Run script                     |
| `dr -l [folder/]`     | List scripts (names only)      |
| `dr -L [folder/]`     | List scripts with descriptions |
| `dr set <name>`       | Create/edit script             |
| `dr help <name>`      | Show script docs               |
| `dr move <old> <new>` | Rename/move script             |
| `dr rm <name>`        | Remove script                  |

## Aliases (`-a`)

| Command                  | Purpose                |
| ------------------------ | ---------------------- |
| `dr -a <name>`           | Create/edit alias file |
| `dr -a -l / -L`          | List aliases           |
| `dr -a help <name>`      | Show alias docs        |
| `dr -a move <old> <new>` | Move alias file        |
| `dr -a rm <name>`        | Remove alias file      |

## Configs (`-c`)

| Command                  | Purpose                       |
| ------------------------ | ----------------------------- |
| `dr -c <name>`           | Create/edit config (env vars) |
| `dr -c -l / -L`          | List configs                  |
| `dr -c help <name>`      | Show config docs              |
| `dr -c move <old> <new>` | Move config file              |
| `dr -c rm <name>`        | Remove config file            |

## Collections (`-col`)

| Command                 | Purpose                        |
| ----------------------- | ------------------------------ |
| `dr -col`               | Interactive browser            |
| `dr -col init`          | Init collection in current dir |
| `dr -col add <url>`     | Install from Git               |
| `dr -col list`          | Show installed                 |
| `dr -col sync`          | Check for updates              |
| `dr -col update [name]` | Apply updates                  |
| `dr -col remove <name>` | Remove tracking                |

## System

| Command | Purpose             |
| ------- | ------------------- |
| `dr -r` | Reload shell config |
| `dr -v` | Show version        |
| `dr -h` | Show help           |

---

## Path Patterns

All namespaces support nested paths:

```bash
dr set folder/subfolder/script    # Creates nested structure
dr -a category/subcategory        # Nested aliases
dr -c domain/subdomain            # Nested configs
```

## Naming Rules

- Allowed: `a-zA-Z0-9`, underscore `_`, dash `-`, forward slash `/`
- Forbidden: Spaces, special characters
- Extensions added automatically: `.sh`, `.aliases`, `.config`

## Environment Variables

| Variable          | Default                                        | Purpose                |
| ----------------- | ---------------------------------------------- | ---------------------- |
| `DR_CONFIG`       | `~/.config/dotrun`                             | Base config dir        |
| `DR_LOAD_HELPERS` | `~/.local/share/dotrun/helpers/loadHelpers.sh` | Helper loader          |
| `EDITOR`          | `code` or `nano`                               | Editor for create/edit |

## Dual Syntax

Flag and word syntax are interchangeable:

```bash
dr -s set deploy      # Flag
dr scripts set deploy # Word

dr -a -l              # Flag
dr aliases list       # Word
```
