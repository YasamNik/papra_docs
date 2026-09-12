---
name: papra-session
description: Start, run and end work sessions on Yasam's papra_docs repository (receipt and document management app forked from Papra, github.com/YasamNik/papra_docs). Use this skill whenever Yasam mentions papra, papra_docs, the receipts app, receipt extraction, the worklog, or says things like "start session", "continue where we left off", "end session", "push it", or "wrap up", even if he does not name the skill. Covers setup, code conventions, running the app locally, the WORKLOG.md session log, and pushing to GitHub.
---

# papra_docs work sessions

Every session follows the same loop: set up, work on a feature branch, record the session
in WORKLOG.md, push. Yasam is a solo developer who prefers terse, direct communication.

**First session on this machine?** Read `HISTORY.md` at the repo root before anything else.
It explains what this fork is, what was already built, what was decided and why, and what is
still unproven. Then read the latest WORKLOG.md entry for where things stand right now.

## 1. Start the session

```bash
bash .claude/skills/papra-session/scripts/start_session.sh            # latest feature branch
bash .claude/skills/papra-session/scripts/start_session.sh feat/xyz   # specific branch
```

It fetches, checks out the right branch, installs dependencies, builds workspace packages,
adds a Temporal polyfill if Node is older than 26, and prints the latest WORKLOG entry.
Takes about a minute. It will not switch branches if there are uncommitted changes.

Then give Yasam a two or three line recap from the latest WORKLOG entry and confirm what to
work on. If the WORKLOG `Active branch` differs from what was checked out, switch to the
WORKLOG one. If the task is new and unrelated, branch from `origin/main` as
`feat/<short-name>` and update the WORKLOG header.

## 2. Work

Read `references/architecture.md` before touching code you have not seen this session. It
maps the monorepo, the server module pattern, the document pipeline and fork additions.
Explore the actual code before writing; upstream moves fast.

Conventions that matter:
- Put new features in their own server module so rebasing onto upstream stays easy. Minimal
  edits to upstream files, only for wiring.
- Pure logic in `*.models.ts` with unit tests, orchestration in `*.usecases.ts` with
  in-memory DB tests.
- Commit in small, working steps with conventional messages (`feat(server): ...`,
  `fix(mobile): ...`, `docs: ...`).
- Run the check script before each commit that touches code:
  ```bash
  bash .claude/skills/papra-session/scripts/check.sh src/modules/<module>   # scoped
  bash .claude/skills/papra-session/scripts/check.sh                        # all unit tests
  ```
- Add a docs page in `apps/docs/src/content/docs/03-guides/` for user-facing features.
- Record new fork modules or changed conventions in `CLAUDE.md`. Longer reasoning and
  anything a future reader would need as background goes in `HISTORY.md`.
- No em dashes anywhere: code comments, docs, commit messages, or replies to Yasam.

## Running the app locally

See the "Running locally" section of `CLAUDE.md` for ports, migrations and the `.env`
layout. Two things that have bitten before:
- Sign in against `localhost`, not `127.0.0.1`. The origin check rejects the latter with a
  403 on sign-in.
- Receipt extraction needs `AI_IS_ENABLED=true` *and* `RECEIPT_EXTRACTION_ENABLED=true`, plus
  a provider key. It is off by default.

## 3. End the session

Trigger when Yasam says he is done, asks to push, or the conversation is wrapping up.

1. Add a WORKLOG.md entry following `references/worklog.md`. Capture Yasam's comments and
   decisions from the chat, not just the code changes. That section is what makes the log
   useful next time.
2. Update `CLAUDE.md` if setup steps, conventions or fork additions changed.
3. Commit: `docs(worklog): session YYYY-MM-DD`.
4. Push:
   ```bash
   bash .claude/skills/papra-session/scripts/end_session.sh
   ```
   The script refuses to push `main`, refuses with uncommitted changes, warns if the WORKLOG
   has no new entry, and prints the PR link. It uses the machine's existing git credentials.
5. Tell Yasam in a few lines: what was pushed, the PR link, and the next step.

## Pull requests

Always target `YasamNik/papra_docs`, never `papra-hq/papra`. A PR was once opened against
upstream by mistake, which triggered their CLA bot and maintainer-gated CI. This module is
fork-local and there is no intent to contribute it upstream.

## If something breaks

- `pnpm install` fails: check `$TMPDIR/papra-install.log`. The pnpm version comes from
  `packageManager` in package.json.
- Typecheck cannot find `@papra/*`: packages were not built, rerun the start script.
- `Temporal is not defined` in tests: run tests through `check.sh`, which loads the polyfill.
  Or use Node 26, which has it natively and needs no polyfill.
- Push fails with 403: git credentials are missing or expired. `gh auth status` is the
  quickest check.
