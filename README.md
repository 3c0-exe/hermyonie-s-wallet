# Hermyonie’s Wallet

A mobile-first Flutter personal finance tracker for cash, bank accounts, e-wallets, credit cards, loans, bills, installments and shared expenses. PHP amounts are calculated in centavos while preserving the existing Hive storage schema.

## What works

- Mobile bottom navigation, readable pink theme, keyboard-aware forms and a desktop sidebar.
- Cash is separate from credit/loan balances. Provider limits and personal spending caps are separate fields.
- Transfers and card repayments update both accounts without inflating income or expense reports.
- Recurring monthly bills, partial payments and installment plans retain payment history. Undo the latest payment through Activity.
- Monthly activity search and account filters; monthly spending summaries.
- Preview canonical statement CSVs and skip duplicate references. Download the template from Settings → Import transactions.
- Versioned JSON backup/restore, including existing version 1 backups and shared expenses. Restore validates records before replacing data.
- Serialized mutations with a durable rollback journal recover interrupted writes when the app starts again.
- Groq turns commands into proposed actions. You review each action before saving it.

## Run and test

Pinned deployment SDK: Flutter **3.47.5**, Dart **3.13.4**.

```sh
flutter pub get
flutter test
flutter analyze
flutter build web --release --base-href / --pwa-strategy=none
node --test test/assistant.test.mjs
```

Generated Hive adapters are committed. When changing model fields:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Do not renumber existing Hive fields or type IDs. New fields have defaults so old device databases continue to open. Existing wallets default to cash: the old credit-card icon did not encode a credit account. Create a real credit tracking account and reconcile the old account before archiving it.

## Vercel and Groq

Pushing to the connected production branch triggers Vercel. `vercel.json` uses a pinned Flutter checkout, outputs `build/web`, and serves `api/assistant.mjs` as a Node function. The app uses current Flutter bootstrapping and removes legacy Flutter service-worker caches without clearing IndexedDB records.

Manual tracking is ready immediately; Groq is optional. To enable it later:

1. In Vercel → Project → Settings → Environment Variables, add `GROQ_API_KEY`.
2. Add `WALLET_ASSISTANT_TOKEN`, a long private passphrase of your choice. This protects the API key from public endpoint use.
3. Optionally set `GROQ_MODEL` (default `openai/gpt-oss-20b`, a model supporting strict JSON schema output).
4. Redeploy the project.
5. In the app, open Settings → Assistant access and enter the passphrase. It is held in memory for the current session; do **not** enter the Groq API key there.

The endpoint sends only the command and account IDs/names/types, not full history. It never directly writes data or sends real money. Application services validate every proposed action again. The endpoint has authentication, request limits, a provider timeout, and best-effort per-instance throttling; for a public multi-user product, replace the shared passphrase with per-user authentication and durable rate limiting.

For local testing of the API, use `vercel dev`. For a native build calling your deployment, provide `--dart-define=ASSISTANT_BASE_URL=https://your-deployment.example`.

## Import format

```csv
date,description,amount,type,category,reference
2026-01-01,Lunch,150,expense,Food & Drink,bank-reference-001
2026-01-02,Salary,20000,income,Salary,bank-reference-002
```

Use ISO dates and positive PHP amounts. `type` is `expense` or `income`. Stable references prevent the same transaction being imported twice into the same account. When references are absent, a fingerprint uses account/date/description/amount/type: identical real purchases may require distinct references. Imports change the balance, so start from the balance before the imported period and reconcile afterward. Do not import transfers as ordinary expenses; record them with the transfer flow. PDF extraction and provider-specific formats are not implemented yet.

## Data and scope

Data stays in the current browser/device. Google Drive saves a backup; it is not automatic multi-device sync. Clearing browser storage can erase records, so export backups regularly. Backups contain financial data in readable JSON.

There is **no live GCash, Maya, Atome, bank or loan-provider sync**. Account presets represent local records. Creating an Atome card here does not issue a card or change the provider’s limit. Live integrations need supported consumer APIs and authorization. CSV imports and manual records are the supported ingestion methods in this release.

The home forecast subtracts recorded obligations due by the next 15th/month-end checkpoint from recorded cash. It does not assume salary, everyday expenses or unrecorded card statements. A debt recorded in Plan should not also be entered as a separate loan balance, because that would double-count what you owe.
