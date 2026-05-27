# data-ingest

ETL service that pulls events from Kafka and lands them in BigQuery.

## Stack

- Language: Python 3.12
- Framework: FastAPI
- Testing: pytest

## Commands

| Command | Description |
|---------|-------------|
| `uv sync` | Install dependencies |
| `uv run uvicorn app.main:app --reload` | Start dev server |
| `uv build` | Build wheel |
| `uv run pytest` | Run tests |
| `uv run ruff check .` | Lint / format |

## Architecture

```
data-ingest/
  app/
    consumers/    # Kafka consumer wiring
    transforms/   # row transforms, pure functions
    sinks/        # BigQuery write adapters
  tests/          # pytest suites
  ops/            # ops scripts (backfill, replay)
```

## Key Files

- `app/main.py` — FastAPI app + health endpoints
- `app/consumers/registry.py` — topic-to-handler routing
- `pyproject.toml` — deps, ruff config, pytest config

## Code Style

- Type-hint everything. CI runs `mypy --strict`.
- Pure functions in `transforms/`. Side effects belong in `sinks/` or `consumers/`.
- Prefer `pydantic` models over dicts at every IO boundary.

## Environment

- `KAFKA_BROKERS` — comma-separated broker list
- `BIGQUERY_DATASET` — target dataset
- `GOOGLE_APPLICATION_CREDENTIALS` — path to service-account JSON

## Testing

- `uv run pytest` — full suite
- `uv run pytest tests/transforms` — single package
- Integration tests use a real BigQuery sandbox project (`BQ_SANDBOX_PROJECT`), not mocks — a previous regression slipped past mocked tests.

## Gotchas

- BigQuery streaming inserts have a deduplication window. Use `insertId` from `app/sinks/bq.py`.
- Kafka consumer group is shared across replicas. Local dev must override `KAFKA_GROUP_ID`.
- Ruff config enforces 100-char lines; black-style 88 will fail CI.
