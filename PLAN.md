# PLAN — claude-init full solution

Status: design locked. Implementation pending.

This document is the source of truth for the v1 architecture. Anything in `HANDOFF.md` that conflicts with this file is superseded.

---

## 1. Vision

`claude-init` is a CLI scaffolder for `.claude/` directories. It ships with a slash command that drives it via natural-language dialog inside Claude Code.

One-liner: **The `create-next-app` of Claude Code configuration, with a slash-command front-end.**

Design principles:
- **CLI is the source of truth.** All mechanical work — copy, substitute, validate — happens in the CLI binary.
- **Slash command is a thin AI front-end.** It adapts questions to the project, drafts rich content, and tunes settings — then hands off to the CLI for the actual write.
- **Templates are forkable, upgrade-safe.** Shipped templates live separately from user templates so `claude-init upgrade` never clobbers user edits.
- **Optional features are opt-in.** Hooks, MCP stubs, multi-template — none of these belong in the default scaffold.
- **Generic engineering rules belong in `~/.claude/CLAUDE.md`.** The project template documents only what is unique to the repo.

---

## 2. Architecture

```
┌────────────────────────────────────────────────────────┐
│ Slash command   ~/.claude/commands/claude-init.md      │
│   - dialog with user                                    │
│   - smart detection (READMEs, imports, framework)       │
│   - drafts content for fuzzy sections                   │
│   - tunes settings.json based on stack                  │
│   - writes /tmp/claude-init.config.json                 │
│   - shells out: claude-init init --from-config <file>   │
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────┐
│ CLI binary      ~/.claude/bin/claude-init (symlinked)   │
│   - copy template                                       │
│   - substitute placeholders                             │
│   - strip optional blocks                               │
│   - validate output                                     │
│   - template management (list / edit / fork / path)     │
│   - upgrade, doctor                                     │
│   - usable standalone (no LLM required)                 │
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────┐
│ Templates                                               │
│   ~/.claude/templates/claude-init/default/  (shipped)   │
│   ~/.claude/templates/user/*                (forks)     │
└────────────────────────────────────────────────────────┘
```

Division of labor — never crossed:

| Concern | CLI | Slash command |
|---|---|---|
| Copy files | ✓ | — |
| Placeholder substitution | ✓ | — |
| Optional block stripping | ✓ | — |
| Validation | ✓ | — |
| Template management | ✓ | — |
| Mechanical prompts (`read -p`) | ✓ | — |
| Detect language from `package.json` | ✓ | — |
| Read README and draft description | — | ✓ |
| Infer framework when ambiguous | — | ✓ |
| Populate `## Gotchas` from source scan | — | ✓ |
| Tune `settings.json` per stack | — | ✓ |
| Custom questions per detected stack | — | ✓ |

CLI alone produces a correct, generic scaffold. Slash command produces a correct, tailored scaffold.

---

## 3. Directory layout

### Repo layout

```
claude-init/
├── README.md
├── LICENSE
├── PLAN.md                          # this file
├── HANDOFF.md                       # legacy hand-off, kept for history
├── install.sh                       # curl|bash installer
├── bin/
│   └── claude-init                  # CLI binary (bash)
├── commands/
│   └── claude-init.md               # slash command source
├── templates/
│   └── default/                     # shipped default template
│       ├── CLAUDE.md
│       ├── settings.json
│       ├── .gitignore
│       ├── commands/.gitkeep
│       ├── agents/.gitkeep
│       └── skills/.gitkeep
├── scripts/
│   ├── dev-install.sh               # symlink-install from checkout
│   └── dev-uninstall.sh             # undo dev-install
├── docs/
│   ├── placeholders.md
│   ├── customization.md
│   ├── cli.md                       # CLI reference
│   └── architecture.md              # mirrors PLAN §2
├── examples/
│   ├── node/CLAUDE.md
│   ├── python/CLAUDE.md
│   └── go/CLAUDE.md
└── tests/
    ├── smoke.sh                     # installer smoke test
    ├── cli.sh                       # CLI subcommand tests
    └── fixtures/                    # synthetic projects for init tests
        ├── node/
        ├── python/
        └── go/
```

### Installed layout (`~/.claude/`)

```
~/.claude/
├── bin/
│   └── claude-init                  # symlink to repo or copy from install.sh
├── commands/
│   └── claude-init.md
└── templates/
    ├── claude-init/                 # owned by installer — NEVER hand-edit
    │   └── default/                 # shipped template (was .claude-template)
    └── user/                        # owned by user — installer NEVER touches
        └── <your-forks>/
```

Key invariant: `templates/claude-init/` is overwritten on upgrade. `templates/user/` is sacred.

---

## 4. CLI surface

Single binary at `bin/claude-init`. Bash. Subcommand dispatch.

```
claude-init <command> [args] [flags]

Commands:
  init                        Scaffold .claude/ in current project
  template list               Show all templates with source
  template path [name]        Print resolved directory for template
  template edit [name]        Open template in $EDITOR
  template fork <src> <dst>   Copy a template into user/ for editing
  upgrade                     Re-fetch shipped templates from repo
  doctor                      Diagnose install state
  help [command]              Show help (or subcommand help)
  version                     Print version

Global flags:
  -h, --help                  Show help
  -V, --version               Print version
  -v, --verbose               Verbose output
  -q, --quiet                 Suppress non-error output

init flags:
  --template <name>           Template to use (default: "default")
  --dry-run                   Print plan, no writes
  --force                     Overwrite without prompt
  --non-interactive           Fail instead of prompting
  --from-config <file>        Read answers from JSON

template fork flags:
  --from-user                 Source is a user template, not a shipped one
```

### Resolution order for `--template <name>`

1. `~/.claude/templates/user/<name>/` — user-owned, wins if present
2. `~/.claude/templates/claude-init/<name>/` — shipped
3. `./.claude-template/` — per-project override (no `<name>` needed)
4. `./templates/.claude-template/` — repo-bundled override

First match wins. `claude-init template path <name>` prints which one resolved.

### `--from-config` schema

`/tmp/claude-init.config.json`:

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

Slash command writes this file, CLI reads it, no prompts shown.

---

## 5. Slash command flow

`/claude-init` inside Claude Code:

1. **Inspect repo** — read `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml`. Run `ls`, scan `README.md`.
2. **Draft an interpretation** — language, framework, commands, project description.
3. **Confirm with user in one turn** — "I see X. Look right? Anything to change?"
4. **Ask only what is genuinely missing or ambiguous** — adapted to stack (e.g. monorepo branch, Playwright detection, etc.).
5. **Write config** — `/tmp/claude-init.config.json` with all answers.
6. **Call CLI** — `claude-init init --from-config /tmp/claude-init.config.json`.
7. **Augment output** — after CLI writes baseline `.claude/`:
   - Append drafted `## Gotchas`, `## Key Files`, `## Architecture` content to `CLAUDE.md`.
   - Patch `settings.json` `permissions.allow` with stack-specific safe entries.
   - Add detected env vars to `## Environment`.
8. **Report** — file tree, what was inferred vs. asked, next steps.

Slash command never duplicates CLI logic. If `claude-init` binary not found, falls back to current declarative mode and warns user.

---

## 6. Template structure

`templates/default/CLAUDE.md` stays minimal — section stubs only. AI fills the rich content via Step 7 augmentation above.

Sections:
- `# {{project_name}}` + `{{description}}`
- `## Stack` (language, framework, testing, optional deployment)
- `## Commands` (table of install/dev/build/test/lint)
- `## Architecture` (one line per top-level dir)
- `## Key Files` (stub)
- `## Code Style` (stub)
- `## Environment` (stub)
- `## Testing` (test cmd + patterns)
- `## Gotchas` (stub — the most valuable section, AI populates)
- `## Project Rules` (optional block)

`templates/default/settings.json` ships a safe baseline:
- `allow`: read-only obvious (`git status`, `ls`, `rg`, `find`, `cat`, `pwd`, `tree`)
- `deny`: destructive (`rm -rf`, `git push -f`, `git reset --hard`, `git clean -f`, `git branch -D`)
- `ask`: empty (slash command may populate per stack)

---

## 7. Placeholder system

Unchanged from current spec, formalized:

**Required** (validation fails if any unresolved):
- `project_name`, `description`, `language`, `framework`, `testing`
- `install_cmd`, `dev_cmd`, `build_cmd`, `test_cmd`, `lint_cmd`

**Optional** (wrapped in `<!-- optional:NAME --> … <!-- /optional -->`):
- `deployment`, `rules`, `stack`

Substitution behavior:
- Required missing → CLI exits non-zero, lists offending file + placeholder.
- Optional missing → entire block removed (markers + content).
- Optional present → markers stripped, placeholder substituted, content kept.

Supported file extensions: `.md`, `.json`, `.yaml`, `.yml`, `.txt`.

JSON-aware substitution: for `.json` files, escape values with `jq` or equivalent — never raw string-replace.

---

## 8. Phased delivery

### Phase 1 — foundation (this session, target)

1. **Scrub personal data**
   - `KJOO_BQ_SANDBOX` → `ACME_BQ_SANDBOX` in [examples/python/CLAUDE.md:55](examples/python/CLAUDE.md#L55)
   - ~~`<owner>` / `ssilva` left as TODO comments pending namespace decision~~ (resolved → SamuelSilva2310)
   - `Samuel Silva` in LICENSE: keep (real copyright holder) unless instructed otherwise

2. **Restructure template install path**
   - Installer writes to `~/.claude/templates/claude-init/default/`
   - Update [install.sh:12](install.sh#L12), [commands/claude-init.md:84-87](commands/claude-init.md#L84-L87), [docs/customization.md:5-10](docs/customization.md#L5-L10), [tests/smoke.sh](tests/smoke.sh)

3. **Build CLI skeleton + template management**
   - Replace [bin/claude-init](bin/claude-init) stub with real dispatcher
   - Subcommands: `help`, `version`, `template list|path|edit|fork`
   - Defer `init`, `upgrade`, `doctor` to Phase 2

4. **Dev install scripts**
   - `scripts/dev-install.sh` — symlinks repo into `~/.claude/`
   - `scripts/dev-uninstall.sh` — removes symlinks cleanly

5. **Update docs**
   - [docs/customization.md](docs/customization.md) — new dir layout, CLI commands
   - [README.md](README.md) — mention CLI, link to PLAN.md
   - New [docs/cli.md](docs/cli.md) — full CLI reference

### Phase 2 — engine (done)

6. ~~**CLI `init` subcommand**~~ — done. Three modes: interactive, `--non-interactive`, `--from-config`. Includes `--dry-run`, `--force`, perl-based substitution, JSON validation.
7. ~~**Slash command rewrite**~~ — done. New flow: detect → confirm in one turn → write config → call `claude-init init --from-config` → augment output.
8. ~~**CLI `upgrade`**~~ — done. Re-clones repo and overwrites bin/, commands/, shipped template only. `user/` untouched. Backs up previous shipped template.
9. ~~**CLI `doctor`**~~ — done. Validates install state, dependencies, PATH.
10. **Extend test suite** — deferred. `tests/cli.sh` per subcommand, fixtures in `tests/fixtures/`. Will add when CI is wired up (Phase 4).

### Phase 3 — distribution

11. **Release v0.1.0** — git tag, GitHub release. `install.sh` pins to tag.
12. **Homebrew tap** — `homebrew-claude-init` repo, formula.
13. **npm package** — `npx claude-init` for Node ecosystem reach.
14. **Plugin packaging** — wrap as Claude Code plugin for `/plugins` marketplace.

### Phase 4 — polish (after v0.1.0)

15. CI workflow (GitHub Actions) — runs `tests/smoke.sh` + `tests/cli.sh` on push.
16. `CHANGELOG.md` starting v0.1.0.
17. `CONTRIBUTING.md`.
18. Asciinema cast in README.
19. `examples/rust/CLAUDE.md`.
20. Multiple templates (`templates/minimal/` alongside `templates/default/`).
21. `.mcp.json` opt-in scaffold via `--with-mcp` flag.

---

## 9. Distribution

**v0.1.0 — `install.sh`** (current). Fix: pin to release tag, not `main`.

```bash
curl -fsSL https://raw.githubusercontent.com/SamuelSilva2310/claude-init/v0.1.0/install.sh | bash
```

**v0.2 — Homebrew tap**:
```bash
brew install SamuelSilva2310/claude-init/claude-init
```

**v0.3 — npm**:
```bash
npx claude-init init
```

**v0.4 — Claude Code plugin**:
```
/plugins install claude-init
```

Local dev (any phase):
```bash
./scripts/dev-install.sh
```

---

## 10. Testing

Local-first. No CI until Phase 4.

- `tests/smoke.sh` — installer end-to-end against local checkout
- `tests/cli.sh` (Phase 2) — every subcommand exercised
- `tests/fixtures/{node,python,go}/` — synthetic projects for `init` tests
- Manual: run `./scripts/dev-install.sh`, then `/claude-init` in a real project

CI added in Phase 4 when stability matters.

---

## 11. Out of scope

- Per-framework presets (use forks via `templates/user/`)
- MCP server installation
- Auto-install of Claude Code itself
- Multi-language CLI port (bash is sufficient)
- Backwards compat with `.claude-template` dir name after migration

---

## 12. Open decisions

Resolved:
- ~~**GitHub namespace**~~ — `github.com/SamuelSilva2310/claude-init`.

Still open before Phase 3 ships:
1. **LICENSE author** — keep `Samuel Silva` or anonymize to `claude-init contributors`.
2. **npm package name** — `claude-init` (likely squatted) vs `@samuelsilva2310/claude-init`.
3. **Homebrew tap repo name** — `homebrew-claude-init` vs `homebrew-tap` with multiple formulae.
