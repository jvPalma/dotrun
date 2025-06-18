# Example DotRun Collection

This is an example DotRun collection that demonstrates how teams can share scripts using DotRun's collection system.

## What's Included

- `hello-team`: A simple demonstration script showing collection concepts
- `docker-cleanup`: A practical utility for cleaning up Docker resources

## How to Use This Collection

### Import the Collection

```bash
# Import from a git repository
drun import https://github.com/your-team/dotrun-collection.git team-tools

# Import from local path
drun import /path/to/this/collection team-tools
```

### Use the Scripts

```bash
# List all available scripts (including imported ones)
drun -L

# Run team scripts
drun hello-team "Engineering Team"
drun docker-cleanup
```

### Manage Collections

```bash
# List installed collections
drun collections list:details

# Remove a collection
drun collections remove team-tools
```

## For Team Administrators

### Creating Your Own Collection

1. **Create the structure**:
   ```bash
   mkdir my-team-collection
   cd my-team-collection
   mkdir -p bin docs
   ```

2. **Add metadata** (`.drun-collection.yml`):
   ```yaml
   name: "my-team-tools"
   description: "Shared scripts for our team"
   author: "Team Lead"
   version: "1.0.0"
   # ... see example metadata file
   ```

3. **Add scripts** (`bin/*.sh`):
   - Make them executable
   - Include `### DOC` sections for inline help
   - Follow team coding standards

4. **Add documentation** (`docs/*.md`):
   - One markdown file per script
   - Include usage examples
   - Document requirements and dependencies

5. **Version control**:
   ```bash
   git init
   git add .
   git commit -m "Initial team collection"
   git remote add origin <your-team-repo>
   git push -u origin main
   ```

### Team Workflow

1. **Setup**: Team members run `drun team init <repo-url>`
2. **Updates**: When scripts change, team members can re-import
3. **Personal Scripts**: Individual dotfiles stay separate
4. **Multiple Collections**: Teams can have dev/staging/prod collections

## Integration with Existing Dotfiles

This collection system works seamlessly with:

- **yadm**: Use `drun yadm-init` to integrate with existing yadm repos
- **chezmoi**: Collections are stored separately from personal configs
- **Custom setups**: DotRun doesn't interfere with existing dotfile management

## Benefits

- ✅ **Team Collaboration**: Share scripts without sharing personal configs
- ✅ **Environment Separation**: Different collections for different environments
- ✅ **Easy Updates**: Simple import/export workflow
- ✅ **Non-intrusive**: Works with any dotfile manager
- ✅ **Version Control**: Collections are regular git repositories