# DotRun Publish Strategy

**Objective:** Launch dotrun across 5 audiences to maximize adoption, showcase capabilities, and establish it as the definitive solution for executable knowledge management in development teams.

---

## Executive Summary

**What makes dotrun unique:**

- **Only tool** combining global script execution + self-documentation + team collections + multi-shell support
- Not a dotfiles manager, not a task runner, not a snippet tool
- **New category:** "Executable knowledge management for development teams"

**Core message:** "Transform scattered tribal knowledge into a unified, discoverable, and shareable script ecosystem."

---

## Phase 1: Your Team (5-10 developers)

### Objective

Get early adopters, validate real-world usage, collect testimonials for later phases.

### Target Audience

Your immediate team members who:

- Ask the same questions repeatedly
- Share commands via Slack/chat
- Have tribal knowledge in their heads
- Want to reduce interruptions

### Key Pain Point

**"Can someone share that Docker cleanup command again?"**

Every team has this: commands that get asked for repeatedly, knowledge that lives in one person's head, workflows that exist only in Slack history.

### Message Framework

**Subject Line (Email/Slack):**

```
I built a tool to stop us from asking for the same commands over and over
```

**Opening (First 30 seconds):**

```
Hey team,

I noticed we keep asking each other for the same commands - deployment workflows,
Git cleanups, Docker commands, environment setup scripts. It's taking up time
in our chat and slowing everyone down.

I've been using this tool called dotrun that solves this problem, and I think
it could help our team.
```

**The Demo (Show, don't tell):**

```
Instead of searching Slack for:
  "Hey, what was that command to clean up old Git branches?"

You just run:
  dr git/cleanup

And it works from any directory, on any project, with built-in help.
```

**Value Proposition:**

1. **Stop being interrupted** - People find commands themselves
2. **Onboard new teammates faster** - All knowledge is discoverable
3. **Work from anywhere** - Scripts run in any directory
4. **Keep it updated** - Collections sync like Git repos

### Presentation Flow

**1. Show the Pain (2 minutes)**

- Open Slack and search for a command someone asked about
- Show how long it takes to find it
- Mention how many times this happens per week

**2. Show the Solution (3 minutes)**

```bash
# Install (30 seconds)
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)

# Create a team script (1 minute)
dr set deploy
# Add your deployment command with documentation

# Run it from anywhere (30 seconds)
cd ~/any-project
dr deploy staging

# Share with team (1 minute)
# Show how to create a collection and share
```

**3. Show Discovery (1 minute)**

```bash
dr -L                # List all scripts
dr help deploy       # Show documentation
dr <TAB>             # Tab completion
```

**4. Call to Action**

```
Let's try this for our most-asked-about commands. I'll create a team collection
with our deployment, Git, and Docker scripts. You can install dotrun and pull
from our shared collection.

If it works for us, we can share it with the whole engineering org.
```

### Success Metrics

- [ ] 80% of team installs dotrun
- [ ] 10+ scripts in shared team collection
- [ ] 50% reduction in "how do I..." questions in chat
- [ ] 2-3 team members willing to give testimonials

### Sample Scripts to Start With

1. **deploy** - Your deployment workflow
2. **git/cleanup** - Remove merged branches
3. **docker/clean** - Clean up containers and images
4. **env/setup** - Set up development environment
5. **db/reset** - Reset local database

### Follow-up (1 week later)

```
Quick update on dotrun:

We now have 12 scripts in our team collection. This week, I noticed:
- Zero questions about the deployment command
- New teammate set up their environment in 5 minutes instead of 2 hours
- Everyone is using tab completion to discover scripts

If you haven't tried it yet, I recommend starting with `dr -L` to see
what's available.
```

---

## Phase 2: Whole Company (Engineering Org)

### Objective

Scale adoption across engineering, position as productivity tool, get leadership buy-in.

### Target Audience

- Engineering managers (want team productivity)
- DevOps/Platform teams (want standardization)
- New hires (want faster onboarding)
- Engineering leadership (want ROI)

### Key Pain Point

**"New hires take 2-3 weeks to learn all our commands and workflows."**

### Message Framework

**Subject Line (Email/Announcement):**

```
[Engineering] New tool: Reduce onboarding time by 50% with executable runbooks
```

**Opening:**

```
The [Your Team] team has been piloting a tool called dotrun for the past
month to solve a common problem: scattered tribal knowledge.

Our commands live in Slack threads, wiki pages, and individual scripts.
New teammates spend weeks learning workflows that should take minutes.

Dotrun turns this scattered knowledge into a unified, discoverable system.
```

**Results from Pilot (Use real numbers):**

```
After 4 weeks with dotrun:
- Team onboarding time reduced from 2 weeks to 3 days
- 95% reduction in "how do I..." questions
- 25+ reusable scripts created and documented
- Works across macOS and Linux, bash/zsh/fish
```

**How It Works:**

```
1. Team creates scripts with built-in documentation
2. Scripts are organized in collections (like Git repos)
3. Everyone can install and run scripts from anywhere
4. Updates sync automatically with version control
```

**Live Demo (For Town Hall/Meeting):**

**Show the problem (1 minute):**

- New developer joins: "How do I deploy?"
- Check Slack, check wiki, ask someone
- Find outdated documentation
- Copy-paste from history

**Show the solution (3 minutes):**

```bash
# New hire installs dotrun
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)

# Install company collections
dr -col add https://github.com/yourcompany/engineering-scripts.git
dr -col add https://github.com/yourcompany/devops-scripts.git

# Discover available scripts
dr -L

# Run with help
dr help deploy
dr deploy production

# Everything documented, everything discoverable
```

**Show discovery (1 minute):**

```bash
dr <TAB>              # Tab completion shows all scripts
dr -L | grep docker   # Search for Docker scripts
dr help db/migrate    # Built-in documentation
```

**ROI Calculation:**

```
Conservative estimate for 50-person engineering team:

Time saved per developer:
- Searching for commands: 15 min/day × 220 days = 55 hours/year
- Onboarding new teammates: 40 hours → 20 hours (save 20 hours per new hire)
- Documenting workflows: Automatic with dotrun

For 50 developers + 10 new hires per year:
- 2,750 hours saved on command searches
- 200 hours saved on onboarding
- Total: ~2,950 hours/year = ~$295,000 at $100/hour

One-time setup cost: ~40 hours to migrate existing scripts
```

**Call to Action:**

```
We're rolling this out in phases:

Week 1-2: Platform team creates core collections
Week 3-4: Open to early adopters (opt-in)
Week 5+: Recommended for all engineering

To join early access, reply to this thread or DM me.
```

### Presentation Materials

**1. Company Wiki Page**
Create a page: "Engineering/Tools/DotRun"

- What it is and why we're using it
- Installation guide
- Available collections
- How to contribute scripts
- FAQ

**2. Slack Announcement**

```
📢 New Engineering Tool: DotRun

Stop searching Slack for commands. Start running them.

What: Unified script management for all our workflows
Why: Reduce onboarding time, increase productivity
How: Install in 30 seconds, access 50+ team scripts

Try it: [link to wiki page]
Questions: #engineering-tools
```

**3. Engineering All-Hands Slide Deck**

**Slide 1: The Problem**

```
Title: "Tribal Knowledge is Killing Our Productivity"

- New hires ask the same questions for 2-3 weeks
- Commands live in Slack threads from 6 months ago
- Everyone has their own version of "the deployment script"
- Wiki pages are outdated 2 weeks after creation
```

**Slide 2: Real Examples**

```
Title: "How many times have we seen this?"

Slack screenshots:
- "What's the command to reset my local DB?"
- "Can someone share the Docker cleanup script?"
- "How do I deploy to staging again?"
- "Where's the AWS login command?"
```

**Slide 3: The Solution**

```
Title: "DotRun: Executable Knowledge Management"

One command replaces all of this:
dr deploy staging

Features:
✅ Global access from any directory
✅ Built-in documentation
✅ Team collaboration via collections
✅ Works in bash, zsh, fish
✅ Private repo for configs
```

**Slide 4: Pilot Results**

```
Title: "[Team Name] Pilot Results (4 weeks)"

Before:
- 15-20 "how do I..." questions per week
- 2 weeks to onboard new developers
- 0 documented scripts

After:
- 1-2 "how do I..." questions per week
- 3 days to onboard new developers
- 25 documented, searchable scripts
```

**Slide 5: Live Demo**

```
Title: "See It In Action"

[Screen recording or live demo]
- Install (30 seconds)
- Install company collection (30 seconds)
- Browse scripts (dr -L)
- Run a script (dr deploy)
- Show tab completion
```

**Slide 6: Rollout Plan**

```
Title: "Phased Rollout"

Week 1-2: Platform team creates core collections
  - DevOps scripts
  - Git workflows
  - Docker/k8s commands

Week 3-4: Early adopters (opt-in)
  - Collect feedback
  - Add more scripts
  - Refine docs

Week 5+: Recommended for all engineering
  - Include in new hire onboarding
  - Add to engineering handbook
```

**Slide 7: Get Started**

```
Title: "Join the Beta"

1. Read the docs: [wiki link]
2. Install: bash <(curl ...)
3. Add company collection
4. Join #dotrun-users
5. Contribute your scripts

Questions? Ask in #engineering-tools
```

### Success Metrics

- [ ] 40%+ of engineering org installs dotrun
- [ ] 100+ scripts in company collections
- [ ] 50% reduction in onboarding time (measured)
- [ ] Included in new hire checklist
- [ ] 5+ teams actively contributing scripts

### Email Template for Engineering Managers

```
Subject: [Action] New productivity tool for your team - DotRun

Hi [Manager Name],

I wanted to share a tool that's been making a significant impact on
team productivity.

**The Problem:**
Your team likely spends hours every week answering the same "how do I..."
questions. New hires take weeks to learn all your workflows. Commands live
in Slack history and outdated wiki pages.

**The Solution:**
DotRun turns scattered commands into a unified, discoverable system. Think
"executable runbook" that works from any directory with built-in help.

**Pilot Results:**
[Team Name] has been using it for 4 weeks:
- Onboarding time: 2 weeks → 3 days
- "How do I" questions: -95%
- Documented scripts: 0 → 25

**Next Steps:**
1. Review the wiki page: [link]
2. 15-minute demo available (optional)
3. Opt-in for early access

This is rolling out company-wide starting [date]. Early adoption helps
your team shape the collections and workflow.

Best,
[Your Name]

P.S. - The ROI calculation is compelling: ~60 hours saved per developer per
year on command searches alone.
```

---

## Phase 3: LinkedIn

### Objective

Build personal brand, attract external users, generate discussions about developer productivity.

### Target Audience

- Senior developers and tech leads
- Engineering managers
- DevOps/Platform engineers
- Developer productivity enthusiasts

### Key Pain Point

**"I built a tool to solve a problem every developer has."**

### Post Strategy

**Post Type:** Personal story + value demonstration

**Post 1: The Origin Story (Week 1)**

```
I was tired of being interrupted for the same commands.

"Can you share that deploy command again?"
"What's the Git cleanup script?"
"How do I reset my local database?"

Every week, the same questions. Every time, I'd search Slack history or
copy-paste from my own notes.

So I built DotRun.

Instead of searching for commands, my team now runs them:
• dr deploy staging
• dr git/cleanup
• dr db/reset

Three months in, we've:
✅ Cut onboarding time in half (2 weeks → 3 days)
✅ Created 50+ documented, reusable scripts
✅ Reduced "how do I..." questions by 95%

The best part? It's not just for my team. It's open source.

It works across projects, shells (bash/zsh/fish), and teams. You can
share scripts like Git repos while keeping personal configs private.

If you've ever wished your team had a better way to share commands,
check it out: github.com/jvpalma/dotrun

What commands does your team wish were easier to find?

#DeveloperProductivity #OpenSource #DevTools #EngineeringCulture
```

**Why this works:**

- Starts with relatable pain
- Shows personal investment (I built it)
- Concrete results with numbers
- Open-ended question for engagement
- Relevant hashtags without spam

**Post 2: The Technical Deep Dive (Week 3)**

````
Most developer tools solve one problem:
• Dotfiles managers → Sync configs
• Task runners → Project automation
• Snippet managers → Store commands

DotRun combines all three:

Global execution + Self-documentation + Team collaboration

Here's what makes it unique:

🚀 Global Access
Run scripts from ANY directory, not just project roots.

📚 Self-Documentation
Every script includes usage examples and help text. No more
"what does this do?"

👥 Team Collaboration
Share scripts via collections (Git repos) while keeping personal
configs separate.

🐚 Shell Universal
One script, works in bash, zsh, AND fish.

Example: Instead of this...
```bash
git fetch --all && git branch -vv | \
  awk '/: gone]/{print $1}' | xargs git branch -d
````

You run this:

```bash
dr git/cleanup
```

It's the layer between aliases and automation that's been missing.

Built it because I needed it. Open sourced it because you might too.

GitHub: github.com/jvpalma/dotrun

Developers: What's your most complex command that you wish was
one word?

#DevOps #DeveloperTools #OpenSource #CommandLine #Productivity

```

**Why this works:**
- Educates on the problem space
- Shows technical depth
- Visual example (code blocks)
- Establishes expertise
- Invites specific examples

**Post 3: The ROI/Impact Post (Week 5)**

```

We calculated the ROI of better command management.

For a 50-person engineering team:

Before DotRun:
• 15 min/day searching for commands
• 2 weeks onboarding new developers
• Tribal knowledge trapped in Slack

After DotRun:
• <1 min to find any command (built-in search)
• 3 days to onboard (everything documented)
• Knowledge lives in executable, versioned collections

The math:
• 2,750 hours/year saved on command searches
• 200 hours/year saved on onboarding
• ~$295k value at $100/hour

One-time setup cost: ~40 hours

This is why developer productivity tools matter.

The real value isn't the tool itself—it's the compound effect
of small time savings across an entire team.

What productivity improvements have had the biggest impact on
your team?

Project: github.com/jvpalma/dotrun

#EngineeringLeadership #DeveloperProductivity #ROI #DevTools

```

**Why this works:**
- Speaks to managers and leaders
- Concrete, verifiable numbers
- Frames tool as business value
- Opens discussion on productivity
- Appeals to decision-makers

**Post 4: The Community/Ecosystem Post (Week 7)**

```

The best part of building in public?

Seeing how people use your tool in ways you never imagined.

Since launching DotRun, developers have shared collections for:

🚀 DevOps: Kubernetes scripts, AWS workflows, Terraform helpers
🔧 Development: Git workflows, database scripts, code generators
🧪 Testing: Test runners, coverage reports, CI helpers
📦 Docker: Container management, image cleanup, compose workflows
🔐 Security: Secrets management, vulnerability scanning

One team created a "new hire" collection with everything a
developer needs on day one.

Another uses it to standardize 50+ microservice deployments.

This is what open source is about—solving a problem, then watching
the community extend it in creative ways.

If you've built something similar or have ideas for dotrun, I'd
love to hear about it.

GitHub: github.com/jvpalma/dotrun

What collections would be most valuable for your team?

#OpenSource #DeveloperCommunity #DevTools #Productivity

```

**Why this works:**
- Shows traction and social proof
- Highlights diverse use cases
- Builds community around the tool
- Invites contribution and ideas
- Demonstrates active maintenance

### Engagement Strategy

**When people comment:**
1. **Respond within 2 hours** (shows active maintenance)
2. **Ask follow-up questions** (increases engagement)
3. **Offer to help** ("I'd be happy to help you set that up")
4. **Share examples** ("Here's how team X solved that")

**When people ask "vs [other tool]":**
```

Great question! [Other tool] is excellent for [its use case].

DotRun is different because:

- [Specific differentiator 1]
- [Specific differentiator 2]

They can actually work together—many teams use [other tool] for
[X] and dotrun for [Y].

Want me to share an example?

````

### Success Metrics
- [ ] 1,000+ post views per post
- [ ] 50+ engaged comments
- [ ] 100+ GitHub stars from LinkedIn traffic
- [ ] 5+ inbound messages about adoption
- [ ] Featured in 1-2 LinkedIn newsletters/groups

---

## Phase 4: Reddit

### Objective
Reach technical community, get feedback, drive GitHub stars, establish credibility.

### Target Subreddits

**Priority 1 (High engagement, relevant):**
- r/commandline (240k members) - Perfect fit
- r/devops (250k members) - DevOps audience
- r/programming (6M members) - Broad reach
- r/selfhosted (400k members) - Privacy/control angle

**Priority 2 (Smaller but targeted):**
- r/sysadmin (500k members) - IT/automation
- r/linux (1.2M members) - Linux users
- r/bash (40k members) - Shell scripting
- r/productivity (2M members) - Productivity tools

### Key Pain Point
**"I built a better way to manage scripts across projects and teams."**

### Reddit-Specific Guidelines

**DO:**
- Be humble and authentic
- Share technical details
- Invite criticism and feedback
- Acknowledge limitations
- Respond to every comment
- Cross-post to related subs after 24 hours

**DON'T:**
- Sound like marketing
- Spam multiple subs at once
- Ignore negative feedback
- Delete critical comments
- Use link shorteners

### Post Template for r/commandline

**Title Options (Choose one):**
1. "I built a tool to stop hunting for commands across Slack and docs"
2. "Show your scripts: I made a unified script runner for bash/zsh/fish"
3. "Tired of scattered shell scripts? Here's my solution"

**Post Body:**

```markdown
### The Problem

I was tired of:
- Searching Slack for commands someone shared last month
- Copy-pasting from my `.bash_history`
- Maintaining separate script directories for each project
- Explaining the same workflows to new team members

Every developer I know has a `~/bin` or `~/scripts` directory that's
either a mess or completely forgotten.

### What I Built

DotRun is a unified script management system. Think of it as:
- Alias manager (but with docs and parameters)
- Script runner (but global, not project-local)
- Dotfiles manager (but for executable scripts)

Instead of this:
```bash
cd ~/my-scripts
./deploy.sh staging --force
````

You run this from anywhere:

```bash
dr deploy staging --force
```

### Key Features

1. **Global execution** - Run from any directory
2. **Self-documenting** - Every script has built-in help
3. **Team sharing** - Collections sync like Git repos
4. **Shell universal** - Works in bash, zsh, fish
5. **Tab completion** - Intelligent, categorized completion

### Example

Create a script:

```bash
dr set deploy
# Opens editor with documentation template
```

Run it from anywhere:

```bash
cd ~/any-project
dr deploy staging
```

Share with team:

```bash
dr -col add https://github.com/company/scripts.git
```

### Why I Built It

I wanted something between:

- Simple aliases (too limited)
- Full automation (too complex)

DotRun is the middle layer: documented, discoverable, shareable
commands that work everywhere.

### It's Open Source

GitHub: github.com/jvpalma/dotrun

I'd love feedback, especially:

- What am I missing?
- How does this compare to your workflow?
- What features would make this useful for you?

### Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)
```

---

**Edit:** Thanks for all the feedback! Common questions:

**Q: How is this different from aliases?**
A: Aliases are great for simple commands, but dotrun handles:

- Parameters and arguments
- Multi-line scripts
- Built-in documentation
- Team sharing via collections
- Cross-shell support (one script, all shells)

**Q: Why not just use Makefiles?**
A: Makefiles are project-specific. DotRun scripts work globally—
you can run `dr deploy` from any directory.

**Q: How does it compare to `just` or `task`?**
A: Those are excellent project-local runners. DotRun is for
global, reusable scripts that work across all projects.

```

### Response Strategy

**For positive feedback:**
```

Thanks! Let me know if you try it—I'm actively adding features
based on feedback.

What workflows would you want to automate with this?

```

**For critical feedback:**
```

Great point—that's definitely a limitation right now.

The reason I didn't implement [feature] is [honest reason].

Would you be interested in [alternative approach] or is that
missing the point?

[If good idea:] This is worth adding. I'll open an issue to
track it: [link]

```

**For "just use X" comments:**
```

[Tool X] is excellent! I use it for [specific use case].

The gap I found was [specific problem]. Do you have a way
to solve [problem] with [Tool X]?

Genuinely curious—I might be overcomplicating this.

```

**For "why not just..." comments:**
```

I tried that! The problem I ran into was [specific issue].

How do you handle [edge case]? Maybe I'm missing something.

````

### Post Template for r/devops

**Title:**
"Made a tool to share DevOps scripts across teams (no more Slack archaeology)"

**Body:**
```markdown
### DevOps Problem

How many times have you seen this in Slack?

> "Can someone share the command to restart staging?"
> "What's the kubectl script for checking pod health?"
> "How do I deploy again?"

Every team has tribal knowledge trapped in:
- Slack threads from 6 months ago
- Someone's personal notes
- Undocumented scripts in a repo somewhere

### My Solution

I built DotRun to make DevOps workflows discoverable and shareable.

**Before:**
```bash
# Search Slack
# Copy-paste 6-line kubectl command
# Hope it still works
# Save to my notes
# Forget I saved it
````

**After:**

```bash
dr k8s/pod-health staging
```

### How It Works

1. **Create once, use everywhere:**

```bash
dr set k8s/deploy
# Add your kubectl/helm workflow
```

2. **Share with team:**

```bash
# Team creates a collection
dr -col add github.com/yourteam/devops-scripts
```

3. **Everyone runs it:**

```bash
dr k8s/deploy production
dr help k8s/deploy # Built-in docs
```

### Features for DevOps

- **Self-documenting** - Every script includes usage and examples
- **Version controlled** - Collections are Git repos
- **Environment-aware** - Scripts know project context
- **Safe sharing** - Team scripts vs personal scripts separated
- **Multi-shell** - Works in bash, zsh, fish

### Real-World Example

Our team manages 50+ microservices. Before DotRun:

- 10+ Slack questions per day about deployments
- New team members took 2 weeks to learn workflows
- Scripts were scattered across repos

After DotRun:

- All deployment workflows in one discoverable place
- New member productive day 1 (run `dr -L` to see all scripts)
- 95% reduction in "how do I..." questions

### Open Source

GitHub: github.com/jvpalma/dotrun

Installation:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)
```

---

**Looking for feedback:**

- What DevOps workflows would you want to manage this way?
- What's missing for this to be useful for you?
- How do you currently share scripts across your team?

```

### Timing Strategy

**Day 1:** Post to r/commandline
**Day 2:** Respond to all comments
**Day 3:** Cross-post to r/bash (with "x-post from r/commandline")
**Day 5:** Post to r/devops (DevOps-specific angle)
**Day 7:** Post to r/programming (if r/commandline went well)
**Day 10:** Post to r/selfhosted (privacy/control angle)

### Success Metrics
- [ ] 100+ upvotes on primary post
- [ ] 50+ engaged comments
- [ ] 500+ GitHub stars from Reddit traffic
- [ ] Featured in at least one "weekly roundup"
- [ ] 3-5 substantial feature requests
- [ ] 1-2 pull requests from community

---

## Phase 5: Other Channels

### Hacker News

**Timing:** After Reddit success (need social proof)

**Title:**
"DotRun – Unified script management for development teams"

**Submission URL:**
github.com/jvpalma/dotrun

**Comment (Add immediately after posting):**
```

Author here. I built DotRun to solve a problem every dev team has:
scattered tribal knowledge.

Commands live in Slack history, wiki pages, and personal scripts.
New teammates spend weeks learning workflows that should take minutes.

DotRun turns scattered scripts into a unified system:

- Run from any directory (dr deploy staging)
- Built-in documentation (dr help deploy)
- Team sharing via collections (like Git repos)
- Works in bash, zsh, fish

It's the layer between aliases and full automation.

Our team cut onboarding time in half and eliminated 95% of
"how do I..." questions.

Happy to answer questions about design decisions, implementation,
or use cases.

```

**Best practices for HN:**
- Post between 8-10 AM EST on Tuesday-Thursday
- Respond to EVERY comment within 1 hour
- Be technical and honest about trade-offs
- Acknowledge limitations
- Share implementation details
- Don't be defensive

**Response templates:**

For "Why not X?"
```

Great question. I looked at X, and it's excellent for [use case].

The gap I found was [specific problem]. X solves [A and B] but
doesn't address [C].

Could you solve [C] with X? I might be missing something.

```

For technical questions:
```

Good catch. The implementation is [detailed explanation].

The trade-off is [pro vs con]. I chose [approach] because
[reasoning].

Code is here: [link to relevant file]

```

### dev.to

**Article Series (4 posts over 4 weeks):**

**Post 1: "Stop Searching Slack for Commands: A Better Way"**
- The problem (relatable story)
- Current solutions and their limitations
- Introducing DotRun
- Quick demo
- Call to action: Try it

**Post 2: "How We Cut Developer Onboarding Time in Half"**
- The onboarding problem
- What didn't work (wiki, docs, Slack)
- DotRun implementation
- Results and metrics
- How to replicate

**Post 3: "Building a Script Management System: Technical Deep Dive"**
- Architecture decisions
- Why bash (portability)
- Collection system design
- Tab completion implementation
- Lessons learned

**Post 4: "Team Workflows: Real-World DotRun Examples"**
- DevOps workflows
- Git automation
- Docker/Kubernetes scripts
- Database management
- Custom tooling

### Product Hunt

**Launch Strategy:**

**When:** After Reddit/HN success (need momentum)

**Tagline:**
"Stop hunting for commands. Start running them."

**First Comment:**
```

Hi Product Hunt! 👋

I'm [Name], and I built DotRun to solve a problem every developer has.

🔍 The Problem:
We waste hours searching for commands in Slack, copy-pasting from
wiki pages, and asking teammates "how do I...?" for the 100th time.

✨ The Solution:
DotRun turns scattered scripts into a unified, discoverable system.

Instead of searching Slack for:
"What's that Docker cleanup command?"

You run:
dr docker/clean

📚 Key Features:

- Global execution (run from any directory)
- Self-documenting (built-in help)
- Team collaboration (share via Git)
- Shell universal (bash/zsh/fish)
- Tab completion (smart discovery)

🎯 Who It's For:

- Development teams tired of tribal knowledge
- DevOps teams managing complex workflows
- Anyone with a messy ~/scripts directory

💡 Why I Built It:
I was tired of being interrupted for the same commands. My team
was too. So I built the layer between aliases and automation
that was missing.

Results from our team:
✅ Onboarding time: 2 weeks → 3 days
✅ "How do I" questions: -95%
✅ Documented scripts: 0 → 50+

🚀 Try It:
Installation takes 30 seconds:
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)

Questions? AMA in the comments!

```

**Hunter:** Find someone with PH following to hunt it

**Media:**
- Screenshot of tab completion
- GIF of installation → first script → execution
- Video demo (60 seconds)

**Categories:**
- Developer Tools
- Productivity
- Open Source

### Twitter/X

**Strategy:** Thread-based storytelling

**Thread 1: The Origin Story**
```

I was tired of being interrupted for the same commands.

"Can you share that deploy script?"
"What's the DB reset command?"
"How do I clean up Docker?"

Every. Single. Day.

So I built something better. 🧵

## 1/7

The problem: Knowledge lives in Slack threads from 6 months ago.

You search. You scroll. You ask. You wait.

Meanwhile, 10 other people need the same command.

There had to be a better way.

## 2/7

I tried everything:
• Aliases (too limited)
• Makefiles (project-specific)
• Wiki pages (outdated in weeks)
• README lists (not executable)

Nothing solved the core problem: scattered, undiscoverable knowledge.

## 3/7

So I built DotRun.

Instead of searching Slack:
"What's the deploy command?"

You run:
dr deploy staging

From any directory. With built-in help. Documented.

## 4/7

Three months in, the results speak for themselves:

• Onboarding: 2 weeks → 3 days
• "How do I" questions: -95%
• Documented scripts: 50+

The team is more productive. New hires are faster.
I'm interrupted less.

## 5/7

The best part? It's not just for my team.

You can share scripts like Git repos. Keep personal
configs private. Works in bash, zsh, and fish.

It's open source: github.com/jvpalma/dotrun

## 6/7

If you've ever wished your team had a better way to
share commands, check it out.

Install takes 30 seconds:
bash <(curl -fsSL https://...)

What commands does your team wish were easier to find?

7/7

```

**Posting schedule:**
- Monday: Problem/pain point
- Wednesday: Feature highlight
- Friday: User story/testimonial

### YouTube (Optional)

**Video 1: "I Built a Tool to Stop Searching Slack for Commands"**
- 5-7 minutes
- Story + demo + results
- Target: Non-coders who understand the pain

**Video 2: "DotRun Tutorial: From Zero to Productive in 10 Minutes"**
- 10-12 minutes
- Installation → first script → team sharing
- Target: Developers who want to try it

**Video 3: "How We Cut Developer Onboarding Time in Half"**
- 8-10 minutes
- Business case + ROI + implementation
- Target: Engineering managers

---

## Cross-Channel Success Metrics

### Awareness
- [ ] 5,000+ unique visitors to GitHub
- [ ] 1,000+ GitHub stars
- [ ] 500+ installations (estimated)
- [ ] Featured in 3+ newsletters/roundups

### Engagement
- [ ] 100+ GitHub issues/discussions
- [ ] 50+ comments across platforms
- [ ] 10+ blog posts/mentions
- [ ] 5+ video reviews/tutorials

### Adoption
- [ ] 20+ public collections created
- [ ] 10+ companies adopting internally
- [ ] 5+ pull requests from community
- [ ] 3+ forks with substantial changes

### Community
- [ ] 100+ Slack/Discord members
- [ ] 20+ active contributors
- [ ] 10+ testimonials/case studies
- [ ] 1+ conference talk accepted

---

## Content Calendar

### Month 1: Internal Launch
- **Week 1:** Team presentation and pilot
- **Week 2:** Team adoption and script creation
- **Week 3:** Team feedback and iteration
- **Week 4:** Prepare company rollout materials

### Month 2: Company Rollout
- **Week 1:** Engineering leadership presentation
- **Week 2:** All-hands announcement and wiki page
- **Week 3:** Early adopter program
- **Week 4:** Collect metrics and testimonials

### Month 3: External Launch (LinkedIn + Reddit)
- **Week 1:** LinkedIn post 1 (origin story)
- **Week 2:** Reddit r/commandline
- **Week 3:** LinkedIn post 2 (technical deep dive)
- **Week 4:** Reddit r/devops

### Month 4: Amplification
- **Week 1:** Hacker News
- **Week 2:** dev.to series begins
- **Week 3:** Product Hunt launch
- **Week 4:** YouTube video 1

### Month 5+: Sustained Engagement
- Weekly: LinkedIn updates
- Bi-weekly: dev.to articles
- Monthly: Community roundup
- Ongoing: Respond to all comments/issues

---

## Key Messages by Audience

### Developers (Team/Reddit/HN)
**Pain:** "I'm tired of searching for commands"
**Solution:** "Run any script from anywhere"
**Proof:** "30-second demo"

### Managers (Company/LinkedIn)
**Pain:** "Onboarding takes too long"
**Solution:** "Reduce tribal knowledge, increase productivity"
**Proof:** "ROI calculation"

### DevOps (Reddit/Twitter)
**Pain:** "Scripts are scattered across repos"
**Solution:** "Unified workflow management"
**Proof:** "Real-world examples"

### Open Source Community (HN/GitHub)
**Pain:** "No good solution exists"
**Solution:** "Built the missing layer"
**Proof:** "Technical deep dive"

---

## Response Templates

### "How is this different from X?"

```

Great question! [X] is excellent, and I use it for [specific use case].

The key differences:

1. [Specific differentiator]
2. [Specific differentiator]
3. [Specific differentiator]

They actually complement each other—you can use [X] for [A]
and DotRun for [B].

What's your current workflow? I'm curious if DotRun would
actually help or if [X] already solves this for you.

```

### "Why not just use aliases/Makefiles/scripts?"

```

I tried that! Here's what I ran into:

Aliases:

- Can't handle parameters well
- No documentation
- Shell-specific

Makefiles:

- Project-local (need to cd first)
- Tab completion limited
- Syntax is... make syntax

Scripts in ~/bin:

- No organization
- No discovery mechanism
- Hard to share with team

DotRun tries to solve all of these. Does that make sense,
or am I overcomplicating something simple?

```

### "This seems overly complex"

```

Fair criticism! I might be solving a problem you don't have.

For context: My team has 50+ common workflows. Managing them
as individual scripts became a mess.

If you have <10 commands you run regularly, aliases or a
~/scripts directory might be simpler.

DotRun makes sense when:

- You have many scripts
- You need to share with a team
- You want built-in documentation
- You work across many projects

What's your current setup? I'm genuinely curious if this
is overkill for most people.

```

### "I'd use this if it had [feature]"

```

Interesting! I hadn't considered [feature].

Can you tell me more about your workflow? I want to understand:

- How would you use [feature]?
- What problem does it solve?
- Is there a workaround, or is it a blocker?

If it makes sense, I'll open an issue to track it:
[I'll link after creating]

Also, PRs welcome if you want to take a crack at it! 😊

```

---

## FAQ for All Channels

### "How is this different from dotfiles managers like chezmoi?"

```

Dotfiles managers sync config files across machines.
DotRun manages executable scripts and workflows.

They solve different problems:

- Chezmoi: Keep your .vimrc and .zshrc synced
- DotRun: Run deployment/git/docker workflows from anywhere

You'd typically use both—chezmoi for configs, dotrun for scripts.

```

### "Why bash? Why not Python/Go/Rust?"

```

Bash makes it:

1. Zero-dependency (works everywhere)
2. Shell-agnostic (works in bash/zsh/fish)
3. Easy to contribute (no compilation)

The scripts themselves can be in any language (Python, Go, etc.).
DotRun is just the runner/organizer.

Trade-off: Bash is harder to maintain at scale. If this grows
significantly, I might rewrite the core in Go.

```

### "How do you handle secrets/credentials?"

```

Great question. DotRun doesn't manage secrets directly.

Recommended approach:

1. Store secrets in environment variables
2. Use a secrets manager (1Password, vault, etc.)
3. Scripts read from env vars, not hardcoded

Example:

```bash
#!/bin/bash
# In script: dr deploy
if [ -z "$API_KEY" ]; then
  echo "Error: API_KEY not set"
  exit 1
fi
```

This keeps secrets out of scripts and version control.

```

### "Can I use this for work/commercial projects?"

```

Yes! DotRun is MIT licensed.

You can:
✅ Use it at work
✅ Create private collections
✅ Modify it for your needs
✅ Distribute it internally

You don't need to:
❌ Open source your scripts
❌ Contribute back (but appreciated!)
❌ Ask permission

```

### "How do I contribute?"

```

Contributions are welcome! Here's how:

1. Check existing issues: github.com/jvpalma/dotrun/issues
2. Open a discussion for big features
3. Submit PRs for bugs/small features
4. Share your collections (if public)

Areas that need help:

- Documentation improvements
- Shell completion enhancements
- Windows/WSL testing
- Example collections

```

---

## Pitfalls to Avoid

### ❌ DON'T

1. **Spam multiple channels at once**
   - Looks desperate, reduces engagement
   - Post to one, wait 48 hours, then next

2. **Ignore negative feedback**
   - Every critical comment is a learning opportunity
   - Respond thoughtfully to all feedback

3. **Oversell or hype**
   - Be honest about limitations
   - Reddit/HN hates marketing speak

4. **Compare negatively to other tools**
   - "X is bad, use DotRun instead" ← Never do this
   - "X is great for Y, DotRun is for Z" ← Do this

5. **Ghost after posting**
   - Respond within 2 hours to every comment
   - Engagement drives visibility

### ✅ DO

1. **Be authentic and humble**
   - "I built this to solve my problem"
   - "It might not be for everyone"

2. **Invite criticism**
   - "What am I missing?"
   - "How would you solve this?"

3. **Show, don't tell**
   - GIFs, code examples, real numbers
   - Not: "It's fast!" | Yes: "30-second install"

4. **Acknowledge alternatives**
   - Shows you did research
   - Builds credibility

5. **Follow up with value**
   - "Based on feedback, I added X"
   - "Here's a tutorial for Y"

---

## Tools and Resources

### Analytics
- **GitHub Insights:** Track stars, forks, clones
- **Google Analytics:** Website traffic (if you build one)
- **Bit.ly:** Track link clicks from different sources
- **Social media analytics:** LinkedIn, Twitter built-in

### Content Creation
- **Asciinema:** Record terminal sessions
- **Carbon:** Beautiful code screenshots
- **Excalidraw:** Architecture diagrams
- **OBS:** Screen recording for videos
- **Canva:** Social media graphics

### Community Management
- **GitHub Discussions:** Community forum
- **Discord/Slack:** Real-time chat
- **Mailchimp:** Newsletter (if it grows)

### Monitoring
- **Google Alerts:** "dotrun" mentions
- **Social media search:** Twitter, Reddit
- **GitHub watch:** Forks, issues, PRs

---

## Measuring Success

### Week 1 (Team)
- 5+ team members using dotrun
- 10+ scripts created
- 3+ testimonials

### Month 1 (Company)
- 20+ engineers using dotrun
- 50+ scripts in collections
- Included in onboarding docs

### Month 2 (LinkedIn)
- 1,000+ post views
- 50+ engagements
- 100+ GitHub stars

### Month 3 (Reddit)
- 100+ upvotes
- 50+ comments
- 300+ GitHub stars

### Month 4 (HN/PH)
- Front page HN (even briefly)
- Top 5 on Product Hunt
- 1,000+ GitHub stars

### Month 6 (Overall)
- 2,000+ GitHub stars
- 50+ public collections
- 10+ companies using internally
- Featured in 1+ newsletter
- Community-driven development

---

## Final Checklist

### Before Launch
- [ ] README is clear and compelling
- [ ] Installation works on Linux/macOS/WSL
- [ ] Examples are up to date
- [ ] Documentation is complete
- [ ] GitHub issues are organized
- [ ] Contributing guide exists
- [ ] License is clear (MIT)
- [ ] CHANGELOG is up to date

### For Each Channel
- [ ] Message tailored to audience
- [ ] Call to action is clear
- [ ] Examples are relevant
- [ ] Timing is optimal
- [ ] Response templates ready
- [ ] Analytics tracking set up

### After Posting
- [ ] Respond to every comment
- [ ] Track metrics
- [ ] Iterate based on feedback
- [ ] Thank contributors
- [ ] Share wins with team

---

## Conclusion

This publish strategy is designed to:

1. **Start small** (team) and **build momentum**
2. **Validate value** before scaling
3. **Tailor messaging** to each audience
4. **Build community** through authentic engagement
5. **Drive adoption** through education and proof

The key to success is **authenticity**, **responsiveness**, and **continuous value delivery**.

Don't try to execute all channels at once. Follow the phased approach, learn from each wave, and iterate.

**Remember:** The goal isn't just downloads—it's building a community around executable knowledge management that makes developers' lives better.

Good luck! 🚀

---

**Questions or need help with a specific phase?**
Open an issue or reach out—I'm happy to help refine any section.
```
