#!/usr/bin/env bash
# Undo dev-install.sh — remove symlinks pointing at this checkout.
# Real files (not symlinks) are left alone. Backups are not restored.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
BIN_DIR="$CLAUDE_HOME/bin"
COMMANDS_DIR="$CLAUDE_HOME/commands"
SHIPPED_DIR="$CLAUDE_HOME/templates/claude-init"

log()  { printf '  \033[36m%s\033[0m %s\n' "$1" "$2"; }
warn() { printf '  \033[33m%s\033[0m %s\n' "WARN" "$1" >&2; }

log "==>" "dev-uninstall claude-init"
log "src" "$REPO_ROOT"
log "dst" "$CLAUDE_HOME"

# Helper: remove a path only if it's a symlink pointing into the repo.
unlink_if_ours() {
  local path="$1"
  if [ -L "$path" ]; then
    local target
    target="$(readlink "$path")"
    case "$target" in
      "$REPO_ROOT"*)
        rm "$path"
        log "rm" "$path"
        ;;
      *)
        warn "$path is a symlink to $target (not ours, leaving it)"
        ;;
    esac
  elif [ -e "$path" ]; then
    warn "$path is a real file/dir (not a symlink, leaving it)"
  else
    log "skip" "$path (not present)"
  fi
}

unlink_if_ours "$BIN_DIR/claude-init"
unlink_if_ours "$COMMANDS_DIR/claude-init.md"
unlink_if_ours "$SHIPPED_DIR/default"

cat <<EOF

dev-uninstall complete.

Note: backups (*.bak.*) created by dev-install are NOT restored automatically.
List them with:
  ls $CLAUDE_HOME/templates/claude-init/*.bak.* 2>/dev/null
  ls $COMMANDS_DIR/*.bak.* 2>/dev/null
  ls $BIN_DIR/*.bak.* 2>/dev/null
EOF
