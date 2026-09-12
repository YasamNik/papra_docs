# Worklog

Active branch: `feat/receipts`
Newest first. One entry per session. Format: see the papra-session skill (`references/worklog.md`).

## 2026-09-12 · `feat/receipts` · OpenRouter validation

**Done**
- Verified receipt extraction against the **real** AI services stack and the **real** `openrouter` adapter, end to end. Previously only the usecase was tested with canned answers. All 7 fields written per document on all 4 sample receipts.
- Confirmed no code changes are needed for OpenRouter: it is already a registered OpenAI-compatible adapter (`OPENROUTER_API_KEY`, `OPENROUTER_BASE_URL`, model id `openrouter://<model>`).
- Documented OpenRouter setup and the structured-output caveat in `14-receipt-extraction.mdx`.

**Decisions**
- Text extraction path first (OCR text to LLM). Vision-model extraction from receipt photos stays a separate, later piece of work.

**Comments**
- The sandbox network allowlist blocks `openrouter.ai`, so the live call cannot be made from here. Validation used a local OpenAI-compatible mock; the request the adapter builds was inspected and is correct (model id, bearer auth, `response_format` json_schema, system and user prompts, receipt text).
- The adapter always sends `stream: true`. A model must support streaming *and* `json_schema` structured outputs, otherwise the call fails with `missing structured result`.
- OpenRouter decides structured-output support per endpoint, not per model. A model can be routed to a provider that ignores `json_schema`, degrading quietly. The adapter has no way to pass `provider.require_parameters: true`, since `OpenAiCompatibleAdapterConfig` exposes only `defaultHeaders` and `defaultQuery`.

**Open / Next**
- Upstream bug, low severity: `modelCreditRates` in `ai-credits.rates.ts` only covers two Mistral models, so every call with any other model logs a `Model credit rate not found` error. Caught and logged, never fatal, but it spams logs on self-hosted installs. Consider skipping credit registration when the org is self-hosted.
- Consider adding an `extraBody` passthrough to the OpenAI-compatible adapter config so `provider.require_parameters` can be set.
- Still untested: a real model's actual output quality. Needs a run outside the sandbox.

## 2026-09-11 · `feat/receipts` · Fork review, receipt extraction, session workflow

**Done**
- Reviewed the fork. Already present upstream: Expo mobile app with document scanner and share intent, AI auto-tagging (Anthropic, OpenAI-compatible, Ollama), OCR strategies (tesseract, mistral-ocr, azure-di, docling).
- Added `receipt-extraction` server module: LLM detects receipts and invoices, fills Vendor, Receipt date, Total, Tax, Currency, Payment method, Expense category custom properties, applies `Receipt` tag. Env `RECEIPT_EXTRACTION_*`, AI credits source `receipt-extraction`. 18 tests, docs page `14-receipt-extraction.mdx`.
- Ran server and web client in the sandbox, uploaded 4 receipt PDFs through the real API, ran extraction (LLM reply simulated, no API key in sandbox), captured screenshots.
- Added CLAUDE.md, this worklog, and the `papra-session` skill (setup, check and push scripts).

**Decisions**
- Work in Claude's sandbox, push to GitHub at the end of each session (and after milestones) with a short-lived fine-grained token. No patches.
- Session log lives in the repo as WORKLOG.md, with a comments section for Yasam's feedback.
- Receipt extraction uses a global env toggle for now; per-org setting later (needs a migration).

**Comments**
- Yasam wants the app for collecting and managing receipts, with mobile capture by photo or scanning and AI detection and tagging.
- Sandbox runs Node 22; repo needs Node 26 (`Temporal`). Tests run with a polyfill via the skill's `check.sh`.
- Keep AGPL-3.0 in mind if this becomes a closed commercial SaaS.

**Open / Next**
- From running the app with 4 sample receipts: set the document Date from Receipt date, show Vendor and Total columns in the list, format money (3.1 shows instead of 3.10), fix action button overflow at phone width.
- Pick the next feature: mobile scan + review flow, vision model extraction, or expense view + CSV export.
