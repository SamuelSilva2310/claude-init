# Customization

## Where templates live

After `install.sh` runs, your `~/.claude/` looks like:

```
~/.claude/
├── bin/
│   └── claude-init                  # CLI binary
├── commands/
│   └── claude-init.md               # slash command
└── templates/
    ├── claude-init/                 # SHIPPED — installer overwrites this. Do not hand-edit.
    │   └── default/
    └── user/                        # YOURS — installer never touches this. Edit freely.
        └── <your-forks>/
```

Rule of thumb:
- **`templates/claude-init/`** is owned by the installer. Anything you put here may be clobbered on upgrade.
- **`templates/user/`** is owned by you. Fork shipped templates into here for safe edits.

## Use a different template

`/claude-init` and `claude-init init` resolve templates in this order:

1. `~/.claude/templates/user/<name>/` — user fork (wins if `<name>` provided)
2. `~/.claude/templates/claude-init/<name>/` — shipped (wins if `<name>` provided)
3. `~/.claude/templates/user/default/` — user's default
4. `~/.claude/templates/claude-init/default/` — shipped default
5. `./.claude-template/` — per-project override
6. `./templates/.claude-template/` — repo-bundled override

First match wins.

Check what resolves for a given name:

```bash
claude-init template path           # default
claude-init template path minimal   # by name
```

## List your templates

```bash
claude-init template list
```

Shows both shipped and user templates with their paths.

## Per-project override

Drop your own template at `./.claude-template/` inside a project. It wins over global templates.

## Fork the default for editing

```bash
claude-init template fork default my-custom
claude-init template edit my-custom    # opens in $EDITOR
```

This copies `~/.claude/templates/claude-init/default` to `~/.claude/templates/user/my-custom`. Safe across upgrades.

Then use it:

```bash
claude-init init --template my-custom
```

Or inside Claude Code:

```text
/claude-init my-custom
```

## Modify the shipped default (not recommended)

If you must, edit `~/.claude/templates/claude-init/default/` directly. **Warning:** running `install.sh` again will overwrite your changes (with a `.bak.<timestamp>` backup).

Prefer forking — see above.

## Add a new section

To add a new section to the generated `CLAUDE.md`:

1. Edit `templates/default/CLAUDE.md` (in the repo) or your fork.
2. Use `{{placeholders}}` if it needs dynamic content.
3. If the section is optional, wrap it:
   ```markdown
   <!-- optional:my_section -->
   ## My Section

   {{my_section_value}}
   <!-- /optional -->
   ```
4. Register the new placeholder in [commands/claude-init.md](../commands/claude-init.md) Step 5 and in [placeholders.md](placeholders.md).

## Tighten `settings.json`

Open `templates/default/settings.json` and edit `permissions.allow` / `permissions.deny`.

Rules of thumb:
- Anything **read-only and obvious** can go in `allow` (`git status`, `ls`, `rg`, `cat`).
- Anything **destructive** goes in `deny` (`rm -rf`, `git push -f`, `git reset --hard`).
- Anything **side-effectful but useful** stays out of both — Claude Code will prompt the user once.

The slash command may add stack-specific entries on top during scaffold (e.g. `Bash(pnpm:*)` for Node projects).

## Disable scaffold subdirs

If you do not want empty `commands/`, `agents/`, `skills/` directories in target projects, delete the corresponding `.gitkeep` files in your template. The copy step will skip them.

## Develop on claude-init itself

If you are hacking on this repo, symlink-install instead of copying:

```bash
./scripts/dev-install.sh
```

This points `~/.claude/bin/claude-init`, `~/.claude/commands/claude-init.md`, and `~/.claude/templates/claude-init/default` at the repo. Edits go live immediately.

Undo:

```bash
./scripts/dev-uninstall.sh
```
