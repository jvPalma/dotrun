# codeCheck — automated code quality pipeline runner

A comprehensive script that runs generate, lint, type-check, and format scripts across one or many packages in parallel with real-time status display.

## Features

- **Multi-package support** - Automatically detects all packages with package.json files
- **Parallel execution** - Runs scripts concurrently for faster completion
- **Real-time status** - Live-updating table showing progress with emoji indicators
- **Customizable script selection** - Run default scripts or specify your own
- **Error reporting** - Detailed error output for failed scripts
- **Visual feedback** - Beautiful table display with glow rendering support

## Usage

### Basic Usage
```bash
# Run default scripts (generate, lint, type-check, format)
drun code/codeCheck

# Run default scripts plus additional ones
drun code/codeCheck build test

# Run only specified scripts
drun code/codeCheck --only build test
```

### Status Indicators

| Icon | Meaning |
|------|---------|
| 🕛 | Waiting to start |
| ⏳ | Currently running |
| ✅ | Completed successfully |
| ⛔ | Failed with errors |
| 🔘 | Script not available in package.json |

### Examples

```bash
# Standard development workflow
drun code/codeCheck
# Runs: generate → lint → type-check → format

# Pre-deployment check
drun code/codeCheck build test
# Runs: generate → lint → type-check → format → build → test

# Quick formatting only
drun code/codeCheck --only format
# Runs: format only
```

## Requirements

- **Node.js** with yarn package manager
- **package.json** with npm scripts defined
- **jq** for JSON parsing
- **glow** (optional) for enhanced table rendering

## Script Detection

The script automatically detects packages by:
1. Looking for package.json in current directory (single package)
2. Scanning subdirectories for package.json files (monorepo)
3. Excluding node_modules directories

## Dependencies

Expects the following scripts to be defined in package.json:
- `generate` - Code generation (optional)
- `lint` - Linting with ESLint/similar
- `type-check` - TypeScript type checking
- `format` - Code formatting with Prettier/similar
- `build` - Build process (when specified)
- `test` - Test execution (when specified)

