# gpt — generate codebase analysis report for AI processing

### Synopsis

`gpt <directory>`

### Description

Analyzes a project directory and generates a comprehensive report containing the project structure, code statistics, and file contents. The output is optimized for feeding to AI models for code analysis, documentation generation, or architectural review.

**Features:**
- **Project tree visualization** with hierarchical structure
- **Language statistics** via `cloc` (lines of code by language)
- **Selective file inclusion** excluding large binaries and dependencies
- **AI-optimized format** for LLM consumption
- **Interactive editing** opens result in your preferred editor

### Arguments

| Pos | Name      | Description                         |
| --: | --------- | ----------------------------------- |
|   1 | directory | Path to the project root to analyse |

### Usage Examples

#### Basic Analysis
```bash
# Analyze current directory
drun gpt .

# Analyze specific project
drun gpt ./my-react-app
drun gpt ~/projects/backend-api
```

#### Typical Output Structure
```
Project Analysis: ./my-react-app
Generated on: 2024-12-19 14:30:15

=== PROJECT TREE ===
my-react-app/
├── src/
│   ├── components/
│   │   ├── Header.tsx
│   │   └── Footer.tsx
│   ├── pages/
│   └── utils/
├── package.json
└── README.md

=== LANGUAGE STATISTICS ===
Language     Files    Lines     Code     Comments
TypeScript      15     2340     1890      180
JavaScript       3      450      380       45
CSS             8      890      720       90

=== FILE CONTENTS ===
[Detailed file contents with syntax highlighting preserved]
```

### Output Details

**File Selection Criteria:**
- Includes source code files (`.js`, `.ts`, `.py`, `.java`, etc.)
- Includes configuration files (`package.json`, `.gitignore`, etc.)
- Excludes large binaries and media files
- Excludes dependency directories (`node_modules`, `.git`)
- Limits file size to prevent overwhelming output

**Use Cases:**
- **Code Review Preparation** - Share project context with reviewers
- **AI-Assisted Development** - Feed codebase to LLMs for analysis
- **Documentation Generation** - Create comprehensive project overviews
- **Architecture Analysis** - Understand project structure and dependencies
- **Onboarding** - Help new team members understand codebase structure

### Dependencies

- **cloc** (optional) - Provides detailed language statistics
- **$EDITOR** environment variable - Determines which editor opens the output
- **Standard Unix tools** - tree, find, grep for file analysis

### Output Management

The generated `gpt.out` file contains:
- Complete project structure visualization
- Statistical analysis of codebase composition
- Selective file contents for AI consumption
- Timestamped analysis for tracking changes over time

**Note:** Output files can be large for substantial codebases. Review file selection criteria if output becomes unwieldy.
