# {{project_name}}

{{description}}

## Stack

- Language: {{language}}
- Framework: {{framework}}
- Testing: {{testing}}
<!-- optional:deployment -->
- Deployment: {{deployment}}
<!-- /optional -->

## Commands

| Command | Description |
|---------|-------------|
| `{{install_cmd}}` | Install dependencies |
| `{{dev_cmd}}` | Start dev server |
| `{{build_cmd}}` | Production build |
| `{{test_cmd}}` | Run tests |
| `{{lint_cmd}}` | Lint / format |

## Architecture

```
<!-- Fill with actual repo tree. Keep one line per directory with purpose. -->
{{project_name}}/
  src/      # source
  tests/    # tests
```

## Key Files

<!-- List files Claude must know about. Remove section if none. -->
- `<path>` — `<purpose>`

## Code Style

<!-- Project-specific conventions only. Generic style lives in global CLAUDE.md. -->
- `<convention unique to this repo>`

## Environment

<!-- Required env vars. Remove section if none. -->
- `<VAR_NAME>` — `<purpose>`

## Testing

- `{{test_cmd}}` — runs full suite
<!-- Add testing patterns or scopes unique to this project. -->

## Gotchas

<!-- Non-obvious patterns, quirks, ordering deps. The most valuable section. -->
- `<gotcha>`

<!-- optional:rules -->
## Project Rules

{{rules}}
<!-- /optional -->

---

<!--
Maintenance:
- Keep entries one line each.
- Document patterns unique to THIS project. Generic engineering rules belong in ~/.claude/CLAUDE.md.
- Update when conventions evolve.
-->
