# START HERE

Read this file first, then follow it. Written for an AI assistant picking up this repo,
but a human joining the project can read it the same way.

## What this is

A fork of [papra-hq/papra](https://github.com/papra-hq/papra) (a document archiving
platform) being extended into a **receipt capture and management app**: photograph or scan
a receipt on a phone, and have AI detect it is a receipt and pull out the fields.

Owner: Yasam, solo developer. He prefers **terse, direct answers**. No long preambles, no
restating the question, no summaries of what you are about to do. Do the thing, then say
briefly what happened. **No em dashes** anywhere, in code, docs, commits or replies.

## Read these, in this order

1. **`HISTORY.md`** (10 min) - the background. What upstream already provided, what has been
   built, why it is designed that way, what went wrong before, and what is still unproven.
   Read this fully. Most wrong turns on this project came from not knowing something in it.
2. **`WORKLOG.md`**, top entry only - where things stand right now and the agreed next step.
3. **`CLAUDE.md`** - setup, how to run locally, conventions, known gotchas.
4. **`.claude/skills/papra-session/SKILL.md`** - the session loop. Claude Code loads this
   automatically; other assistants should read it as instructions.

## Then get it running

```bash
bash .claude/skills/papra-session/scripts/start_session.sh
```

Installs, builds, checks out the right branch, prints the latest worklog entry. About a
minute. If the script fails, `CLAUDE.md` has the manual steps and the common failures.

## The first real task

**Run receipt extraction against a real model and judge whether the output is good enough.**

Everything built so far assumes the model returns usable fields, and that assumption has
never been tested against an actual model. It was only ever tested with canned answers,
because the environment the code was written in could not reach an LLM provider.

So before building anything new: get a provider key into the server `.env`, upload a few
real receipts (including a photographed thermal receipt, which is the hard case), and look
at what lands in the custom properties. Report honestly on what is wrong. If extraction
quality is poor, that changes the plan, and it is better to know now.

`CLAUDE.md` has the `.env` layout and a warning about which models work. Read that section
before picking one; the wrong model fails in a way that is not obvious.

## After that

`WORKLOG.md` has the list. In short: four small UI fixes found during testing, then one of
three larger features (mobile scan and review flow, vision-model extraction from photos, or
an expense view with CSV export). Ask Yasam which, do not assume.

## Rules that are not negotiable

- **Pull requests target `YasamNik/papra_docs`, never `papra-hq/papra`.** Opening one
  upstream has already happened once by accident and caused real trouble. Check the base
  repository dropdown every time.
- **New features go in their own server module**, with minimal edits to upstream files. This
  fork needs to keep rebasing onto a fast-moving upstream.
- **Run the checks before committing code**:
  `bash .claude/skills/papra-session/scripts/check.sh`
- **End every session with a WORKLOG entry**, including Yasam's decisions and comments from
  the conversation, not just a list of code changes. That section is what makes the next
  session start well instead of starting over.
- **Do not trust model output in code.** Receipt data from an LLM is validated before it is
  stored. Keep that pattern.

## Licence

AGPL-3.0. Modified versions served over a network must publish their source. Worth raising
with Yasam before this becomes a closed commercial product.
