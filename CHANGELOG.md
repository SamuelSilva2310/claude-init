# Changelog

All notable changes to this project will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] — 2026-05-27

First public release.

### Added

- **CLI binary** (`claude-init`) with subcommands:
  - `init` — scaffold `.claude/` with placeholder substitution, optional-block stripping, JSON validation. Three modes: interactive (auto-detects from `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml`), `--non-interactive` (detected defaults only), `--from-config <file>` (silent JSON-driven, used by the slash command). Supports `--dry-run`, `--force`, `--template <name>`.
  - `template list/path/edit/fork` — manage shipped + user templates. Fork shipped templates into `~/.claude/templates/user/` for upgrade-safe editing.
  - `upgrade` — re-fetch shipped templates + CLI + slash command from repo; `user/` is never touched, previous shipped template backed up.
  - `doctor` — diagnose install state, required tools, PATH.
  - `help`, `version`, global flags `-h` / `-V` / `-v` / `-q`.
- **Slash command** (`/claude-init`) — thin AI front-end over the CLI. Detects project context, asks adapted questions per stack, writes config JSON, shells out to `claude-init init --from-config`, then augments output with drafted Gotchas / Key Files / Architecture and stack-specific `settings.json` allow entries. Falls back from `PATH` lookup → `$CLAUDE_HOME/bin/claude-init` → `~/.claude/bin/claude-init` when CLI not on `PATH`.
- **One-liner installer** (`install.sh`) — shell-aware PATH instructions (zsh / bash / fish / POSIX sh) printing ready-to-run `echo ... >> ~/.zshrc` commands. Opt-in `CLAUDE_INIT_ADD_TO_PATH=1` auto-appends to the right rc files with backup (zsh writes to both `~/.zshrc` and `~/.zshenv` so non-interactive shells also see the CLI). Idempotent — re-runs do not duplicate entries.
- **Dev installer** (`scripts/dev-install.sh`, `scripts/dev-uninstall.sh`) — symlink-installs from a local checkout so edits go live immediately.
- **Shared PATH helper** (`scripts/lib/path-setup.sh`) — single source of truth for shell detection + rc-file resolution, sourced by both installers.
- **Default template** (`templates/default/`) — minimal `CLAUDE.md` with section stubs (Stack, Commands, Architecture, Key Files, Code Style, Environment, Testing, Gotchas, optional Project Rules) and pre-seeded `settings.json` with safe read-only `allow` + destructive `deny`.
- **Placeholder system** — required `{{name}}` placeholders (validated, must resolve) and optional `<!-- optional:name --> ... <!-- /optional -->` blocks (stripped if value missing).
- **Two-tier template layout** — shipped templates at `~/.claude/templates/claude-init/`, user forks at `~/.claude/templates/user/`. Installer + `upgrade` never touch `user/`.
- **Smoke test** (`tests/smoke.sh`) — installer + CLI + dev-install symlink regression coverage, including the `cp -RL` symlink-dereference assertion.
- **Examples** for Node, Python, Go projects under `examples/`.
- **Docs**: `docs/cli.md`, `docs/customization.md`, `docs/placeholders.md`. Architecture in `PLAN.md`.

### Dependencies

- **`perl`** required for placeholder substitution (preinstalled on macOS and most Linux).
- **`python3`** required for `--from-config` and JSON validation.
- **`git`** required for `install.sh` and `claude-init upgrade`.

### Platforms

- macOS (primary target).
- Linux (tested).
- Bash 3.2+ compatible (no `mapfile`, no associative arrays in shared code).

[Unreleased]: https://github.com/SamuelSilva2310/claude-init/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/SamuelSilva2310/claude-init/releases/tag/v0.1.0
