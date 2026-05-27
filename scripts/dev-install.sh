#!/usr/bin/env bash
# claude-init dev installer — symlinks from the current checkout into ~/.claude/.
# Edit the repo, see changes live. Run dev-uninstall.sh to undo.
#
# Flags (environment variables):
#   CLAUDE_HOME=<path>          Override install root (default: ~/.claude).
#   CLAUDE_INIT_ADD_TO_PATH=1   Auto-append PATH export to detected shell rc.
#                                Default: print instructions only.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
BIN_DIR="$CLAUDE_HOME/bin"
COMMANDS_DIR="$CLAUDE_HOME/commands"
SHIPPED_DIR="$CLAUDE_HOME/templates/claude-init"
USER_DIR="$CLAUDE_HOME/templates/user"

log()  { printf '  \033[36m%s\033[0m %s\n' "$1" "$2"; }
warn() { printf '  \033[33m%s\033[0m %s\n' "WARN" "$1" >&2; }
die()  { printf '  \033[31m%s\033[0m %s\n' "ERROR" "$1" >&2; exit 1; }

log "==>" "dev-install claude-init from $REPO_ROOT"
log "dst" "$CLAUDE_HOME"

mkdir -p "$BIN_DIR" "$COMMANDS_DIR" "$SHIPPED_DIR" "$USER_DIR"

# Helper: replace a destination with a symlink. Backs up real files/dirs.
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    local backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
    warn "$dst exists, backing up to $backup"
    mv "$dst" "$backup"
  fi
  ln -s "$src" "$dst"
  log "link" "$dst -> $src"
}

link "$REPO_ROOT/bin/claude-init"         "$BIN_DIR/claude-init"
link "$REPO_ROOT/commands/claude-init.md" "$COMMANDS_DIR/claude-init.md"
link "$REPO_ROOT/templates/default"       "$SHIPPED_DIR/default"

# Sanity check
if [ ! -x "$BIN_DIR/claude-init" ]; then
  chmod +x "$REPO_ROOT/bin/claude-init"
fi

cat <<EOF

dev-install complete.

CLI:    $BIN_DIR/claude-init
Slash:  $COMMANDS_DIR/claude-init.md
Tpl:    $SHIPPED_DIR/default -> $REPO_ROOT/templates/default
EOF

# PATH setup — source the shared helper.
# shellcheck source=lib/path-setup.sh
. "$REPO_ROOT/scripts/lib/path-setup.sh"
PATH_SETUP_AUTO_ADD="${CLAUDE_INIT_ADD_TO_PATH:-0}" path_setup_run

if [ "${CLAUDE_INIT_ADD_TO_PATH:-0}" != "1" ] && ! path_setup_bin_on_path; then
  printf '\n      Or re-run dev-install with auto-append:\n'
  printf '        \033[36mCLAUDE_INIT_ADD_TO_PATH=1 ./scripts/dev-install.sh\033[0m\n'
fi

cat <<EOF

Verify:
  claude-init --version
  claude-init template list

Undo:
  $REPO_ROOT/scripts/dev-uninstall.sh
EOF
