# claude-init

Minimal, opinionated `.claude/` scaffolding CLI + slash command for any project.

## Stack

- Language: Bash
- Framework: none (pure bash CLI)
- Testing: bash smoke test (tests/smoke.sh)
- Deployment: One-liner installer: `curl -fsSL https://raw.githubusercontent.com/SamuelSilva2310/claude-init/main/install.sh | bash`

## Commands

| Command | Description |
|---------|-------------|
| `./scripts/dev-install.sh` | Symlink-install CLI + slash + template into `~/.claude/` |
| `./scripts/dev-uninstall.sh` | Remove dev-install symlinks |
| `./bin/claude-init init` | Run CLI directly from checkout |
| `bash tests/smoke.sh` | Run integration smoke test (install + init + regressions) |
| `shellcheck bin/claude-init install.sh scripts/lib/*.sh tests/*.sh` | Lint shell sources |

## Architecture

```
claude-init/
  bin/                       # CLI entrypoint — single-file dispatcher
  commands/                  # /claude-init slash command (Claude Code)
  scripts/                   # dev-install, dev-uninstall
    lib/                     # shared shell helpers (path-setup)
  templates/
    default/                 # shipped scaffold — copied into ./.claude/ on init
      agents/ commands/ skills/   # empty scaffold dirs (gitkept)
  examples/                  # example .claude/ outputs per stack (go, node, python)
  docs/                      # cli.md, customization.md, placeholders.md
  tests/                     # smoke.sh — end-to-end install + init regression suite
  install.sh                 # public one-liner installer
  PLAN.md HANDOFF.md         # architecture + handoff notes
```

Two-tier template root inside `~/.claude/templates/`:
- `claude-init/` — shipped, overwritten by `upgrade` / `install.sh`
- `user/` — user forks, NEVER touched by installers

## Key Files

- [bin/claude-init](../bin/claude-init) — entire CLI: subcommand dispatch, detection, substitution, validation. Read first.
- [commands/claude-init.md](../commands/claude-init.md) — slash command spec; drives the CLI from Claude Code with AI augmentation
- [templates/default/CLAUDE.md](../templates/default/CLAUDE.md) — placeholder schema is the source of truth for required/optional keys
- [templates/default/settings.json](../templates/default/settings.json) — baseline permissions; mirrored to every scaffolded project
- [install.sh](../install.sh) — public installer; honors `CLAUDE_INIT_REPO`, `CLAUDE_INIT_BRANCH`, `CLAUDE_HOME`, `CLAUDE_INIT_ADD_TO_PATH`
- [scripts/dev-install.sh](../scripts/dev-install.sh) — symlinks repo → `~/.claude/` for live edits
- [scripts/lib/path-setup.sh](../scripts/lib/path-setup.sh) — shell-aware PATH setup, sourced by both installers
- [tests/smoke.sh](../tests/smoke.sh) — single integration test; only test gate before merge
- [PLAN.md](../PLAN.md) — full architecture doc; read before designing changes

## Code Style

- Strict mode at every script top: `set -euo pipefail`
- Logging through helpers (`_log`/`_ok`/`_warn`/`_die`/`_dbg`), never bare `echo` for status
- Function naming: `_private_helper`, `cmd_<subcommand>` for entrypoints
- Parsing/substitution offloaded to `perl -0777` and `python3` heredocs — no Bash string-juggling for JSON or multi-line text
- macOS-first portability — every `cp -R` carefully chosen for symlink semantics
- Public template files use `{{name}}` for required placeholders and `<!-- optional:name --> ... <!-- /optional -->` for strippable blocks

## Environment

CLI honors:
- `CLAUDE_HOME` — override `~/.claude/` install root
- `EDITOR` — used by `template edit`
- `CLAUDE_INIT_REPO` — override repo URL (`upgrade`, installers, smoke test)
- `CLAUDE_INIT_BRANCH` — override branch (default `main`)
- `CLAUDE_INIT_ADD_TO_PATH=1` — auto-append PATH export to detected shell rc

Project itself has no runtime env vars.

## Testing

- `bash tests/smoke.sh` — runs full suite (~5s)
- Tests use `CLAUDE_INIT_REPO=file://<repo-root>` to exercise the local checkout, not a remote pull
- The dev-install symlink regression block ([tests/smoke.sh:88-145](../tests/smoke.sh#L88-L145)) is the most fragile section — guards against the BSD `cp -R` symlink bug
- No unit tests, no test runner — just the smoke script. Add cases inline.

## Gotchas

- **`cp -RL` not `cp -R`** in [bin/claude-init:669](../bin/claude-init#L669). Under dev-install the shipped template is a symlink; BSD `cp -R` reproduces the symlink instead of copying contents, leaving `./.claude` as a symlink and every subsequent step a silent no-op. Sanity guards at [bin/claude-init:673-678](../bin/claude-init#L673-L678) fail loud if this regresses.
- **Template resolution order**: `user/<name>/` wins over `claude-init/<name>/` ([bin/claude-init:157-170](../bin/claude-init#L157-L170)). A user fork named `default` silently shadows the shipped one — by design.
- **Optional blocks use HTML-comment markers**, processed by perl `-0777` slurp ([bin/claude-init:410-429](../bin/claude-init#L410-L429)). Empty/null value → entire block deleted; non-empty → only markers stripped. Mismatched / unclosed markers will be caught by `_validate_output` and abort the scaffold.
- **Required keys reject empty strings** ([bin/claude-init:387-398](../bin/claude-init#L387-L398)). For bash projects with no real build step, use `:` or `true`, not `""`.
- **PATH bootstrap is shell-aware and dual-file for zsh**: writes both `~/.zshrc` (interactive) AND `~/.zshenv` ([scripts/lib/path-setup.sh:22-27](../scripts/lib/path-setup.sh#L22-L27)) so Claude Code's non-interactive Bash sees the CLI.
- **`upgrade` overwrites `bin/`, `commands/`, `templates/claude-init/` only**; `templates/user/` is never touched ([bin/claude-init:717-760](../bin/claude-init#L717-L760)). Forks survive upgrades.
- **External-tool dependencies**: `perl` required for substitution, `python3` required for `--from-config` and JSON validation, `git` required for `upgrade`. `doctor` reports missing tools.
- **Substitution scope**: only `*.md`, `*.json`, `*.yaml`, `*.yml`, `*.txt` ([bin/claude-init:436-443](../bin/claude-init#L436-L443)). Placeholders in other extensions are ignored silently.

---

<!--
Maintenance:
- Keep entries one line each.
- Document patterns unique to THIS project. Generic engineering rules belong in ~/.claude/CLAUDE.md.
- Update when conventions evolve.
-->
