# WORKLOG.md format

WORKLOG.md sits at the repo root on the feature branch. Newest entry first, directly under the header block. One entry per session. Keep entries short: a future session reads the latest one to know where things stand, and Yasam reads them on GitHub.

## Header block (top of file, keep updated)

```markdown
# Worklog

Active branch: `feat/receipts`
Newest first. One entry per session.
```

Change `Active branch` whenever work moves to a new branch.

## Entry template

```markdown
## YYYY-MM-DD · `branch-name` · short session title

**Done**
- What changed, in terms of behavior, with module or file names. Include test counts if tests were added.

**Decisions**
- Choices made and why, especially ones Yasam made or confirmed. Rejected alternatives if they are likely to come up again.

**Comments**
- Yasam's feedback, preferences and remarks from the session, in his words where possible.
- Anything surprising found in the codebase or environment.

**Open / Next**
- Unfinished work, known bugs, the agreed next step.
```

Rules:
- Omit a section if there is nothing for it, except **Done** and **Open / Next**.
- Never write tokens, passwords, or personal data.
- Record decisions as Yasam's only if he made or confirmed them. Claude's suggestions he did not confirm go under Open / Next as options.
