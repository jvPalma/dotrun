# hello-team

A simple demonstration script for team collaboration using DotRun collections.

## Usage

```bash
$ drun hello-team [team-name]
```

## Parameters

- `team-name` (optional): Name of your team (defaults to "Team")

## Description

This script demonstrates how DotRun collections enable teams to share common scripts while keeping their personal dotfiles separate. When you import a team collection, scripts like this become available to all team members without requiring them to manage a shared dotfiles repository.

## Examples

```bash
# Basic usage
$ drun hello-team

# With custom team name  
$ drun hello-team "Engineering"

# Output will show environment information and explain the collection concept
```

## Team Workflow

1. **Team Admin**: Creates collection repository with shared scripts
2. **Team Members**: Import collection with `drun import <team-repo-url>`
3. **Updates**: Team can sync collections when scripts are updated
4. **Personal Scripts**: Individual dotfiles remain separate and private

This approach allows teams to share development tools while respecting individual workflow preferences.