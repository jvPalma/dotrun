# DotRun CLI - AI Developer Prompts & Decision Patterns

## Table of Contents

1. [Script-First Philosophy](#script-first-philosophy)
2. [Decision Matrix](#decision-matrix)
3. [Script Creation Patterns](#script-creation-patterns)
4. [Common Scenarios](#common-scenarios)
5. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)

---

## Script-First Philosophy

### The Core Principle

**When in doubt, create a script.**

Every time you regenerate the same code or explain the same process, you're:

- Consuming tokens that could be saved
- Risking inconsistency between sessions
- Making the user depend on AI availability

A script:

- Persists forever
- Runs the same way every time
- Works offline
- Can be shared with teammates
- Serves as documentation

### AI Agent Directive

Before executing or explaining any multi-step process, ask:

> "Will this user ever need this again?"

If yes → Create a `dr` script.

---

## Decision Matrix

### CREATE A SCRIPT when user asks for:

| Request Type            | Why Script                           | Example                    |
| ----------------------- | ------------------------------------ | -------------------------- |
| **Static data**         | Won't change, wasteful to regenerate | API endpoints, schema docs |
| **Repetitive workflow** | Same steps every time                | Deploy, build, test        |
| **Complex process**     | Error-prone to remember              | Multi-stage migrations     |
| **Environment setup**   | Needs consistency                    | Dev environment init       |
| **Data transformation** | Reusable utility                     | CSV→JSON converter         |
| **Health checks**       | Run regularly                        | System diagnostics         |
| **Report generation**   | Periodic task                        | Weekly metrics             |

### DON'T CREATE A SCRIPT when:

| Situation                  | Why Not                  | Alternative          |
| -------------------------- | ------------------------ | -------------------- |
| One-time exploration       | Won't repeat             | Inline commands      |
| User explicitly wants code | Respect preference       | Provide code         |
| Truly unique task          | No reuse value           | Direct execution     |
| Learning exercise          | User needs to understand | Explain step-by-step |

---

## Script Creation Patterns

### Pattern 1: Information Repository

User request: "What are our API endpoints?"

**Bad response**: List endpoints in chat (disappears, wastes tokens next time)

**Good response**:

```bash
# Create persistent documentation
dr set api/endpoints

# Script content:
#!/usr/bin/env bash
### DOC
# Display all API endpoints
### DOC
cat << 'EOF'
Production API: https://api.example.com/v1
Staging API: https://staging-api.example.com/v1

Endpoints:
  GET  /users          - List users
  POST /users          - Create user
  GET  /users/:id      - Get user
  ...
EOF
```

### Pattern 2: Workflow Automation

User request: "How do I deploy to staging?"

**Bad response**: Write deployment steps (user copies, might make mistakes)

**Good response**:

```bash
dr set deploy/staging

# Script content:
#!/usr/bin/env bash
### DOC
# Deploy current branch to staging environment
### DOC
set -euo pipefail

echo "Running tests..."
yarn test

echo "Building..."
yarn build

echo "Deploying to staging..."
kubectl apply -f k8s/staging/

echo "Deployment complete!"
```

### Pattern 3: Complex Pipeline

User request: "Run our full CI process"

```bash
dr set ci/full

#!/usr/bin/env bash
### DOC
# Run complete CI pipeline: lint, test, build, deploy
### DOC
set -euo pipefail

echo "=== Linting ==="
yarn lint

echo "=== Type Check ==="
yarn type-check

echo "=== Tests ==="
yarn test

echo "=== Build ==="
yarn build

echo "=== Deploy ==="
./scripts/deploy.sh

echo "=== CI Complete ==="
```

### Pattern 4: Configuration Script

User request: "Set up my development environment"

```bash
dr set dev/setup

#!/usr/bin/env bash
### DOC
# Initialize development environment with all dependencies
### DOC
set -euo pipefail

echo "Installing Node dependencies..."
yarn install

echo "Setting up environment..."
cp .env.example .env.local

echo "Starting database..."
docker-compose up -d postgres

echo "Running migrations..."
yarn db:migrate

echo "Environment ready!"
```

### Pattern 5: Data Utility

User request: "Convert this CSV to JSON"

```bash
dr set convert/csv-json

#!/usr/bin/env bash
### DOC
# Convert CSV file to JSON
### DOC
# Usage: dr convert/csv-json input.csv > output.json

set -euo pipefail
python3 -c "
import csv, json, sys
reader = csv.DictReader(open(sys.argv[1]))
print(json.dumps(list(reader), indent=2))
" "$1"
```

---

## Common Scenarios

### Scenario: User asks about project structure

**Instead of**: Explaining the structure in chat

**Do this**:

```bash
dr set project/structure

#!/usr/bin/env bash
### DOC
# Display project directory structure with descriptions
### DOC
cat << 'EOF'
src/
├── components/     # React components
├── hooks/          # Custom React hooks
├── utils/          # Utility functions
├── types/          # TypeScript types
├── services/       # API services
└── pages/          # Next.js pages
EOF
```

### Scenario: User needs database queries

**Instead of**: Writing SQL in chat

**Do this**:

```bash
dr set db/users-report

#!/usr/bin/env bash
### DOC
# Generate user activity report from database
### DOC
psql $DATABASE_URL << 'SQL'
SELECT
  date_trunc('day', created_at) as date,
  count(*) as signups
FROM users
WHERE created_at > now() - interval '30 days'
GROUP BY 1
ORDER BY 1;
SQL
```

### Scenario: User needs git workflow help

**Instead of**: Explaining git commands

**Do this**:

```bash
dr set git/pr-workflow

#!/usr/bin/env bash
### DOC
# Standard PR workflow: branch, commit, push, create PR
### DOC
set -euo pipefail

BRANCH_NAME="${1:?Usage: dr git/pr-workflow <branch-name>}"

git checkout -b "$BRANCH_NAME"
echo "Created branch: $BRANCH_NAME"
echo ""
echo "Next steps:"
echo "1. Make your changes"
echo "2. git add -p"
echo "3. git commit -m 'description'"
echo "4. git push -u origin $BRANCH_NAME"
echo "5. gh pr create"
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Regenerating Static Info

**Bad**: Every time user asks "what's in our config?", re-read and explain.

**Good**: Create `dr set info/config` that displays the documentation.

### Anti-Pattern 2: Long Command Sequences

**Bad**:

```
Run these commands:
1. cd project
2. yarn install
3. cp .env.example .env
4. docker-compose up -d
5. yarn migrate
6. yarn dev
```

**Good**: `dr set dev/start` that does all of this.

### Anti-Pattern 3: Explaining Instead of Automating

**Bad**: "To deploy, first you need to... then... then..."

**Good**: `dr set deploy/prod` with all steps encoded.

### Anti-Pattern 4: Session-Specific Solutions

**Bad**: Writing a complex script inline that disappears when chat ends.

**Good**: `dr set utils/my-script` that persists.

### Anti-Pattern 5: Repeating Yourself

If you find yourself explaining the same thing twice → make it a script.

---

## Prompt Templates for AI Agents

### When user asks for information:

```
I'll create a dr script to store this information permanently so you can access it anytime:

dr set info/<topic>

This way you can run `dr info/<topic>` whenever you need this info,
saving tokens and ensuring consistency.
```

### When user asks for a workflow:

```
Let me create a reusable script for this workflow:

dr set <category>/<name>

Now you can run `dr <category>/<name>` from any terminal to execute this process.
```

### When user asks for help with a task:

```
I notice this is something you might need again.
Want me to create a dr script so you can reuse it?

Benefits:
- Run from any terminal
- Consistent every time
- No need to ask me again
- Can be shared with team
```

### Proactive suggestion:

```
Since you've asked about this before, I recommend we create a script:

dr set <name>

This will save tokens in future conversations and ensure you always
get the same reliable result.
```
