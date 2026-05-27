# /claude-init

## Purpose

Scaffold a clean `.claude/` workspace for the current project. This command is a **thin AI front-end** over the `claude-init` CLI. It does the fuzzy work — reading READMEs, inferring frameworks, drafting content — and then hands a config to the deterministic CLI for the actual write.

If the CLI binary is missing, fall back to the legacy declarative flow (see §Fallback below).

---

## Step 1 — Locate the CLI

The CLI may be on `PATH`, or just sitting at its install location. Try these in order and use the **first** one that prints a version. Remember the resolved command for the rest of the flow; refer to it below as `$CLI`.

```bash
# 1. on PATH
command -v claude-init && claude-init --version

# 2. CLAUDE_HOME override
[ -n "$CLAUDE_HOME" ] && "$CLAUDE_HOME/bin/claude-init" --version

# 3. default install path
"$HOME/.claude/bin/claude-init" --version
```

- If any succeed → continue from Step 2 using that command as `$CLI`.
- If all fail → jump to **Fallback (no CLI)** at the bottom.

If `claude-init` was not on `PATH` but option 2 or 3 worked, mention to the user at the end (Step 8):

> Add `~/.claude/bin` to your `PATH` for direct CLI use outside Claude Code:
> ```bash
> echo 'export PATH="$HOME/.claude/bin:$PATH"' >> ~/.zshrc  # or ~/.bashrc
> ```

---

## Step 2 — Inspect the project

Read what is in the current directory. Look at:

- `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` / `Gemfile` → language + commands
- `pnpm-lock.yaml` / `yarn.lock` / `uv.lock` / `poetry.lock` → package manager
- `tsconfig.json` → TypeScript vs JavaScript
- `README.md` → project description (first paragraph), key concepts
- `Makefile`, top-level scripts → custom commands
- `.env.example` → environment variables
- Top-level directory layout → architecture sketch

Build a **draft** of every required and optional value defined in `~/.claude/templates/claude-init/default/CLAUDE.md` placeholders.

Required: `project_name`, `description`, `language`, `framework`, `testing`, `install_cmd`, `dev_cmd`, `build_cmd`, `test_cmd`, `lint_cmd`.

Optional: `deployment`, `rules`, `stack`.

---

## Step 3 — Confirm with the user (single turn)

Show the user the draft in compact form. Ask only what is missing or ambiguous. **Adapt questions to the stack.** Examples:

- Next.js + API routes detected → "App router or pages? Server actions or REST?"
- Monorepo detected (`pnpm-workspace.yaml`) → "Scaffold per-package CLAUDE.md too? (out of scope for v1 — but flag for follow-up)"
- Multiple Go `cmd/*` dirs → "List all entrypoints in Architecture?"
- `.env.example` present → "Auto-fill Environment section from .env.example?"

Be terse. Pre-fill defaults. Use a single message; do not ping-pong.

---

## Step 4 — Handle existing `.claude/`

If `./.claude/` exists:

- Inspect what is there.
- Ask user: **overwrite** (CLI will back up to `.claude.bak.<timestamp>`), **merge** (keep user-created files, refresh templated files), or **cancel**.
- For overwrite: just continue to Step 5; CLI handles the backup with `--force`.
- For merge: warn the user this is not yet automated in the CLI. Either overwrite + manually re-add user files, or cancel.

---

## Step 5 — Write the config

Write the gathered answers to a temp file:

```json
{
  "template": "default",
  "required": {
    "project_name": "...",
    "description": "...",
    "language": "...",
    "framework": "...",
    "testing": "...",
    "install_cmd": "...",
    "dev_cmd": "...",
    "build_cmd": "...",
    "test_cmd": "...",
    "lint_cmd": "..."
  },
  "optional": {
    "deployment": "...",
    "rules": "...",
    "stack": null
  }
}
```

Path: `/tmp/claude-init.config.json` (overwrite freely).

Optional values may be `null` or `""` — the CLI will strip their template blocks.

---

## Step 6 — Run the CLI

Use `$CLI` from Step 1 (the resolved path).

```bash
"$CLI" init --from-config /tmp/claude-init.config.json --force
```

The CLI handles:
- Backup of existing `.claude/`
- Copy template → `./.claude/`
- Placeholder substitution
- Optional block stripping
- Validation (no unresolved required placeholders, JSON parses)
- Failure exits non-zero with a clear message — surface it to the user verbatim.

---

## Step 7 — Augment (the AI value-add)

After the CLI succeeds, **enrich** the generated files. This is what justifies running the slash command over the CLI directly.

### 7a — `CLAUDE.md` content

- Replace the placeholder `## Architecture` tree with a real one. Use `ls`/`tree` output. Add a one-line purpose per top-level dir.
- Populate `## Key Files`. Pick files that matter: composition roots, schema/migration sources, middleware, route registries. Skip boilerplate.
- Draft `## Gotchas`. Scan the source for non-obvious patterns: custom error wrappers, env-dependent behavior, ordering dependencies, magic strings. This is the most valuable section — invest effort here.
- Populate `## Environment` from `.env.example` if present.
- Refine `## Code Style` with patterns actually observed in the repo (e.g. "all services return `Result<T,E>`", "no default exports in routes/").

Edit `./.claude/CLAUDE.md` to insert these. Preserve existing structure and the maintenance comment at the bottom.

### 7b — `settings.json` stack-specific allow entries

Read `./.claude/settings.json`. Add safe, stack-specific entries to `permissions.allow` based on what was detected:

| Detected | Suggested `allow` additions |
|---|---|
| pnpm | `Bash(pnpm list:*)`, `Bash(pnpm outdated:*)`, `Bash(pnpm why:*)` |
| npm | `Bash(npm ls:*)`, `Bash(npm outdated:*)` |
| uv | `Bash(uv tree:*)`, `Bash(uv pip list:*)`, `Bash(uv run pytest:*)` |
| poetry | `Bash(poetry show:*)`, `Bash(poetry run pytest:*)` |
| Docker present | `Bash(docker ps:*)`, `Bash(docker logs:*)` |
| GitHub Actions | `Bash(gh run list:*)`, `Bash(gh pr list:*)`, `Bash(gh issue list:*)` |
| Terraform | `Bash(terraform plan:*)`, `Bash(terraform show:*)` |
| Migrations (drizzle/alembic/sqlx) | `Bash(*:migrate:status)`, `Bash(*:migrate:up)` |

Add corresponding `deny` entries for the destructive cousins (e.g. `Bash(pnpm publish:*)`, `Bash(terraform apply:*)`, `Bash(*:migrate:reset)`).

Do not blindly allow `Bash(<tool>:*)` — favor verb-scoped entries.

---

## Step 8 — Final report

Show the user:

1. Generated file tree.
2. Template source path used (`claude-init template path`).
3. Summary table: what was **inferred** vs what was **asked**.
4. Augmentations made (e.g. "added 5 entries to settings.json allow", "drafted 3 gotchas").
5. Suggested next steps:
   - Review `## Gotchas` — these were AI-drafted, verify accuracy.
   - Commit `.claude/` to the repo.

---

## Fallback (no CLI)

If `claude-init` is not on PATH, perform the steps the CLI would have run, manually:

1. Resolve template — prefer `~/.claude/templates/user/default/`, fall back to `~/.claude/templates/claude-init/default/`, then `./.claude-template/`, then `./templates/.claude-template/`.
2. Ask the user for required and optional values (same prompts as Step 3).
3. Confirm `.claude/` handling.
4. Copy the template into `./.claude/`.
5. Substitute placeholders:
   - For each required placeholder `{{name}}` → replace with value across `*.md`, `*.json`, `*.yaml`, `*.yml`, `*.txt`.
   - For each optional block `<!-- optional:name --> … <!-- /optional -->`:
     - Value provided → strip markers, substitute `{{name}}`, keep content.
     - Value missing → remove block entirely (markers + content).
6. Validate:
   - No `{{required_name}}` token remains.
   - No `<!-- optional:* -->` or `<!-- /optional -->` marker remains.
   - JSON files parse.
7. Apply Step 7 augmentations.
8. Report (Step 8).

Suggest the user install the CLI at the end:
> Install `claude-init` for faster, reproducible scaffolds: `curl -fsSL https://raw.githubusercontent.com/SamuelSilva2310/claude-init/main/install.sh | bash`

---

## Behavioral rules

- Prefer deterministic output via the CLI; do not duplicate its mechanical work.
- Ask in a single turn. Pre-fill detected defaults aggressively.
- Surface CLI errors verbatim — do not paraphrase.
- Preserve user-created files in `.claude/` (mention them explicitly in the report if any exist).
- Project `CLAUDE.md` documents what is unique to **this** project. Generic engineering rules live in `~/.claude/CLAUDE.md` — do not duplicate them.
- Augmentations in Step 7 must be conservative. Never invent gotchas; only draft from observed code patterns.
