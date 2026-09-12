# papra_docs architecture notes

Fork of papra-hq/papra (AGPL-3.0). pnpm monorepo, Node 26, TypeScript everywhere.

## Layout
- `apps/papra-server`: Hono API, Drizzle ORM on SQLite/libsql, valibot schemas, background tasks. Most feature work happens here.
- `apps/papra-client`: SolidJS web app.
- `apps/mobile`: Expo / React Native. Has `react-native-document-scanner-plugin` and `expo-share-intent`.
- `apps/docs`: Astro Starlight docs, guides in `src/content/docs/03-guides/*.mdx`.
- `packages/lecture`: text extraction (tesseract.js OCR, PDF, DOCX). `packages/api-sdk`, `packages/webhooks`, `packages/search-parser`, `packages/std`.

## Server module pattern (`apps/papra-server/src/modules/<name>/`)
- `<name>.constants.ts`: names, defaults, task names.
- `<name>.config.ts`: env config (`doc`, `schema`, `env`, `default`), wired into `modules/config/config.ts`.
- `<name>.models.ts`: pure functions. Unit tested in `<name>.models.test.ts` with no DB.
- `<name>.repository.ts`: DB access, `create<Name>Repository({ db })`.
- `<name>.usecases.ts`: orchestration, dependencies passed as arguments. Tested with `createInMemoryDatabase({ ...seed })` from `app/database/database.test-utils`, `overrideConfig()` from `config/config.test-utils`, and `vi.fn()` fakes for AI.
- `<name>.routes.ts`: Hono routes.
- `tasks/<task>.task.ts`: `taskServices.registerTask`, registered in `modules/tasks/tasks.definitions.ts`.

## Document pipeline
Upload → `extract-document-file-content` task (OCR strategies: lecture/tesseract, mistral-ocr, azure-di, docling, custom-http) → schedules `extract-receipt-data` (if `RECEIPT_EXTRACTION_ENABLED`) and `auto-tag-document` (if auto tagging enabled).

## Useful building blocks
- AI: `aiServices.generateStructuredData({ modelId, schema, systemPrompt, userPrompt, source, organizationId })`. Valibot schema becomes structured output. Add new `source` values to `AiCreditsUsageSource` in `ai-credits/ai-credits.types.ts`.
- Custom properties: types text, number, date, boolean, select, multi_select, user_relation, document_relation. Use `createPropertyDefinition` and `setDocumentCustomPropertyValue` from `custom-properties.usecases.ts`. Property `key` = name lowercased with non alphanumerics stripped.
- Tags: `createTag`, `applyTagsToDocuments` in `tags/tags.usecases.ts`.

## Fork additions (keep this list current)
- `modules/receipt-extraction`: detects receipts, fills Vendor, Receipt date, Total, Tax, Currency, Payment method, Expense category properties, applies `Receipt` tag. Env `RECEIPT_EXTRACTION_*`.

## Gotchas
- `/bin/sh` runs tool commands, so brace expansion like `mkdir {a,b}` does not work. Use bash or explicit paths.
- Workspace packages must be built before server typecheck resolves `@papra/*` imports.
- One webhook SSRF test can fail in the sandbox because of network restrictions. Unrelated to feature work.
