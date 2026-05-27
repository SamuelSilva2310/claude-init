# billing-api

Internal billing service exposing invoice + subscription endpoints to the dashboard.

## Stack

- Language: TypeScript
- Framework: Fastify
- Testing: Vitest
- Deployment: Fly.io

## Commands

| Command | Description |
|---------|-------------|
| `pnpm install` | Install dependencies |
| `pnpm dev` | Start dev server |
| `pnpm build` | Production build |
| `pnpm test` | Run tests |
| `pnpm lint` | Lint / format |

## Architecture

```
billing-api/
  src/
    routes/    # HTTP route handlers
    services/  # business logic
    db/        # Drizzle schema + migrations
  tests/       # Vitest suites
  scripts/     # one-off ops scripts
```

## Key Files

- `src/server.ts` — Fastify bootstrap, plugin registration
- `src/db/schema.ts` — Drizzle table definitions, source of truth for migrations
- `drizzle.config.ts` — migration runner config

## Code Style

- Route files export a single `register*` function. No default exports.
- Service functions return `Result<T, E>` (custom union), never throw on expected errors.
- Use `pino` logger via `req.log`, never `console.log`.

## Environment

- `DATABASE_URL` — Postgres connection string
- `STRIPE_SECRET_KEY` — server-side Stripe key

## Testing

- `pnpm test` — full suite
- `pnpm test src/services/invoice.test.ts` — single file
- Integration tests spin up Postgres via testcontainers; do not mock the DB.

## Gotchas

- `pnpm dev` requires `DATABASE_URL` pointing at a *migrated* DB. Run `pnpm db:migrate` first.
- Drizzle schema changes need a regenerated migration before `pnpm build` will pass typecheck.
- Stripe webhook routes verify signatures — local testing requires `stripe listen --forward-to ...`.

## Project Rules

- Never log full Stripe customer objects. PII redaction lives in `src/logger.ts`.
