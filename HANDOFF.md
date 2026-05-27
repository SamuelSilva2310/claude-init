# HANDOFF — claude-init

> Hand-off document for the next AI model / human contributor.
> Self-contained. Assumes you have read nothing else in this repo yet.

---

## 1. What this project is

**`claude-init`** is a minimal, opinionated scaffolding tool for the `.claude/` configuration directory used by Anthropic's Claude Code CLI. It ships:

1. A **slash command** (`/claude-init`) that lives under `~/.claude/commands/claude-init.md` and is invoked by users inside any project.
2. A **template** at `templates/default/` (installed to `~/.claude/templates/.claude-template/`) that gets copied into `./.claude/` of the target project with placeholder substitution.

The slash command is currently **declarative markdown** — it describes the algorithm Claude Code itself should follow when invoked. There is no compiled binary yet. Optionally we may later add a thin bash CLI in `bin/claude-init` for non-Claude-Code workflows; see §6.

## 2. Goals and non-goals

**Goals**
- Make `.claude/` setup boring and one-step for any project.
- Encourage the convention: *project* `CLAUDE.md` = unique-to-this-repo only; *global* `~/.claude/CLAUDE.md` = engineering baseline.
- Pre-seed safe permissions so users do not get prompted for trivia (`git status`, `ls`, `rg`).
- Stay small and hackable. One template, no framework matrix.

**Non-goals**
- Not a per-framework preset library (that is `claude-code-templates`).
- Not an MCP server installer.
- Not a Claude Code plugin (could be packaged as one later; see §6).

## 3. Repo layout (current)

```
claude-init/
├── README.md                # public-facing pitch + install + comparison
├── LICENSE                  # MIT
├── HANDOFF.md               # this file
├── install.sh               # idempotent curl|bash installer
├── .gitignore               # repo-level
├── bin/
│   └── claude-init          # (planned) shell CLI alternative — see §6
├── commands/
│   └── claude-init.md       # the slash command source-of-truth
├── templates/
│   └── default/             # what gets copied into ./.claude/
│       ├── CLAUDE.md        # project-doc template, sections per templates.md
│       ├── settings.json    # pre-seeded permissions
│       ├── .gitignore       # ignores settings.local.json
│       ├── commands/.gitkeep
│       ├── agents/.gitkeep
│       └── skills/.gitkeep
├── docs/
│   ├── placeholders.md      # required vs optional reference
│   └── customization.md     # how to fork the template / point at another
├── examples/
│   ├── node/CLAUDE.md       # filled example for a Node project
│   ├── python/CLAUDE.md     # filled example for a Python project
│   └── go/CLAUDE.md         # filled example for a Go project
└── tests/
    └── smoke.sh             # idempotent smoke test for install.sh + scaffold
```

## 4. Conventions to preserve

These are deliberate. Do not "fix" them without reading the rationale.

1. **Placeholders are double-curly:** `{{project_name}}`. Simple regex substitution.
2. **Optional blocks** are wrapped in HTML comments:
   ```
   <!-- optional:rules -->
   ## Project Rules

   {{rules}}
   <!-- /optional -->
   ```
   - If value provided → strip markers, substitute placeholder, keep content.
   - If value missing → remove the entire block.
   - Required placeholders are **not** wrapped — unresolved ones cause Step 7 validation to fail.
3. **Template structure is preserved exactly** by `/claude-init` — including empty `commands/`, `agents/`, `skills/` dirs (kept alive by `.gitkeep`).
4. **`templates/default/.gitignore` ships inside the scaffold** so generated `.claude/` ignores `settings.local.json` in target repos.
5. **Project `CLAUDE.md` only documents what is unique to this repo.** Generic engineering rules belong in `~/.claude/CLAUDE.md`. The template body reflects this — do not pad it with generic "be safe / be minimal" prose.
6. **`settings.json` allow-list is read-only and obvious.** Anything mutating (`rm`, `git push -f`, `git reset --hard`) goes in `deny`. If you add to `allow`, the rule is: a hostile invocation of this command must not be able to harm the user's machine.

## 5. Status — what is done vs pending

### Done
- [x] Template files (`CLAUDE.md`, `settings.json`, `.gitignore`, scaffold dirs)
- [x] Slash command spec (`commands/claude-init.md`)
- [x] `README.md` with comparison table
- [x] `LICENSE` (MIT, 2026, Samuel Silva)
- [x] `install.sh` (idempotent, backs up existing template)
- [x] Repo-level `.gitignore`
- [x] Docs: `docs/placeholders.md`, `docs/customization.md`
- [x] Examples: `examples/{node,python,go}/CLAUDE.md`
- [x] `tests/smoke.sh`

### Pending (next model, pick what is in scope)

**P0 — before first publish**
- [ ] Replace `<owner>` / `ssilva` placeholders in [README.md](README.md) and [install.sh](install.sh) once the GitHub repo URL is final.
- [ ] Verify `install.sh` against an actual public clone URL (currently `https://github.com/ssilva/claude-init.git` — confirm the user owns that namespace or change it).
- [ ] Run `bash tests/smoke.sh` end-to-end and fix any failures.
- [ ] Decide: keep `~/.claude/templates/.claude-template/` (current convention, matches existing user setup) **or** rename to `~/.claude/templates/default/` (cleaner, matches `templates/default/` in repo). If you change it, update **both** `commands/claude-init.md` Step 3 **and** `install.sh`.

**P1 — polish**
- [ ] Add `examples/rust/CLAUDE.md`.
- [ ] Add a short `CONTRIBUTING.md`.
- [ ] Add a GIF or asciinema cast to `README.md` showing a `/claude-init` run.
- [ ] Add a CI workflow (`.github/workflows/test.yml`) that runs `tests/smoke.sh` on push.
- [ ] Add a small `CHANGELOG.md` starting at `v0.1.0`.

**P2 — optional extensions**
- [ ] **Bash CLI** (`bin/claude-init`): some users will want to scaffold without invoking Claude Code (e.g. CI bootstrap, dotfiles). Shell script that reproduces Step 4 + Step 5 deterministically. Read project type from `package.json` / `pyproject.toml`, prompt for missing fields, do the placeholder substitution, write to `./.claude/`. Keep it ≤200 LOC.
- [ ] **Claude Code plugin packaging**: wrap as a plugin in the official marketplace format so it can be installed via `/plugins`. Check the existing structure under `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/<plugin>/` for the layout.
- [ ] **`.mcp.json` template**: many `.claude/` setups also ship a project-level MCP config. Add a commented-out scaffold to `templates/default/`.
- [ ] Multiple templates: introduce `templates/minimal/` (CLAUDE.md only) alongside `templates/default/`, let `/claude-init <template-name>` pick.

## 6. Open design questions

These need a human decision before implementing — flag them, do not silently choose.

1. **Repo namespace.** The placeholder `ssilva` in `install.sh` is a guess. Confirm GitHub username / org before publishing.
2. **Template directory naming.** See P0 above — `.claude-template` vs `default`.
3. **Distribution channel.** Plain GitHub + curl installer (current), or also `npm` / `brew` / `pipx`? Start with curl-only.
4. **Slash command vs CLI primary.** Slash command is the v1 primary path. The CLI in `bin/` is P2 — only build it if there is user demand.

## 7. Testing approach

`tests/smoke.sh` exercises the happy path end-to-end:

1. Create a temp dir.
2. Run `install.sh` against the local checkout (not GitHub) by setting `CLAUDE_INIT_REPO=file://$PWD` and `CLAUDE_HOME=$tmp/claude-home`.
3. Verify `commands/claude-init.md` and `templates/.claude-template/CLAUDE.md` exist in the temp home.
4. Cleanup.

It does **not** test the placeholder substitution end-to-end because that step is executed by Claude Code reading the slash-command spec — not by code in this repo. If a real CLI gets built (P2), extend the test suite to cover substitution.

## 8. Files you will probably touch first

- [commands/claude-init.md](commands/claude-init.md) — the slash command spec. Source of truth for Steps 0–8.
- [templates/default/CLAUDE.md](templates/default/CLAUDE.md) — the project doc template.
- [templates/default/settings.json](templates/default/settings.json) — pre-seeded permissions.
- [install.sh](install.sh) — the installer; update repo URL here.
- [README.md](README.md) — public pitch; update repo URL here.

## 9. Out-of-scope reminders

- Do not bundle MCP server configurations into the default template.
- Do not add framework-specific presets to `templates/default/`. If you want presets, add a new sibling directory `templates/<preset>/`.
- Do not import the user's global `~/.claude/CLAUDE.md` content into the project template — it is intentionally separated.
- Do not auto-install Claude Code itself; assume the user already has it.

## 10. Quick start for the next model

```bash
cd ~/personal/dev/claude-init

# See what is here
tree -a -I '.git'

# Inspect the source of truth
cat commands/claude-init.md
cat templates/default/CLAUDE.md
cat templates/default/settings.json

# Run the smoke test
bash tests/smoke.sh

# Try the installer locally (does NOT need a published GitHub repo)
CLAUDE_INIT_REPO="file://$PWD" CLAUDE_HOME=/tmp/claude-init-test ./install.sh
ls /tmp/claude-init-test/commands /tmp/claude-init-test/templates/.claude-template

# Read the pending checklist in §5 of this file. Pick a P0 item.
```
