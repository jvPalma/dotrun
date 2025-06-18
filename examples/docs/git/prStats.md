# prStats — comprehensive pull request performance audit tool

## Synopsis

```bash
drun git/prStats <owner/repo> <label-name>
```

## Description

A powerful analytics tool that audits pull request workflows by collecting detailed timing metrics and reviewer data. Designed for teams who want to understand their development velocity, review patterns, and process bottlenecks.

**Key Metrics Collected:**
- Time from PR creation to label assignment
- Time from label assignment to merge
- Reviewer assignment vs. actual review participation
- PR lifecycle timestamps with second-level precision

## Arguments

| Position | Name | Description | Example |
|----------|------|-------------|---------|
| 1 | owner/repo | GitHub repository in format owner/repository | `myorg/myapp` |
| 2 | label-name | Label to track for timing analysis | `qa-approved` |

## Output Format

Generates CSV data with the following columns:

```csv
number,created_at,label_added_at,requested_reviewers,reviewers,merged_at,secs_created→label,secs_label→merged
```

### Column Descriptions

- **number**: PR number
- **created_at**: ISO timestamp when PR was created
- **label_added_at**: ISO timestamp when target label was first applied
- **requested_reviewers**: Comma-separated list of requested reviewer usernames
- **reviewers**: Comma-separated list of users who actually submitted reviews
- **merged_at**: ISO timestamp when PR was merged
- **secs_created→label**: Time in seconds from PR creation to label assignment
- **secs_label→merged**: Time in seconds from label assignment to merge

## Use Cases

### Development Velocity Analysis
Track how long it takes for PRs to move through your workflow stages:
```bash
drun git/prStats myorg/frontend-app "ready-for-review"
```

### QA Process Monitoring
Measure time from QA approval to deployment:
```bash
drun git/prStats myorg/backend-api "qa-approved"
```

### Review Efficiency Metrics
Compare requested vs. actual reviewers to optimize team assignments:
```bash
drun git/prStats myorg/platform "design-approved"
```

## Data Analysis Examples

### Import into spreadsheet
```bash
drun git/prStats myorg/myapp "ready-to-merge" > pr_analysis.csv
```

### Calculate average review time
```bash
drun git/prStats myorg/myapp "approved" | awk -F, 'NR>1 && $7 {sum+=$7; count++} END {print "Average review time:", sum/count/3600, "hours"}'
```

### Find bottlenecks
```bash
drun git/prStats myorg/myapp "qa-passed" | sort -t, -k7 -nr | head -10
```

## Features

### Robust API Handling
- **Automatic retries**: Up to 15 attempts with exponential backoff
- **Timeout protection**: 140-second timeout per API call
- **Rate limit awareness**: Built-in delay mechanisms
- **Error resilience**: Continues processing even if individual PRs fail

### Comprehensive Data Collection
- **Label event tracking**: Finds exact timestamp when target label was applied
- **Review participation**: Captures both requested and actual reviewers
- **Multi-page support**: Handles repositories with large numbers of PRs and events
- **Author filtering**: Only processes PRs authored by the current user

### Performance Optimizations
- **Parallel-ready**: Designed for potential concurrent processing
- **Memory efficient**: Streams data rather than loading everything into memory
- **API efficient**: Minimal API calls with maximum data extraction

## Configuration

### Environment Variables

- **GH_MAX_RETRIES**: Maximum API retry attempts (default: 15)
- **GH_TIMEOUT**: Timeout per API call in seconds (default: 140)

### Example with custom settings
```bash
GH_MAX_RETRIES=10 GH_TIMEOUT=60 drun git/prStats myorg/myapp "approved"
```

## Dependencies

- **GitHub CLI (`gh`)**: Must be authenticated and configured
- **jq**: JSON processing for API response parsing
- **bash 4+**: For array handling and modern shell features

## Authentication

Requires GitHub CLI authentication:
```bash
gh auth login
```

## Limitations

- **Author scope**: Only analyzes PRs authored by the authenticated user
- **Merged PRs only**: Focuses on completed workflow analysis
- **Label dependency**: Requires consistent label usage for meaningful timing data
- **API rate limits**: Subject to GitHub API quotas (handled gracefully)

## Related Tools

- Combine with `drun git/prDescription` for PR content analysis
- Use with data visualization tools like Excel, Tableau, or Python pandas
- Integrate into CI/CD for automated performance reporting

