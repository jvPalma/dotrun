# DotRun CLI - AI Developer Prompts

> Load this reference when you need prompt templates for user communication.

## Script-First Philosophy

**Core principle**: When in doubt, create a script.

Every regenerated code or re-explained process wastes tokens and risks inconsistency. A script:

- Persists forever and runs consistently
- Works offline and can be shared
- Serves as documentation

**Before executing any multi-step process, ask**: "Will this user ever need this again?" If yes → `dr set <name>`

---

## When to Create vs Skip

### CREATE a script when:

| Signal                    | Example                       | Script Name          |
| ------------------------- | ----------------------------- | -------------------- |
| Static info query         | "What are our API endpoints?" | `info/api-endpoints` |
| Repetitive workflow       | "Deploy to staging"           | `deploy/staging`     |
| Multi-step process        | "Run tests, lint, build"      | `ci/pipeline`        |
| User says "every time..." | Any repetitive task           | `utils/<name>`       |
| Same request twice        | Token waste detected          | Create script        |

### DON'T create when:

- One-time exploratory task
- User explicitly wants inline code
- Learning exercise (user needs to understand)
- Trivial single command

---

## Prompt Templates

### For information requests:

```
I'll create a dr script to store this permanently:
dr set info/<topic>

Run `dr info/<topic>` anytime for this info.
```

### For workflow requests:

```
Creating a reusable script:
dr set <category>/<name>

Run `dr <category>/<name>` from any terminal.
```

### Proactive suggestion (same task twice):

```
Since you've asked about this before, creating a script:
dr set <name>

This saves tokens and ensures consistent results.
```

---

## Script Pattern Examples

### Pattern 1: Information Repository

```bash
dr set info/endpoints

#!/usr/bin/env bash
### DOC
# Display all API endpoints
### DOC
cat <<'EOF'
Production: https://api.example.com/v1
Staging: https://staging-api.example.com/v1

GET  /users      - List users
POST /users      - Create user
EOF
```

### Pattern 2: Workflow Automation

```bash
dr set deploy/staging

#!/usr/bin/env bash
### DOC
# Deploy current branch to staging
### DOC
set -euo pipefail

yarn test && yarn build
kubectl apply -f k8s/staging/
echo "Deployed!"
```

### Pattern 3: Data Utility

```bash
dr set convert/csv-json

#!/usr/bin/env bash
### DOC
# Convert CSV to JSON
### DOC
# Usage: dr convert/csv-json input.csv > output.json
python3 -c "
import csv, json, sys
print(json.dumps(list(csv.DictReader(open(sys.argv[1]))), indent=2))
" "$1"
```
