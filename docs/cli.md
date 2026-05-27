# CLI reference

`claude-init` is a bash CLI. After `install.sh`, the binary lives at `~/.claude/bin/claude-init`. Add that directory to your `PATH`:

```bash
export PATH="$HOME/.claude/bin:$PATH"
```

Verify:

```bash
claude-init --version
```

## Synopsis

```
claude-init <command> [args] [flags]
```

## Commands

### `init`

Scaffold `.claude/` in the current project.

```
claude-init init [flags]
```

Flags:
| Flag | Effect |
|---|---|
| `--template <name>` | Template to use. Default: `default`. |
| `--dry-run` | Print what would happen, write nothing. |
| `--force` | Overwrite existing `.claude/` without prompt. Existing dir is backed up to `.claude.bak.<timestamp>`. |
| `--non-interactive` | Use detected defaults only, fail instead of prompting for missing values. |
| `--from-config <file>` | Read answers from a JSON file (see schema below). No prompts. |

Modes:
- **Interactive** (default): detects defaults from `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml`, prompts for each required + optional value with the detection as default.
- **`--non-interactive`**: uses only what could be detected. Required values that cannot be inferred become empty and validation fails.
- **`--from-config <file>`**: silent. All answers come from the JSON file. Used by `/claude-init` slash command.

Examples:

```bash
# Interactive — most common
claude-init init

# Reproducible — for CI or dotfiles bootstrap
claude-init init --from-config ./project-claude.json --force

# Preview without writing
claude-init init --from-config ./project-claude.json --dry-run
```

### `template list`

List shipped and user templates with their resolved paths.

```bash
claude-init template list
```

Example output:

```
Shipped templates (/Users/you/.claude/templates/claude-init):
  default               shipped  /Users/you/.claude/templates/claude-init/default/

User templates (/Users/you/.claude/templates/user):
  my-custom             user     /Users/you/.claude/templates/user/my-custom/
```

### `template path [name]`

Print the resolved directory for a template name. Default name is `default`.

```bash
claude-init template path
claude-init template path my-custom
```

Resolution order:
1. `~/.claude/templates/user/<name>/`
2. `~/.claude/templates/claude-init/<name>/`

Exits non-zero if not found.

### `template edit [name]`

Open a template in `$EDITOR`. Default name is `default`.

```bash
EDITOR=vim claude-init template edit
claude-init template edit my-custom
```

Note: editing the shipped template directly is risky — re-running `install.sh` will overwrite it (with a backup). Prefer forking first.

### `template fork <src> <dst>`

Copy a shipped template into the user templates dir for safe editing across upgrades.

```bash
claude-init template fork default my-custom
```

This creates `~/.claude/templates/user/my-custom/` from `~/.claude/templates/claude-init/default/`.

Flags:
| Flag | Effect |
|---|---|
| `--from-user` | `<src>` is a user template, not a shipped one. |

Fork a user template into a sibling:

```bash
claude-init template fork --from-user my-custom my-other
```

### `upgrade`

Re-clone the repo and overwrite:
- `~/.claude/bin/claude-init` (the CLI itself)
- `~/.claude/commands/claude-init.md` (the slash command)
- `~/.claude/templates/claude-init/default/` (shipped template)

User templates (`~/.claude/templates/user/`) are **never** touched. The existing shipped template is backed up to `<path>.bak.<timestamp>`.

```bash
claude-init upgrade
```

Override source:

```bash
CLAUDE_INIT_REPO=https://github.com/me/my-fork.git CLAUDE_INIT_BRANCH=experimental claude-init upgrade
```

### `doctor`

Diagnose install state.

```bash
claude-init doctor
```

Checks:
- `CLAUDE_HOME` directory exists
- CLI binary present + executable
- Slash command present
- Shipped template + `CLAUDE.md` + `settings.json` present
- `settings.json` parses as JSON
- `user/` template dir present (warning only)
- `$CLAUDE_HOME/bin` is on `PATH` (warning only)
- `perl` (required), `python3` (recommended), `git` (for upgrade) available

Prints one line per check with `✓`/`!`/`✗`. Exits non-zero if any `✗` failed.

### `help [command]`

Show help. With no argument, prints the top-level usage. With a subcommand, prints that subcommand's usage.

```bash
claude-init help
claude-init help template
claude-init help init
```

### `version`

Print the CLI version.

```bash
claude-init version
claude-init --version
```

## Global flags

| Flag | Effect |
|---|---|
| `-h`, `--help` | Show help. |
| `-V`, `--version` | Print version. |
| `-v`, `--verbose` | Verbose debug output. |
| `-q`, `--quiet` | Suppress non-error output. |

## Environment variables

| Variable | Effect |
|---|---|
| `CLAUDE_HOME` | Override `~/.claude` (default: `$HOME/.claude`). Used by all subcommands. |
| `EDITOR` | Used by `template edit`. |

## `--from-config` schema (Phase 2)

The slash command writes a JSON file in this shape, then calls `claude-init init --from-config <file>`. You can write one by hand too.

```json
{
  "template": "default",
  "required": {
    "project_name": "billing-api",
    "description": "Internal billing service",
    "language": "TypeScript",
    "framework": "Fastify",
    "testing": "Vitest",
    "install_cmd": "pnpm install",
    "dev_cmd": "pnpm dev",
    "build_cmd": "pnpm build",
    "test_cmd": "pnpm test",
    "lint_cmd": "pnpm lint"
  },
  "optional": {
    "deployment": "Fly.io",
    "rules": "Never log full Stripe customer objects.",
    "stack": null
  }
}
```

Required values must all be present. Optional values may be `null` or omitted — their template blocks will be stripped.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success. |
| 1 | Generic error (e.g. template not found). |
| 64 | Subcommand not implemented yet (`EX_USAGE`). |
