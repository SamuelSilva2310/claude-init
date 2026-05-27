# claude-init

Minimal, opinionated `.claude/` scaffolding for any project. A bash CLI plus a slash command that drives it.

## Why

`/init` (built-in) writes a single `CLAUDE.md` from codebase analysis. It does not scaffold the full `.claude/` workspace, does not template, and does not enforce a baseline `settings.json`.

[`claude-code-templates`](https://github.com/davila7/claude-code-templates) is comprehensive but heavyweight: stack matrix, NPM dependency, opinionated per-framework presets.

**`claude-init` sits between them.** One template by default, hackable, fork-friendly. CLI does the mechanical work; the slash command adds AI-driven detection and content drafting on top.

Philosophy:
- **Project `CLAUDE.md` documents what's unique to *this* repo.** Generic engineering rules belong in `~/.claude/CLAUDE.md`.
- **Pre-seeded `settings.json`** — common read-only Bash allowed, destructive commands denied, no permission prompts for the obvious stuff.
- **Templates are upgrade-safe.** Shipped templates live in `~/.claude/templates/claude-init/`. Your forks live in `~/.claude/templates/user/` and are never touched by the installer.

See [PLAN.md](PLAN.md) for the full architecture.

## Install

One-liner (until v0.1.0 ships, this pulls `main`):

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/claude-init/main/install.sh | bash
```

Add the CLI to your `PATH`:

```bash
export PATH="$HOME/.claude/bin:$PATH"
```

Verify:

```bash
claude-init --version
claude-init template list
ls ~/.claude/commands/claude-init.md ~/.claude/templates/claude-init/default/CLAUDE.md
```

### Local development

If you are hacking on this repo, symlink-install from the checkout so edits go live:

```bash
git clone https://github.com/<owner>/claude-init.git
cd claude-init
./scripts/dev-install.sh
```

Undo with `./scripts/dev-uninstall.sh`.

## Usage

Inside any project directory, either:

```bash
claude-init init                  # CLI (Phase 2 — not yet implemented)
```

…or, inside Claude Code:

```text
/claude-init
```

The flow:

1. Detect project type (Node, Python, Go, Rust, …)
2. Infer commands from `package.json` / `pyproject.toml` / `Makefile`
3. Ask only for what cannot be inferred
4. Copy template → `./.claude/`
5. Substitute placeholders
6. Strip unused optional blocks
7. Validate output
8. (Slash command only) Augment with AI-drafted Gotchas, Key Files, stack-specific `settings.json` entries

See [docs/cli.md](docs/cli.md) for full CLI reference.

## Installed layout

```
~/.claude/
├── bin/
│   └── claude-init                  # CLI binary
├── commands/
│   └── claude-init.md               # slash command
└── templates/
    ├── claude-init/                 # shipped — installer overwrites
    │   └── default/
    └── user/                        # yours — installer never touches
        └── <your-forks>/
```

Fork the default for safe edits:

```bash
claude-init template fork default my-custom
claude-init template edit my-custom
claude-init init --template my-custom
```

See [docs/customization.md](docs/customization.md).

## Template structure

```
.claude/
  CLAUDE.md          # project-specific docs
  settings.json      # pre-seeded permissions
  .gitignore         # ignores settings.local.json
  commands/          # project slash commands (scaffold)
  agents/            # project subagents (scaffold)
  skills/            # project skills (scaffold)
```

## Placeholders

See [docs/placeholders.md](docs/placeholders.md) for the full reference.

Required: `{{project_name}}`, `{{description}}`, `{{language}}`, `{{framework}}`, `{{testing}}`, `{{install_cmd}}`, `{{dev_cmd}}`, `{{build_cmd}}`, `{{test_cmd}}`, `{{lint_cmd}}`

Optional (wrapped in `<!-- optional:name --> … <!-- /optional -->`): `{{deployment}}`, `{{rules}}`, `{{stack}}`

## Comparison

| Feature                       | `/init` built-in | `claude-code-templates` | `claude-init` |
|-------------------------------|:---:|:---:|:---:|
| Scaffolds full `.claude/`     | ✗   | ✓   | ✓   |
| Per-stack presets             | ✗   | ✓   | ✗   |
| Single hackable template      | n/a | ✗   | ✓   |
| Pre-seeded permissions        | ✗   | partial | ✓ |
| Required/optional placeholders| ✗   | ✗   | ✓   |
| Standalone CLI (no Claude)    | ✗   | ✓   | ✓   |
| Upgrade-safe user forks       | ✗   | partial | ✓ |
| NPM dependency                | ✗   | ✓   | ✗   |

## Contributing

PRs welcome. Keep the template small. New examples go in `examples/<stack>/`.

## License

MIT — see [LICENSE](LICENSE).
