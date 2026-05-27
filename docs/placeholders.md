# Placeholders

`claude-init` uses simple double-curly placeholders that get substituted at scaffold time.

## Required

These must resolve. If any is missing, Step 7 validation fails and `/claude-init` aborts.

| Placeholder      | Example                       | Source                                  |
|------------------|-------------------------------|-----------------------------------------|
| `{{project_name}}` | `my-app`                    | Repo dir name or user prompt            |
| `{{description}}`  | `Internal billing service`  | User prompt                             |
| `{{language}}`     | `TypeScript`                | Detected from `package.json` etc.       |
| `{{framework}}`    | `Next.js`                   | Detected from dependencies or prompt    |
| `{{testing}}`      | `Vitest`                    | Detected from dependencies or prompt    |
| `{{install_cmd}}`  | `pnpm install`              | Inferred from lockfile / `Makefile`     |
| `{{dev_cmd}}`      | `pnpm dev`                  | Inferred from `scripts.dev`             |
| `{{build_cmd}}`    | `pnpm build`                | Inferred from `scripts.build`           |
| `{{test_cmd}}`     | `pnpm test`                 | Inferred from `scripts.test`            |
| `{{lint_cmd}}`     | `pnpm lint`                 | Inferred from `scripts.lint`            |

## Optional

Wrapped in HTML comment markers. If the value is missing or empty, the **entire block** (markers + content) is removed at scaffold time.

| Placeholder      | Block name | Used in template section |
|------------------|------------|--------------------------|
| `{{deployment}}` | `deployment` | Stack list line          |
| `{{rules}}`      | `rules`      | `## Project Rules` section |
| `{{stack}}`      | `stack`      | Optional consolidated stack line |

### Optional block syntax

```markdown
<!-- optional:rules -->
## Project Rules

{{rules}}
<!-- /optional -->
```

Behavior:
- Value present → strip the two markers, substitute placeholder, keep content.
- Value missing → delete from `<!-- optional:rules -->` through `<!-- /optional -->` inclusive.

## Validation rules

1. After substitution, no `{{…}}` token from the **required** list may remain.
2. No `<!-- optional:* -->` or `<!-- /optional -->` marker may remain.
3. JSON files must parse.

A failure aborts `/claude-init` with the offending file path.

## Adding new placeholders

1. Add the placeholder to `templates/default/CLAUDE.md` (or any template file under `.md` / `.json` / `.yaml` / `.yml` / `.txt`).
2. Add it to this doc under **Required** or **Optional**.
3. Add it to the matching list in [commands/claude-init.md](../commands/claude-init.md) Step 5.
4. If optional, wrap the surrounding block in `<!-- optional:<name> --> … <!-- /optional -->`.
