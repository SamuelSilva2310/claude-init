#!/usr/bin/env bash
# Smoke test for claude-init install.sh
# Verifies the installer lays down the slash command and template into a fresh CLAUDE_HOME.
# Uses the local checkout (file://) so it does not depend on a published GitHub repo.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_HOME="$(mktemp -d -t claude-init-smoke.XXXXXX)"

cleanup() { rm -rf "$TMP_HOME"; }
trap cleanup EXIT

pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; exit 1; }

echo "==> claude-init smoke test"
echo "    repo:  $REPO_ROOT"
echo "    home:  $TMP_HOME"

# install.sh clones $REPO_URL — point it at the local checkout
CLAUDE_INIT_REPO="file://$REPO_ROOT" \
CLAUDE_INIT_BRANCH="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)" \
CLAUDE_HOME="$TMP_HOME" \
  bash "$REPO_ROOT/install.sh" >/dev/null

[ -f "$TMP_HOME/bin/claude-init" ] \
  && pass "cli binary installed" \
  || fail "missing $TMP_HOME/bin/claude-init"

[ -x "$TMP_HOME/bin/claude-init" ] \
  && pass "cli binary is executable" \
  || fail "$TMP_HOME/bin/claude-init not executable"

[ -f "$TMP_HOME/commands/claude-init.md" ] \
  && pass "slash command installed" \
  || fail "missing $TMP_HOME/commands/claude-init.md"

[ -d "$TMP_HOME/templates/claude-init/default" ] \
  && pass "shipped template dir present" \
  || fail "missing $TMP_HOME/templates/claude-init/default"

[ -d "$TMP_HOME/templates/user" ] \
  && pass "user template dir created" \
  || fail "missing $TMP_HOME/templates/user"

[ -f "$TMP_HOME/templates/claude-init/default/CLAUDE.md" ] \
  && pass "template CLAUDE.md installed" \
  || fail "missing template CLAUDE.md"

[ -f "$TMP_HOME/templates/claude-init/default/settings.json" ] \
  && pass "template settings.json installed" \
  || fail "missing template settings.json"

# settings.json must parse
python3 -c "import json,sys; json.load(open('$TMP_HOME/templates/claude-init/default/settings.json'))" \
  && pass "settings.json is valid JSON" \
  || fail "settings.json failed to parse"

# Scaffold dirs preserved
for d in commands agents skills; do
  [ -d "$TMP_HOME/templates/claude-init/default/$d" ] \
    && pass "scaffold dir present: $d" \
    || fail "missing scaffold dir: $d"
done

# CLI smoke
"$TMP_HOME/bin/claude-init" --version >/dev/null \
  && pass "cli --version works" \
  || fail "cli --version failed"

CLAUDE_HOME="$TMP_HOME" "$TMP_HOME/bin/claude-init" template list >/dev/null \
  && pass "cli template list works" \
  || fail "cli template list failed"

# Re-run must succeed (idempotency, with backup)
CLAUDE_INIT_REPO="file://$REPO_ROOT" \
CLAUDE_INIT_BRANCH="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)" \
CLAUDE_HOME="$TMP_HOME" \
  bash "$REPO_ROOT/install.sh" >/dev/null \
  && pass "re-run succeeds (idempotent)" \
  || fail "re-run failed"

ls "$TMP_HOME/templates/claude-init/" | grep -q 'default.bak.' \
  && pass "previous template backed up" \
  || fail "expected default.bak.* after re-run"

echo "==> all checks passed"
