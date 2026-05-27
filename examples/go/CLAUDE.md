# edge-router

HTTP edge router that fronts the internal microservices and handles auth + rate limiting.

## Stack

- Language: Go 1.22
- Framework: net/http + chi
- Testing: go test

## Commands

| Command | Description |
|---------|-------------|
| `go mod download` | Install dependencies |
| `go run ./cmd/router` | Start dev server |
| `go build -o bin/router ./cmd/router` | Production build |
| `go test ./...` | Run tests |
| `golangci-lint run` | Lint |

## Architecture

```
edge-router/
  cmd/router/        # entrypoint
  internal/
    middleware/      # auth, ratelimit, logging
    upstream/        # service discovery + transport
    config/          # env + flag parsing
  pkg/health/        # exported health-check helpers
```

## Key Files

- `cmd/router/main.go` — composition root
- `internal/middleware/auth.go` — JWT validation, source of all auth decisions
- `internal/upstream/registry.go` — upstream service map, edit when adding a new backend

## Code Style

- Errors wrapped with `fmt.Errorf("…: %w", err)`. Never `errors.New` at call sites.
- Context is the first arg everywhere. No `ctx` stored on structs.
- Lowercase package names, no underscores.

## Environment

- `LISTEN_ADDR` — bind address, default `:8080`
- `JWT_PUBLIC_KEY_PATH` — PEM file path
- `UPSTREAM_CONFIG` — JSON file mapping route → upstream URL

## Testing

- `go test ./...` — full suite
- `go test -race ./internal/upstream` — race detector for the connection pool
- httptest is fine for middleware; do not stand up a real listener in unit tests.

## Gotchas

- `internal/upstream/pool.go` reuses connections by host. If you add a new upstream, double-check the host comparison is case-insensitive.
- Rate limiter is per-IP — behind a CDN, it sees the CDN IP. The `X-Forwarded-For` parse lives in `middleware/realip.go`; do not bypass it.
