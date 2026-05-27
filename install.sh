#!/usr/bin/env bash
# claude-init installer
# Idempotent — safe to re-run.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/SamuelSilva2310/claude-init/main/install.sh | bash
#
# Flags (set via environment variables when piping to bash):
#   CLAUDE_INIT_ADD_TO_PATH=1   Auto-append PATH export to detected shell rc (with backup).
#                                Default: print instructions only.
#   CLAUDE_INIT_REPO=<url>      Override repo URL.
#   CLAUDE_INIT_BRANCH=<name>   Override branch (default: main).
#   CLAUDE_HOME=<path>          Override install root (default: ~/.claude).

set -euo pipefail

REPO_URL="${CLAUDE_INIT_REPO:-https://github.com/SamuelSilva2310/claude-init.git}"
BRANCH="${CLAUDE_INIT_BRANCH:-main}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
ADD_TO_PATH="${CLAUDE_INIT_ADD_TO_PATH:-0}"

BIN_DIR="$CLAUDE_HOME/bin"
COMMANDS_DIR="$CLAUDE_HOME/commands"
TEMPLATES_DIR="$CLAUDE_HOME/templates"
SHIPPED_TEMPLATES_DIR="$TEMPLATES_DIR/claude-init"
USER_TEMPLATES_DIR="$TEMPLATES_DIR/user"
TEMPLATE_DEST="$SHIPPED_TEMPLATES_DIR/default"
TMP_DIR="$(mktemp -d -t claude-init.XXXXXX)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

log()  { printf '  \033[36m%s\033[0m %s\n' "$1" "$2"; }
warn() { printf '  \033[33m%s\033[0m %s\n' "WARN" "$1"; }
die()  { printf '  \033[31m%s\033[0m %s\n' "ERROR" "$1" >&2; exit 1; }

command -v git >/dev/null 2>&1 || die "git not found in PATH"

log "==>" "Installing claude-init"
log "src" "$REPO_URL (branch: $BRANCH)"
log "dst" "$CLAUDE_HOME"

mkdir -p "$BIN_DIR" "$COMMANDS_DIR" "$SHIPPED_TEMPLATES_DIR" "$USER_TEMPLATES_DIR"

log "clone" "fetching repo"
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TMP_DIR/repo" >/dev/null 2>&1 \
  || die "clone failed: $REPO_URL"

# CLI binary
if [ -f "$BIN_DIR/claude-init" ]; then
  warn "overwriting existing $BIN_DIR/claude-init"
fi
cp "$TMP_DIR/repo/bin/claude-init" "$BIN_DIR/claude-init"
chmod +x "$BIN_DIR/claude-init"
log "ok" "cli -> $BIN_DIR/claude-init"

# Slash command
if [ -f "$COMMANDS_DIR/claude-init.md" ]; then
  warn "overwriting existing $COMMANDS_DIR/claude-init.md"
fi
cp "$TMP_DIR/repo/commands/claude-init.md" "$COMMANDS_DIR/claude-init.md"
log "ok" "command -> $COMMANDS_DIR/claude-init.md"

# Shipped template
if [ -d "$TEMPLATE_DEST" ]; then
  BACKUP="$TEMPLATE_DEST.bak.$(date +%Y%m%d%H%M%S)"
  warn "existing shipped template found, backing up to $BACKUP"
  mv "$TEMPLATE_DEST" "$BACKUP"
fi
cp -R "$TMP_DIR/repo/templates/default" "$TEMPLATE_DEST"
log "ok" "template -> $TEMPLATE_DEST"

# Legacy migration warning
LEGACY="$TEMPLATES_DIR/.claude-template"
if [ -d "$LEGACY" ]; then
  warn "found legacy template at $LEGACY (pre-v0.1 layout)"
  warn "it is no longer used. Move customizations to $USER_TEMPLATES_DIR/<name>/ and delete the legacy dir."
fi

# PATH setup — source the shared helper from the cloned repo.
# shellcheck source=scripts/lib/path-setup.sh
. "$TMP_DIR/repo/scripts/lib/path-setup.sh"

cat <<EOF

claude-init installed.

CLI:    $BIN_DIR/claude-init
Slash:  /claude-init  (inside Claude Code)
Tpl:    $TEMPLATE_DEST
EOF

PATH_SETUP_AUTO_ADD="$ADD_TO_PATH" path_setup_run

if [ "$ADD_TO_PATH" != "1" ] && ! path_setup_bin_on_path; then
  printf '\n      Or re-run the installer with auto-append:\n'
  printf '        \033[36mcurl -fsSL https://raw.githubusercontent.com/SamuelSilva2310/claude-init/main/install.sh | CLAUDE_INIT_ADD_TO_PATH=1 bash\033[0m\n'
fi

cat <<EOF

Next:
  cd <your project>
  claude-init init           # or /claude-init inside Claude Code

Docs: $REPO_URL
EOF
