#!/usr/bin/env bash
# Shared PATH-setup helpers for install.sh and scripts/dev-install.sh.
#
# Sourced, not executed. Caller must have these defined:
#   BIN_DIR     — directory holding the claude-init binary
#   log         — info logger:  log <label> <msg>
#   warn        — warning logger
#
# Caller passes:
#   PATH_SETUP_AUTO_ADD = "1"   to auto-append (with backup + idempotency)
#                         else  print instructions only

# Detect user's login shell. Falls back to $SHELL, then "sh".
path_setup_detect_shell() {
  local s="${SHELL:-/bin/sh}"
  basename "$s"
}

# Files to source for a given shell.
# Echoes one path per line: first = interactive rc, then non-interactive env (if any).
path_setup_rc_files_for() {
  local sh="$1"
  case "$sh" in
    zsh)
      printf '%s\n' "$HOME/.zshrc"
      printf '%s\n' "$HOME/.zshenv"   # non-interactive shells (Claude Code Bash, etc.)
      ;;
    bash)
      # macOS bash reads ~/.bash_profile for login shells, ~/.bashrc for interactive non-login.
      # Linux uses ~/.bashrc for interactive non-login. Cover both common cases.
      case "$(uname -s)" in
        Darwin) printf '%s\n' "$HOME/.bash_profile" ;;
        *)      printf '%s\n' "$HOME/.bashrc" ;;
      esac
      ;;
    fish)
      printf '%s\n' "$HOME/.config/fish/config.fish"
      ;;
    *)
      # POSIX sh / dash / ksh / unknown
      printf '%s\n' "$HOME/.profile"
      ;;
  esac
}

# Build the export line for a shell (different syntax per shell).
path_setup_export_line_for() {
  local sh="$1" bin="$2"
  case "$sh" in
    fish) printf 'set -gx PATH %s $PATH\n' "$bin" ;;
    *)    printf 'export PATH="%s:$PATH"\n' "$bin" ;;
  esac
}

# Append the export line to a file if not already present. Backs up first.
path_setup_append_to_rc() {
  local rc="$1" line="$2"
  if [ -f "$rc" ] && grep -qF "$line" "$rc" 2>/dev/null; then
    log "ok" "$rc already contains PATH entry"
    return 0
  fi
  # Ensure parent dir exists (e.g. ~/.config/fish/)
  mkdir -p "$(dirname "$rc")"
  if [ -f "$rc" ]; then
    cp "$rc" "$rc.bak.$(date +%Y%m%d%H%M%S)"
  fi
  printf '\n# claude-init PATH (added %s)\n%s\n' "$(date +%Y-%m-%d)" "$line" >> "$rc"
  log "ok" "appended to $rc"
}

# True iff $BIN_DIR is on the current PATH.
path_setup_bin_on_path() {
  case ":$PATH:" in
    *":$BIN_DIR:"*) return 0 ;;
    *)              return 1 ;;
  esac
}

# Main entry — print or auto-add PATH setup. Caller must have BIN_DIR + log/warn.
path_setup_run() {
  local auto="${PATH_SETUP_AUTO_ADD:-0}"
  local shell_name export_line
  shell_name="$(path_setup_detect_shell)"
  export_line="$(path_setup_export_line_for "$shell_name" "$BIN_DIR")"

  local -a rc_files=()
  local _rc
  while IFS= read -r _rc; do
    [ -n "$_rc" ] && rc_files+=("$_rc")
  done < <(path_setup_rc_files_for "$shell_name")

  if path_setup_bin_on_path; then
    printf '\nPATH: \033[32m✓ %s already on PATH\033[0m\n' "$BIN_DIR"
    return 0
  fi

  printf '\nPATH: \033[33m! %s is NOT on your PATH\033[0m\n' "$BIN_DIR"
  printf '      Detected shell: \033[36m%s\033[0m\n' "$shell_name"

  if [ "$auto" = "1" ]; then
    printf '      \033[36mauto-append\033[0m enabled — appending to rc files:\n'
    local rc
    for rc in "${rc_files[@]}"; do
      path_setup_append_to_rc "$rc" "$export_line"
    done
    printf '\n      Reload your shell or run: \033[36msource %s\033[0m\n' "${rc_files[0]}"
    return 0
  fi

  printf '\n      Add this line to:\n'
  local rc
  for rc in "${rc_files[@]}"; do
    printf '        - %s\n' "$rc"
  done
  if [ "$shell_name" = "zsh" ]; then
    printf '      (Both — \033[36m.zshrc\033[0m for your terminal, \033[36m.zshenv\033[0m for Claude Code Bash.)\n'
  fi
  printf '\n      \033[36m%s\033[0m\n' "$export_line"
}
