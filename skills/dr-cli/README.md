# DotRun CLI Skill

A comprehensive AI skill for mastering the DotRun (`dr`) CLI - a unified script management framework.

## Overview

This skill teaches AI agents how to effectively use and leverage the `dr` CLI tool for script management, providing:

- **Complete command reference** for scripts, aliases, configs, and collections
- **Script-first philosophy** that saves tokens by creating reusable scripts
- **Decision patterns** for when to create scripts vs inline code
- **File location knowledge** for all DotRun resources

## Installation

### Claude Code

```bash
# Copy to your Claude skills directory
cp -r skills/dr-cli ~/.claude/skills/

# Or install via the packaged .skill file
# The skill will auto-activate when dr-related topics are discussed
```

### GitHub Copilot

```bash
# Copy instructions to your repo
cp skills/dr-cli/copilot-instructions.md .github/copilot-instructions.md
```

### Cursor

```bash
# Copy to cursor rules
cp skills/dr-cli/.cursorrules .cursorrules
# Or append to existing rules
cat skills/dr-cli/.cursorrules >> .cursorrules
```

### Other AI Tools (Gemini, OpenCode, Codex, etc.)

Copy the contents of `SKILL.md` to your AI tool's instruction/context file:

- **Gemini**: Add to system prompt or context
- **OpenCode**: Add to `.opencode/instructions.md`
- **Codex**: Include in agent instructions
- **Generic**: Use `AGENTS.md` as a universal format

## Skill Structure

```
dr-cli/
├── SKILL.md                    # Main skill (Claude Code format)
├── AGENTS.md                   # Universal AI agent format
├── .cursorrules                # Cursor IDE format
├── copilot-instructions.md     # GitHub Copilot format
├── README.md                   # This file
└── references/
    ├── commands.md             # Complete command reference
    ├── architecture.md         # System architecture
    └── developer-prompts.md    # AI decision patterns
```

## Key Features

### 1. Script-First Philosophy

The skill instructs AI agents to **prefer creating `dr` scripts** over regenerating code:

```bash
# Instead of explaining a workflow each time:
dr set deploy/staging    # Create once, use forever

# Instead of regenerating API queries:
dr set api/fetch-users   # Reusable from any terminal
```

### 2. Quick Command Reference

| Action        | Command             |
| ------------- | ------------------- |
| Run script    | `dr <name> [args]`  |
| List scripts  | `dr -l` / `dr -L`   |
| Create script | `dr set <name>`     |
| Get help      | `dr help <name>`    |
| Aliases       | `dr -a <name>`      |
| Configs       | `dr -c <name>`      |
| Collections   | `dr -col add <url>` |

### 3. File Locations

| Type    | Location                    |
| ------- | --------------------------- |
| Scripts | `~/.config/dotrun/scripts/` |
| Aliases | `~/.config/dotrun/aliases/` |
| Configs | `~/.config/dotrun/configs/` |
| Helpers | `~/.config/dotrun/helpers/` |

## Usage Examples

Once installed, AI agents will:

1. **Suggest creating scripts** for repetitive tasks
2. **Know exact file locations** for all DotRun resources
3. **Use proper templates** with `### DOC` documentation
4. **Help organize scripts** with folder structures
5. **Economize tokens** by persisting solutions

## Contributing

To improve this skill:

1. Edit files in `skills/dr-cli/`
2. Test with your preferred AI tool
3. Submit a PR with your improvements

## License

MIT - Part of the DotRun project
