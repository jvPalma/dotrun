#!/usr/bin/env bash
# Help message for: dr -col --help / dr collections --help

# Color codes for help output
BOLD=$'\e[1m'
CYAN=$'\e[36m'
GREEN=$'\e[32m'
PURPLE=$'\e[35m'
RED=$'\e[31m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
GRAY=$'\e[90m'
RESET=$'\e[0m'

FEATURE_COLOR="${BLUE}"

cat <<EOF
${BOLD}${CYAN}DotRun Collections System${RESET}

A version-controlled, copy-based system for sharing and managing script collections from
Git repositories. Collections use SHA256 hash tracking for modification detection and
provide interactive conflict resolution during updates.

${BOLD}ARCHITECTURE${RESET}

  ${GRAY}Copy-Based Imports${RESET}   Resources are ${BOLD}copied${RESET} to your config (not symlinked)
                     You can freely edit imported files without breaking updates

  ${GRAY}Hash Tracking${RESET}        SHA256 hashes (8-char) detect if you've modified imported files
                     Update workflow changes based on modification status

  ${GRAY}Git Versioning${RESET}       Collections use semantic version tags (v1.0.0, v1.1.0, etc.)
                     \`sync\` checks for updates, \`update\` applies them interactively

  ${GRAY}Persistent Clones${RESET}    Collections stored in \$DR_CONFIG/collections/ as full git repos
                     Enables diff, merge, and version comparison

${BOLD}COMMANDS${RESET}

  ${CYAN}dr ${FEATURE_COLOR}-col${RESET}                  ${GRAY}[Interactive Browser]${RESET}
                           Browse installed collections and import additional resources
                           Shows update badges (🔄) for collections with available updates

  ${CYAN}dr ${FEATURE_COLOR}-col init${RESET}             ${GRAY}[For Collection Authors]${RESET}
                           Initialize collection structure in current directory
                           Creates: dotrun.collection.yml, scripts/, aliases/, helpers/, configs/
                           Use when creating a new collection to share

  ${CYAN}dr ${FEATURE_COLOR}-col add${RESET} ${YELLOW}<url>${RESET}         ${GRAY}[Install Collection]${RESET}
                           Clone collection from GitHub, display resource menu, import selected
                           Tracks: version, URL, imported files with hashes
                           ${GRAY}Example: dr -col add https://github.com/user/devtools.git${RESET}

  ${CYAN}dr ${FEATURE_COLOR}-col list${RESET}             ${GRAY}[Show Installed]${RESET}
                           List all installed collections with:
                           - Collection name and current version
                           - Repository URL
                           - Count of imported resources by type

  ${CYAN}dr ${FEATURE_COLOR}-col sync${RESET}             ${GRAY}[Check Updates]${RESET}
                           Fetch latest tags from all collections, compare versions
                           Shows which files changed in each update
                           Non-destructive: only checks, doesn't modify files

  ${CYAN}dr ${FEATURE_COLOR}-col update${RESET} ${YELLOW}[name]${RESET}     ${GRAY}[Apply Updates]${RESET}
                           Update collection to latest version with conflict resolution
                           ${YELLOW}[name]${RESET} optional - shows interactive selection if omitted

                           For ${BOLD}unmodified${RESET} files: [U]pdate, [D]iff, [S]kip
                           For ${BOLD}modified${RESET} files:   [K]eep, [O]verwrite, [D]iff, [M]erge, [B]ackup
                           For ${BOLD}new${RESET} files:        [I]mport, [V]iew, [S]kip

  ${CYAN}dr ${FEATURE_COLOR}-col remove${RESET} ${YELLOW}<name>${RESET}     ${GRAY}[Remove Tracking]${RESET}
                           Remove collection from tracking and delete repository clone
                           ${YELLOW}NOTE${RESET}: Imported files remain in your config (you own them)
                           Delete manually if unwanted

${BOLD}WORKFLOWS${RESET}

  ${CYAN}→ As a Collection User${RESET}

    1. Discover and install:
       ${GRAY}dr -col add https://github.com/team/deployment-scripts.git${RESET}

    2. Select resources to import from interactive menu
       Scripts, aliases, helpers, configs displayed by category

    3. Check for updates periodically:
       ${GRAY}dr -col sync${RESET}

    4. Apply updates when available:
       ${GRAY}dr -col update deployment-scripts${RESET}

    5. Resolve conflicts interactively:
       - Keep your changes or accept collection's version
       - View diffs to understand changes
       - Merge conflicting edits when possible

  ${CYAN}→ As a Collection Author${RESET}

    1. Initialize collection structure:
       ${GRAY}cd ~/my-team-scripts && dr -col init${RESET}

    2. Edit dotrun.collection.yml metadata:
       ${GRAY}name, version, description, author, repository${RESET}

    3. Organize resources in subdirectories:
       ${GRAY}scripts/    - Executable scripts (.sh)${RESET}
       ${GRAY}aliases/    - Shell aliases (.aliases)${RESET}
       ${GRAY}helpers/    - Sourced helper modules${RESET}
       ${GRAY}configs/    - Configuration files (.config)${RESET}

    4. Commit and tag with semantic versions:
       ${GRAY}git add . && git commit -m "Add deployment automation"${RESET}
       ${GRAY}git tag v1.0.0 && git push --tags${RESET}

    5. Share repository URL with your team
       They install with: ${GRAY}dr -col add <your-repo-url>${RESET}

    6. For updates, increment version and create new tag:
       ${GRAY}# Edit dotrun.collection.yml: version: "1.1.0"${RESET}
       ${GRAY}git commit -am "Add monitoring script" && git tag v1.1.0${RESET}
       ${GRAY}git push --tags${RESET}

${BOLD}COLLECTION STRUCTURE${RESET}

  ${GRAY}Repository Layout:${RESET}

    dotrun.collection.yml    ${GRAY}# Required metadata${RESET}
    scripts/                 ${GRAY}# Executable scripts${RESET}
      deploy.sh
      backup.sh
      git/                   ${GRAY}# Subdirectories preserved on import${RESET}
        sync.sh
    aliases/                 ${GRAY}# Shell aliases${RESET}
      01-git.aliases
      02-docker.aliases
    helpers/                 ${GRAY}# Sourced modules${RESET}
      validation.sh
    configs/                 ${GRAY}# Global variables${RESET}
      01-api.config

  ${GRAY}Metadata (dotrun.collection.yml):${RESET}

    name: "deployment-tools"          ${GRAY}# Required: unique identifier${RESET}
    version: "1.0.0"                  ${GRAY}# Required: semantic version${RESET}
    description: "Deploy automation"  ${GRAY}# Required: brief description${RESET}
    author: "DevOps Team"             ${GRAY}# Required: creator name${RESET}
    repository: "https://github.com/team/deploy.git"  ${GRAY}# Required: git URL${RESET}
    license: "MIT"                    ${GRAY}# Optional${RESET}
    homepage: "https://docs.team.com" ${GRAY}# Optional${RESET}
    dependencies: []                  ${GRAY}# Optional: other collections${RESET}

${BOLD}TRACKING & STORAGE${RESET}

  ${GRAY}Collections Directory${RESET}   \$DR_CONFIG/collections/${YELLOW}<name>${RESET}/
                           Full git clone for each collection
                           ${GRAY}Example: ~/.config/dotrun/collections/devtools/${RESET}

  ${GRAY}Tracking Database${RESET}       ~/.local/share/dotrun/collections.conf
                           INI format with sections per collection
                           Stores: URL, version, path, imported files with hashes

  ${GRAY}Imported Resources${RESET}      \$DR_CONFIG/{scripts,aliases,helpers,configs}/
                           Copied from collection to your config
                           You own these files and can edit freely

${BOLD}CONFLICT RESOLUTION${RESET}

  When updating a collection, DotRun compares file hashes to detect modifications:

  ${GREEN}Unmodified File${RESET} (hash matches original)
    ${GRAY}[U]pdate${RESET}  - Overwrite with collection's new version
    ${GRAY}[D]iff${RESET}    - Show changes between versions
    ${GRAY}[S]kip${RESET}    - Keep current version, don't update

  ${YELLOW}Modified File${RESET} (you changed it after import)
    ${GRAY}[K]eep${RESET}     - Keep your version, skip update
    ${GRAY}[O]verwrite${RESET} - Replace with collection version (lose your changes)
    ${GRAY}[D]iff${RESET}     - Show 3-way diff: original | yours | collection's
    ${GRAY}[M]erge${RESET}    - Attempt 3-way merge (git merge-file)
    ${GRAY}[B]ackup${RESET}   - Save yours as .bak, then overwrite

  ${BLUE}New File${RESET} (added in collection update)
    ${GRAY}[I]mport${RESET}  - Copy to your config
    ${GRAY}[V]iew${RESET}    - Display file contents
    ${GRAY}[S]kip${RESET}    - Don't import

${BOLD}EXAMPLES${RESET}

  ${GRAY}# Install and browse collection${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-col add ${YELLOW}https://github.com/user/devtools.git${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-col${RESET}                                    ${GRAY}# Browse interactively${RESET}

  ${GRAY}# Check and apply updates${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-col sync${RESET}                               ${GRAY}# Check all for updates${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-col update${RESET}                             ${GRAY}# Interactive: select collection${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-col update ${YELLOW}devtools${RESET}                    ${GRAY}# Direct: update specific collection${RESET}

  ${GRAY}# Create and share a collection${RESET}
  mkdir ~/team-scripts && cd ~/team-scripts
  ${CYAN}dr ${FEATURE_COLOR}-col init${RESET}                               ${GRAY}# Initialize structure${RESET}
  ${GRAY}# ... add scripts to scripts/, aliases to aliases/ ...${RESET}
  vim dotrun.collection.yml                  ${GRAY}# Edit metadata${RESET}
  git init && git add .
  git commit -m "Initial collection"
  git tag v1.0.0
  git remote add origin https://github.com/team/scripts.git
  git push -u origin master --tags

  ${GRAY}# Manage installed collections${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-col list${RESET}                               ${GRAY}# Show all installed${RESET}
  ${CYAN}dr ${FEATURE_COLOR}-col remove ${YELLOW}old-collection${RESET}              ${GRAY}# Remove tracking${RESET}

${BOLD}TIPS & BEST PRACTICES${RESET}

  ${GRAY}For Users:${RESET}
  - Run ${CYAN}dr ${FEATURE_COLOR}-col sync${RESET} regularly to stay updated
  - Use ${GRAY}[D]iff${RESET} option during updates to understand changes
  - Modified files won't be overwritten without confirmation
  - Imported files are yours - edit freely without breaking updates

  ${GRAY}For Authors:${RESET}
  - Use semantic versioning: MAJOR.MINOR.PATCH (1.0.0, 1.1.0, 2.0.0)
  - Increment MAJOR for breaking changes, MINOR for features, PATCH for fixes
  - Tag every release: ${GRAY}git tag v1.0.0${RESET}
  - Keep dotrun.collection.yml version in sync with git tags
  - Document breaking changes in scripts with ${GRAY}### DOC${RESET} blocks
  - Test imports in a clean environment before sharing

  ${GRAY}Version Management:${RESET}
  - Collections track installed version vs. available version
  - ${FEATURE_COLOR}sync${RESET} fetches tags but doesn't modify files
  - ${FEATURE_COLOR}update${RESET} checks out new tag and prompts for each changed file
  - Git history preserved - can always ${GRAY}git checkout${RESET} older versions

${GRAY}Use 'dr -col <command>' to manage collections. Both flag (-col) and subcommand${RESET}
${GRAY}(collections) styles work identically.${RESET}
EOF
