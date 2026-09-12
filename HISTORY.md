# Project history

Background for anyone (human or Claude) picking this repo up cold. WORKLOG.md is the
running per-session log; this file is the story behind it and the reasoning that does not
fit in a log entry. Written 2026-09-12, at the point where work moves out of Claude's
web sandbox and onto Yasam's machine with Claude Code.

## Who and what

Yasam is a solo developer in Kanata, Ontario. He wants an app for collecting and managing
receipts: capture on a phone by photo or document scan, then have AI detect that a
document is a receipt and pull the useful fields out of it automatically.

Rather than start from scratch he forked [papra-hq/papra](https://github.com/papra-hq/papra)
to `YasamNik/papra_docs`. Papra is a document management platform, so the storage,
organisations, tagging, search and upload pipeline already existed.

Communication preference: terse and direct. No em dashes anywhere, in code, docs, commit
messages or chat.

## What the upstream project already gave us

The first session was spent reading the fork rather than writing code, and it changed the
plan. A lot of what looked like work to do was already there, just undocumented in the
README:

- `apps/mobile`: a full Expo / React Native app, including
  `react-native-document-scanner-plugin` for edge detection and cropping, and a share
  intent so other apps can send documents in.
- An AI auto-tagging module, with adapters for Anthropic, any OpenAI-compatible endpoint,
  and Ollama.
- `packages/lecture`: content extraction, with tesseract.js OCR plus PDF, DOCX and RTF
  parsing. Other OCR strategies exist behind config: `mistral-ocr`, `azure-di`, `docling`,
  and `custom-http`.
- AI credits, plans, subscriptions, email ingestion, webhooks, an API SDK, and custom
  properties on documents.

So the real gap was never capture or OCR. It was that the AI layer only produced **tags**.
Nothing pulled structured fields out of a document, and nothing knew what a receipt was.

## The first piece of work: receipt extraction

`apps/papra-server/src/modules/receipt-extraction/`.

It runs as a background task after content extraction, scheduled alongside auto-tagging in
`modules/documents/tasks/extract-document-file-content.task.ts`. The LLM decides whether the
document is a receipt or invoice. If it is, the module lazily creates and fills custom
properties (Vendor, Receipt date, Total, Tax, Currency, Payment method, Expense category)
and applies a `Receipt` tag.

Design choices worth knowing:

- It reuses same-named properties when the type matches, and skips ones whose type clashes,
  rather than creating duplicates or failing.
- It never overwrites a value already on a document, unless
  `RECEIPT_EXTRACTION_OVERWRITE_EXISTING_VALUES` is on. A value a human corrected by hand
  should survive re-extraction.
- Model output is not trusted. Invalid, rolled-over, future and pre-1990 dates are rejected,
  a tax greater than the total is dropped, currency must be a 3 letter ISO code, amounts are
  rounded to 2dp, and document content is truncated at 12,000 characters. Card numbers are
  never stored.
- Off by default (`RECEIPT_EXTRACTION_ENABLED=false`), and requires `AI_IS_ENABLED=true`.

Everything lives in its own module on purpose. Upstream moves fast, and the only edits to
upstream files are the minimum needed for wiring: `modules/config/config.ts`,
`modules/tasks/tasks.definitions.ts`, `modules/ai-credits/ai-credits.types.ts` (a new
`receipt-extraction` credit source), and the extraction task. That keeps rebases cheap.

## Proving it worked

The module has 18 unit tests, and the full server suite passed (1151 tests, with one
pre-existing webhook SSRF failure caused by sandbox networking, not by this change).

Beyond tests, the app was run for real in the sandbox: server on port 1221, web client on
port 3000, an account and organisation created through the UI, four receipt PDFs generated
(Loblaws, Shell, The Works, and an AWS invoice) and uploaded through the real API. PDF text
extraction worked. The extraction usecase then ran against the real dev database and wrote
all seven fields plus the tag on every document.

The caveat at that stage: the LLM's answers were canned, because the sandbox had no API key.
The code path was real; the model was not.

## Moving to a real model provider

Yasam chose OpenRouter, so any model could be swapped in without code changes.

That turned out to need no code at all. OpenRouter is already a registered
OpenAI-compatible adapter in the repo. Setting `OPENROUTER_API_KEY` and a model id of
`openrouter://<model>` is the whole configuration.

The live call still could not be made from the sandbox: Claude's sandbox has a network
allowlist and `openrouter.ai` is not on it. So the next best thing was done instead. The
real AI services stack and the real OpenRouter adapter were run end to end against a local
endpoint speaking the same protocol, and the outgoing request was captured and inspected.
It was correct: right model id, bearer auth, `response_format` json_schema with
`strict: true`, correct system and user prompts, correct receipt text. All four documents
extracted, all seven fields written each.

Three things came out of that run, and they are the reason this section exists:

1. **The adapter always streams.** `ai.services.ts` passes `stream: false` to the tanstack
   chat helper, but the HTTP request still carries `stream: true` and the reply is consumed
   as SSE. A model must support streaming *and* json_schema structured outputs, or
   extraction fails with `missing structured result`.
2. **OpenRouter decides structured-output support per endpoint, not per model.** The same
   model can be served by several providers, and only some honour `json_schema`. When a
   request routes to one that does not, OpenRouter may quietly fall back to looser JSON, so
   extraction degrades instead of failing loudly. The fix is `provider.require_parameters:
   true` in the request body, which the adapter currently cannot send:
   `OpenAiCompatibleAdapterConfig` exposes only `defaultHeaders` and `defaultQuery`.
3. **An upstream annoyance.** `modelCreditRates` in `ai-credits.rates.ts` only covers two
   Mistral models, so any other model logs `Model credit rate not found` on every single
   call. It is caught and logged, never fatal, but on a self-hosted install it is pure noise.

**Still untested: how well a real model actually performs.** That is the first thing to do
locally, because the whole feature rests on it.

## Working arrangement, and why it is changing

Sessions ran in Claude's web sandbox, which is wiped between chats, so GitHub was the source
of truth and each session ended with a push using a short-lived fine-grained token Yasam
pasted into chat.

Two things went wrong along the way, both worth not repeating:

- A pull request was opened against **papra-hq/papra** (upstream) instead of the fork. That
  triggered upstream's CLA bot, a maintainer-gated CI workflow and an automated review. It
  was closed. This module is fork-local and there is no intent to contribute it upstream;
  signing the CLA would assign rights over the code. Always target `YasamNik/papra_docs`.
- Early commits were authored as `Claude <claude@local>` and `<noreply@anthropic.com>`,
  which is what the CLA bot could not match to a GitHub account. The identity is now
  `YasamNik <yasam.nikros@gmail.com>`. Commits already merged keep the old author; not worth
  rewriting history over.

As of 2026-09-12 the work moves to Claude Code on Yasam's own machine. That removes the
sandbox network allowlist (so OpenRouter works), removes the need to paste GitHub tokens
into a chat (local git is already authenticated), and removes the ephemeral filesystem.

## Licensing

AGPL-3.0. Modified versions served over a network must publish their source. Worth keeping
in mind before this becomes a closed commercial SaaS.

## Where to look next

`WORKLOG.md` has the per-session log, newest first, with an Open / Next section that is the
actual to-do list. `CLAUDE.md` has setup, conventions and known gotchas. The
`.claude/skills/papra-session/` skill drives the session loop.
