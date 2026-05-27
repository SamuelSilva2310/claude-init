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

# ── Regression: dev-install symlink + init ───────────────────────────────────
# Reproduces the bug where cp -R (BSD) reproduces a source symlink instead of
# copying contents, leaving ./.claude as a symlink and all subsequent steps as
# silent no-ops. The install.sh path uses a real copy, so this dev-install
# scenario must be exercised separately.
#
# Setup: a second CLAUDE_HOME where the shipped template is a symlink (mimicking
# what scripts/dev-install.sh produces).
DEV_HOME="$(mktemp -d -t claude-init-dev.XXXXXX)"
mkdir -p "$DEV_HOME/bin" "$DEV_HOME/templates/claude-init" "$DEV_HOME/templates/user"
cp "$REPO_ROOT/bin/claude-init" "$DEV_HOME/bin/claude-init"
chmod +x "$DEV_HOME/bin/claude-init"
ln -s "$REPO_ROOT/templates/default" "$DEV_HOME/templates/claude-init/default"

PROJECT="$(mktemp -d -t claude-init-proj.XXXXXX)"
CFG="$(mktemp -t claude-init-cfg.XXXXXX)"
cat > "$CFG" <<'JSON'
{
  "template": "default",
  "required": {
    "project_name": "t", "description": "t", "language": "t",
    "framework": "t", "testing": "t",
    "install_cmd": "t", "dev_cmd": "t", "build_cmd": "t",
    "test_cmd": "t", "lint_cmd": "t"
  },
  "optional": {}
}
JSON

(
  cd "$PROJECT"
  CLAUDE_HOME="$DEV_HOME" "$DEV_HOME/bin/claude-init" init \
    --from-config "$CFG" --force >/dev/null 2>&1
)

[ ! -L "$PROJECT/.claude" ] \
  && pass "./.claude is NOT a symlink under dev-install (cp -RL fix)" \
  || fail "./.claude is a symlink — cp -R bug regressed"

[ -d "$PROJECT/.claude" ] \
  && pass "./.claude is a real directory under dev-install" \
  || fail "./.claude is not a directory"

[ -f "$PROJECT/.claude/CLAUDE.md" ] \
  && pass "./.claude/CLAUDE.md exists" \
  || fail "./.claude/CLAUDE.md missing"

grep -q '{{' "$PROJECT/.claude/CLAUDE.md" \
  && fail "placeholders left unsubstituted in ./.claude/CLAUDE.md" \
  || pass "placeholders substituted (no {{...}} remaining)"

# Edits to ./.claude/CLAUDE.md must not propagate to the source template.
ORIG_TPL_HASH="$(shasum "$REPO_ROOT/templates/default/CLAUDE.md" | awk '{print $1}')"
printf '\nSCRATCH\n' >> "$PROJECT/.claude/CLAUDE.md"
NEW_TPL_HASH="$(shasum "$REPO_ROOT/templates/default/CLAUDE.md" | awk '{print $1}')"
[ "$ORIG_TPL_HASH" = "$NEW_TPL_HASH" ] \
  && pass "source template untouched by project edits" \
  || fail "source template mutated! shipped templates/default/CLAUDE.md was modified"

rm -rf "$DEV_HOME" "$PROJECT" "$CFG"

echo "==> all checks passed"
