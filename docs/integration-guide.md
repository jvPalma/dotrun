# DotRun Integration Guide

DotRun is designed to work **with** your existing dotfile management setup, not replace it. This guide shows how to integrate DotRun with popular dotfile managers and establish team workflows.

## Philosophy

DotRun focuses on **script management and team collaboration** while letting you keep your existing dotfile workflow. Whether you use yadm, chezmoi, or a custom setup, DotRun complements your dotfiles without interfering.

## Integration with Existing Dotfile Managers

### YADM Integration

[YADM](https://yadm.io/) is a popular dotfiles manager that uses git directly. DotRun integrates seamlessly:

```bash
# Setup DotRun to work with your existing yadm repository
drun yadm-init
```

This command:
- ✅ Creates DotRun structure within your yadm-managed dotfiles
- ✅ Migrates existing DotRun config to yadm location
- ✅ Sets up proper .gitignore for collections
- ✅ Creates symlinks for seamless operation

**Benefits:**
- Your personal scripts are version controlled with your dotfiles
- Team collections remain separate (not in your personal repo)
- Works with existing yadm workflows
- Easy backup and sync across machines

### Chezmoi Integration

[Chezmoi](https://www.chezmoi.io/) users can integrate DotRun by managing the config directory:

```bash
# Add DotRun config to chezmoi
chezmoi add ~/.config/dotrun

# Edit chezmoi template to ensure DotRun is set up  
chezmoi edit ~/.local/bin/drun
```

### Custom Dotfile Setups

For custom setups, DotRun works out of the box. Simply ensure your dotfile sync includes:
- `~/.config/dotrun/` (your personal scripts)
- Exclude `~/.config/dotrun/collections/` (team collections managed separately)

## Team Collaboration Workflows

### Setting Up Team Collections

Team administrators can create shared script collections:

```bash
# Create a new collection repository
mkdir company-scripts
cd company-scripts

# Set up collection structure
mkdir -p bin docs
cp /path/to/dotrun/template/collection/.drun-collection.yml .

# Edit metadata
vim .drun-collection.yml  # Update name, description, team info

# Add team scripts
drun add company/deploy
drun add company/database-backup
drun add company/dev-environment

# Version control
git init
git add .
git commit -m "Initial company scripts collection"
git remote add origin git@github.com:company/dotrun-scripts.git
git push -u origin main
```

### Team Member Setup

Team members can easily access shared collections:

```bash
# Setup team collection (one-time)
drun team init git@github.com:company/dotrun-scripts.git company

# Use team scripts
drun -L  # See all scripts including team ones
drun company/deploy staging
drun company/database-backup
```

### Multiple Team Collections

Teams can maintain different collections for different purposes:

```bash
# Development tools
drun team init git@github.com:company/dev-tools.git dev

# DevOps scripts  
drun team init git@github.com:company/devops-scripts.git ops

# QA automation
drun team init git@github.com:company/qa-scripts.git qa
```

### Environment-Specific Collections

Collections can be tailored for different environments:

```bash
# Development environment scripts
drun import git@github.com:company/scripts.git#dev-branch dev-tools

# Production scripts (restricted access)
drun import git@github.com:company/prod-scripts.git prod-tools

# Staging scripts
drun import git@github.com:company/scripts.git#staging-branch staging-tools
```

## Collection Management

### Creating Collections

```bash
# Export your scripts as a collection
drun export my-tools ./my-collection --git

# Share with team
cd my-collection
git remote add origin git@github.com:username/my-dotrun-scripts.git
git push -u origin main
```

### Importing Collections

```bash
# From git repository
drun import https://github.com/team/scripts.git team-tools

# From local directory
drun import /path/to/collection my-tools

# With custom name
drun import git@github.com:company/tools.git company-utilities
```

### Managing Collections

```bash
# List installed collections
drun collections list
drun collections list:details

# Remove collections
drun collections remove old-collection
drun collections remove temp-tools --force
```

## Sync and Updates

### Manual Sync (Current)

```bash
# Update a team collection
drun collections remove company-tools
drun team init git@github.com:company/scripts.git company-tools
```

### Planned: Automatic Sync

Future versions will include:
```bash
# Sync all team collections
drun team sync

# Sync specific collection
drun sync company-tools

# Check for updates
drun team status
```

## Best Practices

### For Individuals

1. **Keep Personal Scripts in Dotfiles**: Use `drun yadm-init` or similar integration
2. **Use Collections for Team Tools**: Import team collections separately
3. **Organize by Purpose**: Create folders like `work/`, `personal/`, `tools/`
4. **Document Your Scripts**: Use both inline docs and markdown files

### For Teams

1. **Standardize Collection Structure**: Use consistent naming and organization
2. **Include Documentation**: Every script should have usage docs
3. **Version Your Collections**: Use semantic versioning for collection releases
4. **Environment Separation**: Different collections for dev/staging/prod
5. **Access Control**: Use private repositories for sensitive scripts

### For Organizations

1. **Collection Governance**: Establish who can publish team collections
2. **Security Review**: Review scripts before adding to team collections
3. **Training**: Provide team training on DotRun usage
4. **Integration**: Integrate with existing CI/CD and tooling

## Troubleshooting

### Common Issues

**Collections not found after import:**
```bash
# Check collections directory
ls ~/.config/dotrun/collections/

# Verify import was successful
drun collections list:details
```

**Scripts not executable:**
```bash
# Fix permissions on imported scripts
find ~/.config/dotrun/bin -name "*.sh" -exec chmod +x {} \;
```

**YADM integration issues:**
```bash
# Verify yadm is working
yadm status

# Re-run integration if needed
drun yadm-init
```

**Collection conflicts:**
```bash
# Remove conflicting collection
drun collections remove conflicting-name

# Re-import with different name
drun import <source> new-name
```

## Advanced Usage

### Custom Collection Templates

Create your own collection templates:

```bash
# Copy example template
cp -r ~/.config/dotrun/template/collection my-template

# Customize metadata and scripts
vim my-template/.drun-collection.yml

# Use as basis for new collections
cp -r my-template new-collection
```

### Integration with CI/CD

```bash
# In your CI pipeline
drun import git@github.com:company/ci-scripts.git ci-tools
drun ci-tools/deploy $ENVIRONMENT
drun ci-tools/notify-slack "Deployment complete"
```

### Dotfile Distribution

```bash
# Include DotRun setup in your dotfile installer
#!/bin/bash
# install-dotfiles.sh

# Install DotRun
curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh | sh

# Setup with dotfiles
drun yadm-init

# Import team collections
drun team init git@github.com:company/scripts.git company
```

## Migration Guide

### From Existing Script Collections

If you have existing script collections:

1. **Create collection structure**:
   ```bash
   mkdir my-existing-collection
   cd my-existing-collection
   mkdir -p bin docs
   ```

2. **Copy scripts to bin/**:
   ```bash
   cp ~/scripts/* bin/
   chmod +x bin/*.sh
   ```

3. **Create metadata**:
   ```bash
   cp ~/.config/dotrun/template/collection/.drun-collection.yml .
   # Edit as needed
   ```

4. **Add documentation**:
   ```bash
   # Create docs for each script
   for script in bin/*.sh; do
     name=$(basename "$script" .sh)
     echo "# $name" > "docs/$name.md"
     echo "Documentation for $name script" >> "docs/$name.md"
   done
   ```

5. **Import into DotRun**:
   ```bash
   drun import . my-collection
   ```

### From Other Tools

**From Homebrew taps or similar**:
- Create collections for commonly used script bundles
- Document dependencies and installation requirements
- Use DotRun's package validation features

**From team wikis or documentation**:
- Convert documented procedures into executable scripts
- Organize by team or functional area
- Include original documentation as markdown files

This integration approach ensures DotRun enhances your existing workflow without disrupting established practices.