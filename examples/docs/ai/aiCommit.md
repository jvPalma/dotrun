# aiCommit 🚀

AI-generated **conventional commit messages** with a single command.

---

## Why?

Writing clear commit titles every few minutes is tedious.  
`aiCommit` feeds your staged diff into an AI model and suggests a succinct message.

---

## Usage

```bash
# stage everything, commit & push
drun aiCommit

# if you already staged files manually
drun aiCommit --no-add

# commit but do not push
drun aiCommit --no-push
```

During generation you’ll be asked:

```bash
Accept [a] / Regenerate [r] / Quit [q]?
```

- **Accept / a / ↵** – creates the commit (and pushes unless `--no-push`)
  _The message is archived under `~/.config/prompts/commit-history/` (latest 10 kept)._
- **Regenerate / r** – tries again with a fresh AI analysis.
- **Quit / q** – exits, nothing staged is changed.

---

## Options

| Flag        | Effect                            |
| ----------- | --------------------------------- |
| `--no-add`  | Do **not** run `git add -A` first |
| `--no-push` | Skip `git push` after committing  |

---

## Prompts

- `~/.config/prompts/commit-system-prompt.txt` – system prompt injected into the AI analysis.

Customise it to steer tone or enforce a commit-lint style.

---

## Git alias (optional)

Add to **\~/.gitconfig** to use `git ai` everywhere:

```ini
[alias]
    ai = "!drun aiCommit"
```

Now:

```bash
git ai               # shorthand for aiCommit
```

---

## Dependencies

- **llm** – CLI wrapper for your preferred AI backend
- **DotRun** – script orchestration (`drun`)
