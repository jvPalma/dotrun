# DotRun AI Documentation Index

**Purpose**: Comprehensive documentation designed for AI assistants to deeply understand, modify, and extend the DotRun codebase.

**Last Updated**: 2025-10-17

## Navigation Guide

### Quick Start for AI Assistants

1. **Understanding the System**: Start with [Architecture Overview](01-architecture/overview.md)
2. **Making Changes**: See [Development Guide](04-development/adding-commands.md)
3. **Finding Functions**: Check [API Reference](02-api-reference/dr-main.md)
4. **Debugging Issues**: Use [Troubleshooting Guide](07-troubleshooting/common-errors.md)

## Documentation Structure

### 01 - Architecture

High-level system design and component relationships

- [overview.md](01-architecture/overview.md) - System architecture and design philosophy
- [control-flow.md](01-architecture/control-flow.md) - Command routing and execution paths
- [data-flow.md](01-architecture/data-flow.md) - How data moves through the system
- [helper-system.md](01-architecture/helper-system.md) - Helper module architecture and loading
- [shell-integration.md](01-architecture/shell-integration.md) - Shell-specific implementations

### 02 - API Reference

Detailed function signatures, parameters, and behaviors

- [dr-main.md](02-api-reference/dr-main.md) - All functions in the main dr script
- [collections-api.md](02-api-reference/collections-api.md) - Collection management functions
- [aliases-api.md](02-api-reference/aliases-api.md) - Alias management functions
- [config-api.md](02-api-reference/config-api.md) - Configuration management functions
- [pkg-api.md](02-api-reference/pkg-api.md) - Package and validation utilities
- [environment.md](02-api-reference/environment.md) - Environment variables and their effects

### 03 - Implementation Details

Deep dives into specific algorithms and processes

- [script-resolution.md](03-implementation/script-resolution.md) - How scripts are located and validated
- [collection-import.md](03-implementation/collection-import.md) - Collection import process step-by-step
- [move-rename.md](03-implementation/move-rename.md) - Move/rename algorithm and edge cases
- [documentation-system.md](03-implementation/documentation-system.md) - Inline and markdown documentation
- [shell-completion.md](03-implementation/shell-completion.md) - Tab completion mechanisms

### 04 - Development Guides

How to extend and modify DotRun

- [adding-commands.md](04-development/adding-commands.md) - Step-by-step guide to adding commands
- [creating-helpers.md](04-development/creating-helpers.md) - How to create new helper modules
- [extending-collections.md](04-development/extending-collections.md) - Extending collection functionality
- [shell-compatibility.md](04-development/shell-compatibility.md) - Ensuring cross-shell compatibility

### 05 - Testing

Test scenarios, edge cases, and validation

- [test-scenarios.md](05-testing/test-scenarios.md) - Comprehensive test cases for all features
- [edge-cases.md](05-testing/edge-cases.md) - Known edge cases and how to handle them
- [manual-testing.md](05-testing/manual-testing.md) - Manual test procedures
- [integration-tests.md](05-testing/integration-tests.md) - Integration testing approaches

### 06 - Code Maps

Annotated code and relationship diagrams

- [dr-annotated.md](06-code-maps/dr-annotated.md) - Line-by-line annotations of dr
- [collections-annotated.md](06-code-maps/collections-annotated.md) - Annotated collections.sh
- [call-graphs.md](06-code-maps/call-graphs.md) - Function call relationships
- [data-structures.md](06-code-maps/data-structures.md) - Data formats and structures

### 07 - Troubleshooting

Common problems and solutions

- [common-errors.md](07-troubleshooting/common-errors.md) - Error messages and fixes
- [debugging.md](07-troubleshooting/debugging.md) - Debug techniques and strategies
- [shell-issues.md](07-troubleshooting/shell-issues.md) - Shell-specific problems

### 08 - Security

Security considerations and safe coding practices

- [input-validation.md](08-security/input-validation.md) - Input validation patterns
- [command-injection.md](08-security/command-injection.md) - Preventing command injection
- [file-operations.md](08-security/file-operations.md) - Safe file operation practices

## How to Use This Documentation

### For Understanding

1. Start with architecture overview
2. Read relevant implementation details
3. Check API reference for specific functions
4. Review code maps for visual understanding

### For Modifying

1. Check development guides for patterns
2. Review similar existing implementations
3. Validate against test scenarios
4. Check security considerations
5. Test across all supported shells

### For Debugging

1. Check troubleshooting guide for known issues
2. Review call graphs to trace execution
3. Use debugging guide techniques
4. Validate against edge cases

## Key Concepts

### Script Resolution

Scripts are resolved in two phases:

1. Exact path match for folder/script syntax
2. Recursive basename search for simple names

### Collection System

Collections are git repositories with structure:

- `bin/` - Executable scripts
- `docs/` - Markdown documentation
- `.dr-collection.yml` - Metadata

### Helper Modules

Helpers are sourced dynamically by main dr script:

- Provide specialized functionality
- Independent and self-contained
- Use `validatePkg` for dependencies

### Documentation System

Two-tier documentation:

- Inline (`### DOC` markers) for quick help
- Markdown files for comprehensive guides

## Critical Files

| File                     | Purpose               | Lines | Complexity |
| ------------------------ | --------------------- | ----- | ---------- |
| `dr`                     | Main executable       | ~1022 | High       |
| `helpers/collections.sh` | Collection management | ~613  | High       |
| `helpers/config.sh`      | Configuration system  | ~600+ | Medium     |
| `helpers/aliases.sh`     | Alias management      | ~400+ | Medium     |
| `install.sh`             | Installation script   | ~893  | High       |

## Version Information

- **DotRun Version**: 1.0.1
- **Supported Shells**: Bash 4.0+, Zsh, Fish
- **Supported OS**: Linux, macOS, Windows (WSL/Git Bash)

## Maintenance

This documentation should be updated when:

- New commands are added
- Helper modules are created or modified
- Major refactoring occurs
- New shell support is added
- Security vulnerabilities are fixed

## Contributing to Documentation

When adding documentation:

1. Follow existing structure and formatting
2. Include code examples with line numbers
3. Cross-reference related documents
4. Keep language clear and unambiguous
5. Assume AI assistant has read context but not memorized code
