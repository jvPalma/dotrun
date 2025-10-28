# Phase 1: Quick Start Guide

**Read this first. Execute today.**

---

## What You Have Now

✅ **PUBLISH_STRATEGY.md** - Complete 5-phase strategy
✅ **PHASE1_LAUNCH_KIT.md** - Everything for team launch
✅ **This guide** - Your action checklist

---

## Do This Today (1 Hour Total)

### Step 1: Create Team Collection (15 min)

```bash
# 1. Create new repo on GitHub/GitLab
# Name it: dotrun-scripts (or whatever you prefer)

# 2. Clone it locally
git clone https://github.com/[your-org]/dotrun-scripts.git
cd dotrun-scripts

# 3. Create structure
mkdir -p scripts/{git,docker,env,db} helpers
touch README.md CONTRIBUTING.md .gitignore .dotrun-collection

# 4. Copy content from PHASE1_LAUNCH_KIT.md:
# - All 5 starter scripts → scripts/
# - README.md content
# - CONTRIBUTING.md content
# - .gitignore content
# - .dotrun-collection content

# 5. Make scripts executable
chmod +x scripts/**/*
chmod +x scripts/deploy

# 6. Commit and push
git add .
git commit -m "Initial dotrun scripts collection"
git push
```

### Step 2: Test Everything (10 min)

```bash
# Install dotrun (if not already)
bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)

# Add your collection
dr -col add https://github.com/[your-org]/dotrun-scripts.git

# Test each script
dr -L               # Should show all 5 scripts
dr help git/cleanup # Should show documentation
dr git/cleanup      # Actually run it (safe)
```

### Step 3: Find Slack Examples (5 min)

Search your team Slack for:

- "deploy command"
- "how do I"
- "can someone share"

Copy 2-3 real examples with dates. You'll show these in the presentation.

### Step 4: Schedule Presentation (5 min)

Pick one:

- **Option A:** During tomorrow's standup (5 min demo)
- **Option B:** Dedicated 15-min team meeting this week
- **Option C:** Async: Record demo, post to Slack

Send calendar invite or Slack message.

### Step 5: Send Announcement (5 min)

Copy this into Slack **right now**:

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

I'll do a quick 5-minute demo [TOMORROW/DAY] at [TIME]. If you can't
make it, I'll share a recording and help anyone one-on-one after.

I think this could cut down our "how do I..." questions by 90%.

Want to see it in action? [MEETING LINK or "Join standup"]
```

### Step 6: Prepare Demo (20 min)

```bash
# Practice this flow 2-3 times:

# 1. Open Slack, show real question examples
# 2. Open terminal, run installation
# 3. Create deploy script: dr set deploy
# 4. Run it: dr deploy staging
# 5. Show discovery: dr <TAB>, dr -L, dr help deploy
# 6. Show team collection: dr -col add [your-repo]
# 7. Ask for volunteers to install

# Repeat until smooth (under 7 minutes)
```

---

## Presentation Day

### Morning: Final Check

- [ ] Terminal font sized appropriately (120 columns)
- [ ] Installation command in clipboard
- [ ] Slack examples open in browser tab
- [ ] Team collection repo URL ready
- [ ] All notifications silenced

### During Demo (5-7 minutes)

Follow the script in `PHASE1_LAUNCH_KIT.md`:

1. Show pain (Slack) - 60s
2. Show install - 30s
3. Create script - 60s
4. Show discovery - 60s
5. Show sharing - 60s
6. Call to action - 30s

### After Demo

Post immediately:

```
Thanks everyone who joined!

To try dotrun:

1. Install:
   bash <(curl -fsSL https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh)

2. Add our team scripts:
   dr -col add https://github.com/[your-org]/dotrun-scripts.git

3. Try it:
   dr git/cleanup
   dr -L

I'm available all day to help anyone get set up! 🚀
```

---

## Week 1: Track Progress

### Daily

- Help anyone who asks
- Celebrate wins in Slack ("John just cleaned 40 branches!")
- Add 1 new script based on requests

### End of Week

Count:

- How many installed? (Target: 80%+)
- How many scripts? (Target: 10+)
- Slack questions? (Should be way down)

**If 80%+ → Prepare Phase 2**
**If 50-79% → Iterate another week**
**If <50% → Gather feedback, pivot**

---

## Quick Reference

### All Documents

1. **PUBLISH_STRATEGY.md** - Complete strategy for all 5 phases
2. **PHASE1_LAUNCH_KIT.md** - Detailed team launch materials
3. **This file** - Your action checklist

### Key Links

- Installation: `https://raw.githubusercontent.com/jvPalma/dotrun/master/install.sh`
- GitHub: `https://github.com/jvPalma/dotrun`
- Your collection: `https://github.com/[your-org]/dotrun-scripts`

### Success Metrics

✅ 80%+ team adoption
✅ 10+ scripts in collection
✅ 90%+ reduction in "how do I" questions
✅ 3+ testimonials

---

## Troubleshooting

**"I don't know what to put in the deploy script"**
→ Use your actual deploy command. Even if it's just `echo "Deploying..."` for now.

**"My team doesn't use Slack"**
→ Replace with your chat tool (Teams, Discord, email, etc.)

**"I'm not confident presenting"**
→ Do it async: Record a 5-minute video, post to team chat, offer 1-on-1 help.

**"What if nobody uses it?"**
→ That's valuable feedback! Ask why. Maybe dotrun isn't the solution, or maybe the scripts need to be different.

---

## The 80/20 Rule

**20% effort that gives 80% results:**

1. ✅ Create 3 scripts: git/cleanup, deploy, docker/clean
2. ✅ 5-minute demo showing real value
3. ✅ Help first 2-3 adopters get set up
4. ✅ Celebrate their wins publicly

That's it. Everything else is optimization.

---

## What Success Looks Like

**Day 1:**
Someone installs dotrun during your demo and runs their first script.

**Day 3:**
You see this in Slack: "I just used dr git/cleanup and it was SO fast! Thanks @you!"

**Week 1:**
Someone asks: "Can we add a script for [X]?"
← This is the moment. They're contributing, not just using.

**Week 2:**
You don't have to promote dotrun anymore. Team members recommend it to each other.

---

## Ready?

You have everything you need:

✅ Scripts (5 ready to use)
✅ Presentation (tested flow)
✅ Messages (copy-paste ready)
✅ Follow-up (templates prepared)
✅ Metrics (tracking system)

**Just do it.**

Don't wait for perfect. Launch today.

Good luck! 🚀

---

**Next:** After Week 1 success → Open `PUBLISH_STRATEGY.md` → Phase 2: Company Launch
