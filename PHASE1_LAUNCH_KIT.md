# Phase 1: Team Launch Kit

**Status:** Ready to execute  
**Timeline:** 1 day prep + 1 week active launch  
**Success target:** 80%+ team adoption

---

## Pre-Launch Checklist (Day Before)

### ✅ Technical Preparation

- [ ] Install dotrun on your machine
- [ ] Create team collection repository (GitHub/GitLab)
- [ ] Create 5 starter scripts (see Scripts section below)
- [ ] Test complete demo flow at least once
- [ ] Size terminal appropriately for screen sharing (120 columns)

### ✅ Content Preparation

- [ ] Find 2-3 real Slack examples of repeated questions
- [ ] Copy Slack announcement message (see below)
- [ ] Review presentation script
- [ ] Prepare installation command in clipboard
- [ ] Schedule presentation time (team standup or dedicated 10 min slot)

---

## Day 1: Launch Day Timeline

### Morning (9:00 AM)

**Send Slack Announcement**

```
Hey team! 👋

I want to show you something that could save us a lot of time.

You know how we keep asking each other for the same commands?
- "What's the deploy command again?"
- "Can someone share that Git cleanup script?"
- "How do I reset my local database?"

I've been testing a tool called dotrun that solves this problem.

Instead of searching Slack, you run:
  dr deploy staging
  dr git/cleanup
  dr db/reset

From any directory. With built-in help. Documented.

I'll do a quick 5-minute demo today at [TIME]. If you can't make it,
I'll share a recording and help anyone one-on-one after.

I think this could cut down our "how do I..." questions by 90%.

Want to see it in action? Join at [TIME] or ping me for help after.
```

### Midday (Presentation - 10 minutes)

**Presentation Flow:**

#### Part 1: Show the Pain (60 seconds)

**[Open Slack]**

"Let me show you something. Watch how I find a command someone asked about..."

**[Search for a real example, scroll, show multiple threads]**

"This was 3 days ago... Sarah asked yesterday... John asked last week..."

**[Pause for effect]**

"We've had this exact conversation 4 times this month. And these are just the ones I can find."

#### Part 2: The Solution (30 seconds)

**[Open terminal]**

"I'm going to show you something that takes 30 seconds to install and solves this problem."

**[Paste command]**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)
```

**[Wait for completion]**

"30 seconds. That's it. Now watch this."

#### Part 3: Create First Script (60 seconds)

"Let's take that deploy command everyone keeps asking about."

```bash
dr set deploy
```

**[Editor opens - add your actual deploy command]**

```bash
#!/bin/bash
### DOC
# Deploy application to specified environment
#
# Usage:
#   dr deploy staging
#   dr deploy production
#
# Safety: Asks for confirmation before production deploys
### DOC

ENV=${1:-staging}

if [ "$ENV" = "production" ]; then
  read -p "Deploy to PRODUCTION? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
  fi
fi

echo "Deploying to $ENV..."
# Your actual deploy command here
```

**[Save and exit]**

"Now from ANY directory:"

```bash
cd ~/Documents
dr deploy staging
```

**[Command runs]**

"No more searching Slack. No more asking. Just run it."

#### Part 4: Discovery (60 seconds)

"But how do you remember all the scripts?"

```bash
dr <TAB>
```

**[Shows categorized tab completion]**

"See? Organized by category."

```bash
dr -L
```

**[Shows list with descriptions]**

"Everything is listed with descriptions."

```bash
dr help deploy
```

**[Shows the DOC block]**

"Every script documents itself. Usage examples, parameters, warnings - all built in."

#### Part 5: Team Sharing (60 seconds)

"Here's where it gets powerful for teams."

**[Show team collection]**

"I created a collection with our most common scripts:"

```bash
dr -col add https://github.com/[your-team]/dotrun-scripts.git
```

"Now everyone has the same scripts. When I update `deploy`, you get the update.
No more outdated wiki pages. No more 'which version are you using?'"

```bash
dr -col sync # Check for updates
```

"It's like Git, but for commands."

#### Part 6: Call to Action (30 seconds)

"I want everyone to try this TODAY. Not next week. Today.

Here's what I'm asking:

1. Install it (30 seconds)
2. Run ONE script (dr git/cleanup is a good start)
3. Tell me if it helped or if it's annoying

Who's willing to give this 5 minutes right now? I'll help anyone who wants to try it."

**[Answer questions]**

### Afternoon: One-on-One Help

**Post in Slack:**

```
Thanks everyone who joined the demo!

For those who want to try dotrun:

1. Install:
   bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)

2. Add our team collection:
   dr -col add https://github.com/[your-team]/dotrun-scripts.git

3. Try a script:
   dr git/cleanup
   dr -L  (to see all available scripts)

I'm available all afternoon to help anyone get set up. Just ping me!
```

**Celebrate early wins:**

```
🎉 Quick win: John just used `dr git/cleanup` and removed 37 old branches in 10 seconds!

This is exactly the kind of time we're saving with dotrun.
```

---

## Starter Scripts

Create these 5 scripts in your team collection **before** the presentation.

### 1. scripts/git/cleanup

```bash
#!/bin/bash
### DOC
# Clean up merged Git branches
#
# Usage:
#   dr git/cleanup           # Interactive mode (asks for confirmation)
#   dr git/cleanup --force   # Skip confirmation
#
# What it does:
#   - Fetches latest from origin
#   - Identifies branches merged into main/master
#   - Deletes local branches that are merged
#
# Safety: Always keeps main, master, develop, and current branch
### DOC

set -e

FORCE=false
if [[ "$1" == "--force" ]]; then
  FORCE=true
fi

# Determine main branch
MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Fetching latest from origin..."
git fetch --all --prune

# Get merged branches
MERGED_BRANCHES=$(git branch --merged "$MAIN_BRANCH" | grep -v "^\*" | grep -v "  $MAIN_BRANCH$" | grep -v "  master$" | grep -v "  develop$" | sed 's/^[* ]*//')

if [[ -z "$MERGED_BRANCHES" ]]; then
  echo "No merged branches to clean up!"
  exit 0
fi

echo ""
echo "The following branches are merged into $MAIN_BRANCH and can be deleted:"
echo "$MERGED_BRANCHES"
echo ""

if [[ "$FORCE" != "true" ]]; then
  read -p "Delete these branches? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

echo "$MERGED_BRANCHES" | xargs -r git branch -d

echo "✓ Cleanup complete!"
```

### 2. scripts/docker/clean

```bash
#!/bin/bash
### DOC
# Clean up Docker resources
#
# Usage:
#   dr docker/clean              # Clean stopped containers and dangling images
#   dr docker/clean --all        # Clean everything (aggressive)
#   dr docker/clean --volumes    # Also remove unused volumes
#
# What it does:
#   - Removes stopped containers
#   - Removes dangling images (untagged)
#   - Optionally removes unused volumes
#
# Safety: Asks for confirmation, shows what will be removed
### DOC

set -e

MODE="safe"
REMOVE_VOLUMES=false

if [[ "$1" == "--all" ]]; then
  MODE="aggressive"
elif [[ "$1" == "--volumes" ]]; then
  REMOVE_VOLUMES=true
fi

echo "Docker disk usage BEFORE cleanup:"
docker system df
echo ""

if [[ "$MODE" == "aggressive" ]]; then
  echo "⚠️  AGGRESSIVE MODE: This will remove:"
  echo "  - All stopped containers"
  echo "  - All unused images (not just dangling)"
  echo "  - All unused networks"
  echo "  - All build cache"
  echo ""
  read -p "Continue? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
  docker system prune -a -f
else
  echo "Removing:"
  echo "  - Stopped containers"
  echo "  - Dangling images"
  echo "  - Unused networks"
  echo ""
  read -p "Continue? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
  docker system prune -f
fi

if [[ "$REMOVE_VOLUMES" == "true" ]]; then
  echo ""
  echo "⚠️  VOLUME CLEANUP: This will remove unused volumes (may delete data!)"
  read -p "Remove unused volumes? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker volume prune -f
  fi
fi

echo ""
echo "Docker disk usage AFTER cleanup:"
docker system df
echo ""
echo "✓ Cleanup complete!"
```

### 3. scripts/env/setup

```bash
#!/bin/bash
### DOC
# Set up development environment for this project
#
# Usage:
#   dr env/setup
#
# What it does:
#   - Installs project dependencies
#   - Copies .env.example to .env (if needed)
#   - Runs any necessary setup scripts
#
# Note: Customize this for your project's tech stack
### DOC

set -e

echo "Setting up development environment..."

# Check for required tools
command -v node >/dev/null 2>&1 || {
  echo "Error: Node.js is required but not installed."
  exit 1
}

# Install dependencies
if [[ -f "package.json" ]]; then
  echo "Installing Node.js dependencies..."
  yarn install || npm install
fi

if [[ -f "requirements.txt" ]]; then
  echo "Installing Python dependencies..."
  pip install -r requirements.txt
fi

# Set up environment file
if [[ -f ".env.example" ]] && [[ ! -f ".env" ]]; then
  echo "Creating .env file from .env.example..."
  cp .env.example .env
  echo "⚠️  Remember to fill in your .env file with actual values!"
fi

# Run database migrations if applicable
if [[ -f "package.json" ]] && grep -q "migrate" package.json; then
  echo "Running database migrations..."
  yarn migrate || npm run migrate
fi

echo ""
echo "✓ Environment setup complete!"
echo ""
echo "Next steps:"
echo "  1. Edit .env with your local configuration"
echo "  2. Run 'dr dev' to start the development server"
```

### 4. scripts/db/reset

```bash
#!/bin/bash
### DOC
# Reset local database to clean state
#
# Usage:
#   dr db/reset
#
# What it does:
#   - Drops the database
#   - Creates a fresh database
#   - Runs migrations
#   - Seeds with test data (if applicable)
#
# Safety: Only works in development environment
#         Asks for confirmation before proceeding
### DOC

set -e

# Safety check: Ensure we're in development
if [[ "${NODE_ENV}" == "production" ]] || [[ "${RAILS_ENV}" == "production" ]]; then
  echo "Error: Cannot reset database in production environment!"
  exit 1
fi

echo "⚠️  This will DELETE all data in your local database!"
echo ""
read -p "Reset local database? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi

echo "Resetting database..."

# Customize these commands for your stack
# Example for Node.js with Sequelize:
if [[ -f "package.json" ]] && grep -q "sequelize" package.json; then
  npx sequelize-cli db:drop
  npx sequelize-cli db:create
  npx sequelize-cli db:migrate
  npx sequelize-cli db:seed:all
fi

# Example for Rails:
if [[ -f "Rakefile" ]] && grep -q "Rails" Rakefile; then
  bundle exec rake db:reset
  bundle exec rake db:seed
fi

echo ""
echo "✓ Database reset complete!"
```

### 5. scripts/deploy

```bash
#!/bin/bash
### DOC
# Deploy application to specified environment
#
# Usage:
#   dr deploy staging
#   dr deploy production
#
# Arguments:
#   environment    Target environment (staging|production)
#
# Safety: Requires confirmation for production deploys
### DOC

set -e

ENV=${1:-staging}

# Validate environment
if [[ "$ENV" != "staging" ]] && [[ "$ENV" != "production" ]]; then
  echo "Error: Invalid environment '$ENV'"
  echo "Usage: dr deploy [staging|production]"
  exit 1
fi

# Production safety check
if [[ "$ENV" == "production" ]]; then
  echo "⚠️  PRODUCTION DEPLOYMENT"
  echo ""
  read -p "Deploy to PRODUCTION? This will affect live users. [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

echo "Deploying to $ENV..."

# Add your actual deployment commands here
# Examples:
# - git push heroku-$ENV main
# - ./deploy-script.sh $ENV
# - kubectl apply -f k8s/$ENV/
# - docker build && docker push && kubectl rollout restart

# Placeholder example:
echo "Running deployment for $ENV..."
echo "(Replace this with your actual deployment command)"

echo ""
echo "✓ Deployment to $ENV complete!"
echo ""
echo "Next steps:"
echo "  - Check logs: dr logs $ENV"
echo "  - Run smoke tests: dr test smoke $ENV"
echo "  - Monitor: [your monitoring URL]"
```

---

## Team Collection Repository Structure

Create this structure in your team's GitHub/GitLab repo:

```
dotrun-scripts/
├── README.md
├── CONTRIBUTING.md
├── .gitignore
├── .dotrun-collection
├── scripts/
│   ├── git/
│   │   ├── cleanup
│   │   └── sync-fork
│   ├── docker/
│   │   ├── clean
│   │   └── logs
│   ├── env/
│   │   ├── setup
│   │   └── template  (for .env management)
│   ├── db/
│   │   ├── reset
│   │   └── seed
│   └── deploy
└── helpers/
    └── common.sh  (shared functions)
```

### README.md

````markdown
# Team DotRun Scripts

Shared scripts for [Your Team Name] development workflows.

## Installation

1. Install dotrun:
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)
   ```
````

2. Add this collection:

   ```bash
   dr -col add https://github.com/[your-org]/dotrun-scripts.git
   ```

3. List available scripts:
   ```bash
   dr -L
   ```

## Available Scripts

- **deploy** - Deploy to staging/production
- **git/cleanup** - Remove merged branches
- **docker/clean** - Clean up Docker resources
- **env/setup** - Set up development environment
- **db/reset** - Reset local database

## Usage

```bash
dr <script-name> [arguments]
dr help <script-name>  # Show documentation
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding new scripts.

````

### CONTRIBUTING.md

```markdown
# Contributing to Team Scripts

## Adding a New Script

1. Create the script file in the appropriate category:
   ```bash
   # Create file: scripts/category/script-name
````

2. Use the template structure:

   ```bash
   #!/bin/bash
   ### DOC
   # Brief description
   #
   # Usage:
   #   dr script-name [arguments]
   #
   # What it does:
   #   - Step 1
   #   - Step 2
   ### DOC
   
   set -e # Exit on error
   
   # Your script here
   ```

3. Add safety features:
   - Confirmation prompts for destructive operations
   - Environment checks (don't run in production)
   - Clear error messages
   - Input validation

4. Test locally:

   ```bash
   dr <your-script>
   dr help <your-script>
   ```

5. Submit a Pull Request:
   - Describe what the script does
   - Explain when to use it
   - Note any dependencies

## Script Guidelines

- ✅ DO include DOC blocks with usage examples
- ✅ DO add confirmation prompts for destructive operations
- ✅ DO validate inputs and fail fast with clear errors
- ✅ DO use `set -e` to exit on errors
- ❌ DON'T hardcode secrets or credentials
- ❌ DON'T assume specific directory structures
- ❌ DON'T create scripts that could damage production

## Secrets Management

Never commit secrets! Use environment variables or .env files:

```bash
# In script:
API_KEY=${API_KEY:-}
if [[ -z "$API_KEY" ]]; then
  echo "Error: API_KEY environment variable not set"
  exit 1
fi
```

Create a `.env.template` file showing required variables without actual values.

## Review Process

All scripts are reviewed for:

1. Security (no hardcoded secrets, safe operations)
2. Documentation (clear DOC block)
3. Safety (confirmation prompts where needed)
4. Testability (can it be run safely?)

```

### .gitignore

```

# Environment files (never commit secrets!)

.env
.env.local
_.key
_.pem

# OS files

.DS_Store
Thumbs.db

# Editor files

_.swp
_.swo
\*~
.vscode/
.idea/

````

### .dotrun-collection

```json
{
  "name": "team-scripts",
  "description": "Shared development scripts for [Your Team]",
  "version": "1.0.0",
  "categories": {
    "git": "Git workflows and cleanup",
    "docker": "Docker and container management",
    "env": "Environment setup and configuration",
    "db": "Database operations",
    "deploy": "Deployment workflows"
  }
}
````

---

## Follow-Up Messages

### Day 3: Quick Win Share

```
Quick dotrun update:

So far this week:
- 6 team members installed ✓
- 12 scripts run
- Zero "how do I deploy?" questions in Slack

My favorite moment: Watching Sarah use `dr git/cleanup` and realize
she had 43 old branches taking up space.

If you haven't tried it yet, the installation takes literally 30 seconds:
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)

Then add our team scripts:
dr -col add https://github.com/[your-team]/dotrun-scripts.git
```

### Week 1: Results Summary

```
Week 1 dotrun results:

📊 Metrics:
- Team adoption: 8/10 (80%) ✓
- Scripts created: 12
- "How do I..." questions: Down from ~15/week to 2/week
- Time saved: ~10 min/person/day (rough estimate)

🎉 Highlights:
- John automated the entire onboarding setup (now 5 minutes instead of 2 hours)
- Sarah created scripts for our AWS workflows
- Mike added database seeding scripts

💡 Most used:
1. git/cleanup (everyone)
2. deploy (daily)
3. docker/clean (when disk fills up)

📝 Feedback:
"I didn't think I needed this until I used it" - Sarah
"Finally, I don't have to search Slack for deploy commands" - Mike

What should we add next? Drop suggestions in this thread.
```

### Week 2: Contribution Call

```
dotrun is working great! Now let's make it even better.

I want YOUR scripts in the collection.

Do you have a command you run frequently? Something you've automated?
A workflow that others might find useful?

Add it to our collection:
1. Create the script
2. Add a DOC block (dr help <script> will show it)
3. Submit a PR to github.com/[your-team]/dotrun-scripts

Need help? I'll pair with anyone who wants to add their first script.

Let's build a library of our team's best practices.
```

---

## Success Metrics Tracker

Track these metrics daily for the first week:

### Installation & Adoption

```
Team Size: [10]

Day 1: [5] installed (50%)
Day 2: [7] installed (70%)
Day 3: [8] installed (80%)
Day 7: [9] installed (90%)

Target: 80%+ ✓
```

### Script Usage

```
Week 1:
- git/cleanup: [23] runs
- docker/clean: [8] runs
- deploy: [15] runs
- env/setup: [6] runs
- db/reset: [12] runs

Total script executions: [64]
Average per person: [6.4]
```

### Slack Question Reduction

```
"How do I..." questions:

2 weeks before: [~15 per week]
Week 1: [2 questions]

Reduction: 87% ✓
```

### Contribution Metrics

```
Week 1:
- New scripts added: [3]
- Contributors: [2] (not counting you)
- PRs submitted: [3]

Target: 2+ contributors ✓
```

### Qualitative Feedback

```
Testimonials collected:

1. "[Your teammate's quote]"
2. "[Another quote]"
3. "[Another quote]"

Target: 3+ positive testimonials ✓
```

---

## Common Objections & Responses

### "I don't have time to set this up"

**Response:**
"It's 30 seconds to install, and I'll help you right now. Let's screen share for 2 minutes."

**Action:**
Immediately offer to help. Screen share, walk them through it.

### "I'll try it later"

**Response:**
"What if we do it together in 2 minutes right now? Which script would help you most today - git cleanup or deploy?"

**Action:**
Give them a specific, immediate use case. Show them the value TODAY.

### "My workflow is different"

**Response:**
"Perfect! What commands do YOU use daily? Let's add them to the collection so everyone can benefit from your workflow."

**Action:**
Turn resistance into contribution. Make them feel valuable.

### "What if it breaks something?"

**Response:**
"Everything is in Git, and you can uninstall with one command. Plus all destructive scripts ask for confirmation. I've been using it for [X weeks] with zero issues."

**Action:**
Show the uninstall command. Run a destructive script and show the confirmation prompt.

### "This seems overly complex"

**Response:**
"Fair point. For you specifically, which of these would actually help:

- Not searching Slack for deploy commands?
- Cleaning up old Git branches instantly?
- Resetting your database in 10 seconds?

If none of these save you time, dotrun might not be for you. But I'm betting at least one of these would help."

**Action:**
Be okay with them not using it. But make them identify specific value first.

### "Can't we just use aliases?"

**Response:**
"Absolutely! Aliases are great for simple commands. Let me show you where dotrun is different..."

**[Demo script with parameters and help]**

"Can your alias do this? If yes, stick with aliases! If not, dotrun might help."

**Action:**
Don't attack their current workflow. Show capabilities beyond aliases.

---

## Presentation Tips

### Before You Start

1. **Close unnecessary windows** - Just terminal + Slack
2. **Increase font size** - Everyone should read it easily
3. **Test audio/video** - If remote presentation
4. **Have installation command ready** - In clipboard
5. **Silence notifications** - No interruptions

### During Presentation

1. **Speak slowly** - You know this well, they don't
2. **Pause for questions** - After each section
3. **Show, don't tell** - Run actual commands, don't just talk about them
4. **Use real examples** - Your team's actual Slack questions
5. **Be enthusiastic but not pushy** - You're excited, not selling

### After Presentation

1. **Stay available** - "I'm free all afternoon to help"
2. **Celebrate early wins** - Post them in Slack immediately
3. **Respond to all feedback** - Positive and negative
4. **Follow up with non-adopters** - "Can I help you get set up?"
5. **Track metrics** - Know your numbers for Phase 2

---

## Next Steps After Week 1

### If 80%+ Adoption (Success!)

1. ✅ Collect testimonials (3-5 quotes)
2. ✅ Document time saved (be specific)
3. ✅ Capture metrics (adoption, scripts, questions reduced)
4. ✅ Prepare Phase 2 materials (company-wide)
5. ✅ Share success with leadership

### If 50-79% Adoption (Moderate Success)

1. 🔄 Interview non-adopters: "What would make this useful for you?"
2. 🔄 Add 3-5 more scripts based on feedback
3. 🔄 Do a second presentation with improvements
4. 🔄 One-on-one sessions with holdouts
5. 🔄 Iterate for another week before Phase 2

### If <50% Adoption (Need to Pivot)

1. ❓ Gather honest feedback: "What went wrong?"
2. ❓ Identify the core problem: Wrong scripts? Too complex? Not valuable?
3. ❓ Consider alternatives: Maybe dotrun isn't the right solution
4. ❓ Pivot or pause: Fix fundamental issues before continuing

---

## Emergency Troubleshooting

### "The install script failed"

**Check:**

- Bash version: `bash --version` (need 4.0+)
- Permissions: Can they write to `~/.local/bin`?
- Internet connection: Can they reach GitHub?

**Fix:**
Manual installation steps in dotrun README

### "Scripts aren't running"

**Check:**

- Is dotrun in PATH? `which dr`
- Did they reload shell? `source ~/.bashrc` or restart terminal
- File permissions? `ls -la ~/.local/bin/dr`

**Fix:**

```bash
# Reload shell
exec $SHELL

# Or manually add to PATH
export PATH="$HOME/.local/bin:$PATH"
```

### "Tab completion doesn't work"

**Check:**

- Which shell? `echo $SHELL`
- Did shell config reload?
- Is completion script loaded?

**Fix:**
Restart terminal or run dotrun setup again

---

## Appendix: Demo Script (Terminal Commands)

Copy these commands for your live demo:

```bash
# Part 1: Show current state
echo "Current directory:"
pwd

# Part 2: Installation
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)

# Reload shell
exec $SHELL

# Part 3: Create first script
dr set deploy

# (In editor, paste the deploy script from above)

# Part 4: Run from any directory
cd ~/Documents
dr deploy staging

# Part 5: Discovery
dr <TAB>
dr -L
dr help deploy

# Part 6: Team collection
dr -col add https://github.com/[your-team]/dotrun-scripts.git
dr -L

# Part 7: Run a team script
dr git/cleanup
```

---

## Final Checklist

Before launch day:

- [ ] All 5 starter scripts created and tested
- [ ] Team collection repo created and accessible
- [ ] Slack announcement message copied
- [ ] Presentation script reviewed
- [ ] Demo flow tested at least once
- [ ] Real Slack examples identified
- [ ] Terminal font sized appropriately
- [ ] Installation command in clipboard
- [ ] Presentation time scheduled
- [ ] Metrics tracker ready
- [ ] Follow-up messages prepared
- [ ] Excited and ready to launch! 🚀

---

**You're ready to launch Phase 1!**

Remember: The goal is momentum, not perfection. Get 80% adoption, collect testimonials, and move to Phase 2.

Good luck! 🎉
