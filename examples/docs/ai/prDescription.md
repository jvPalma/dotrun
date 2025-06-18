# prDescription 📝

Generate an **AI-powered pull-request title and body** from the current git diff and contextual analysis.

---

## Why?

Writing meaningful PR descriptions is repetitive and time-consuming.  
`prDescription` uses intelligent analysis to summarise _what changed_ and _why_—so you can paste the result straight into GitHub.

---

## Usage

```bash
# basic
drun prDescription

# add extra context (e.g. Jira ticket, manual notes)
drun prDescription "AN-1234 fix vault creation edge cases"

# skip saving to history
drun prDescription --no-save
```

| Flag           | Description                                          |
| -------------- | ---------------------------------------------------- |
| `--no-save`    | Don’t store the generated text in the history folder |
| _(positional)_ | Additional context injected into the AI analysis     |

After generation you’ll be prompted:

```
Accept [a] / Regenerate [r] / Quit [q]?
```

- **Accept** → prints a 👍 message and (unless `--no-save`) archives the result to `~/.config/prompts/pr-history/`.
- **Regenerate** → re-runs the AI analysis on the same diff/context.
- **Quit** → exits without writing any history.

---

## Dependencies

- `llm` — the CLI wrapper for your preferred AI provider
- `glow` — _optional_ pretty Markdown renderer (falls back to plain text)

---

## Prompts

| File                                    | Purpose                       |
| --------------------------------------- | ----------------------------- |
| `~/.config/prompts/pr-title-prompt.txt` | Template for the PR **title** |
| `~/.config/prompts/pr-body-prompt.txt`  | Template for the PR **body**  |
| `~/.config/prompts/prContext.txt`       | Default fallback context      |

Place `USER_CHANGES_CONTEXT` in your templates where the user-supplied context should be substituted.

---

## History

Successful, confirmed generations are timestamped into:

```
~/.config/prompts/pr-history/<epoch>.txt
```

The helper keeps only the **six** most recent entries.

---

## See also

- [DotRun](https://github.com/jvPalma/dotrun) – script orchestration & docs template
- `drun edit prDescription` – tweak the binary
- `drun edit:docs prDescription` – tweak these docs
