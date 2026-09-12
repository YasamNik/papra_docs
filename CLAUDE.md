# Papra receipts fork: working notes for Claude

Fork of papra-hq/papra, extended into a receipt and document capture app (mobile scan, AI
extraction).

**New here?** Read `START-HERE.md` first, then `HISTORY.md` for the background: what this fork is, what upstream
already provided, what has been built, and what is still unproven. Then read the top entry
of `WORKLOG.md` for current state. This file is the quick reference.

## Session workflow

Driven by the `papra-session` skill in `.claude/skills/papra-session/` (start, check and end
scripts). Without the skill:

1. Check out the active branch named at the top of WORKLOG.md.
2. `pnpm install --ignore-scripts`, then `pnpm --filter "./packages/*" run build`.
3. Work, commit small, push after each milestone. Never push to `main`; merge via PR.
4. Before ending: add a WORKLOG.md entry (Done, Decisions, Comments, Open / Next) and push.

PRs target `YasamNik/papra_docs`, never `papra-hq/papra`.

## Environment

- Node 26 required (`Temporal` global). On older Node, run tests with a Temporal polyfill:
  `NODE_OPTIONS="--import <polyfill-setup>" npx vitest run`
- Server: `apps/papra-server` (Hono, Drizzle, SQLite/libsql, valibot). Typecheck:
  `npx tsc --noEmit -p .`
- Web client: `apps/papra-client` (SolidJS, vite).
- Mobile: `apps/mobile` (Expo, document scanner plugin, share intent).
- Lint/format: `npx oxlint -c oxlint.config.ts <paths>`, `npx oxfmt <paths>`.

## Running locally

```bash
cd apps/papra-server
npx tsx src/scripts/migrate-up.script.ts   # creates/updates db.sqlite
npx tsx src/index.ts                       # API on :1221

cd ../papra-client
pnpm dev                                   # web on :3000, proxies /api/ to :1221
```

Then open **`http://localhost:3000`**. Do not use `127.0.0.1`: the origin check rejects it
with a 403 on sign-in.

Server `.env` for receipt extraction:

```bash
AI_IS_ENABLED=true
RECEIPT_EXTRACTION_ENABLED=true
OPENROUTER_API_KEY=sk-or-v1-...
RECEIPT_EXTRACTION_MODEL=openrouter://google/gemini-2.5-flash
```

Both `AI_IS_ENABLED` and `RECEIPT_EXTRACTION_ENABLED` are needed; extraction is off by
default. Any provider works: `anthropic://`, `openai://`, `mistral://`, `ollama://` and
others are registered adapters, no code changes needed.

## Known gotchas

- **Model choice matters.** The AI adapter always sends `stream: true` along with
  `response_format: json_schema, strict: true`. A model must support streaming *and*
  structured outputs, or extraction fails with `missing structured result`.
- **OpenRouter routes per endpoint, not per model.** The same model served by a provider that
  ignores `json_schema` degrades quietly rather than failing. Check the `structured_outputs`
  flag in the Providers section of the model page. The proper fix,
  `provider.require_parameters: true`, cannot currently be sent: `OpenAiCompatibleAdapterConfig`
  exposes only `defaultHeaders` and `defaultQuery`.
- **Credit rate log noise.** `modelCreditRates` in `ai-credits.rates.ts` only lists two
  Mistral models, so every call with any other model logs `Model credit rate not found`. It is
  caught and logged, never fatal.
- Extraction quality depends on the OCR text. Phone photos of thermal receipts are hard for
  the default tesseract strategy; `mistral-ocr` or `azure-di` do much better.

## Conventions

- New features live in their own module under `apps/papra-server/src/modules/<name>` so
  upstream rebases stay easy.
- Pure logic in `*.models.ts` with unit tests; orchestration in `*.usecases.ts`; background
  jobs in `tasks/`.
- Env config per module in `*.config.ts`, wired into `modules/config/config.ts`.
- No em dashes in docs or code comments.

## Fork additions

- `modules/receipt-extraction`: AI receipt detection into custom properties plus `Receipt`
  tag (`RECEIPT_EXTRACTION_*`). Docs: `apps/docs/src/content/docs/03-guides/14-receipt-extraction.mdx`.

## License

AGPL-3.0. Modified versions served over a network must publish source.
