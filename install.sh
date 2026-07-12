#!/usr/bin/env bash
# Atlaso installer — macOS / Linux / WSL.
#   curl -fsSL https://atlaso.ai/install.sh | bash
#
# Does the minimum bootstrap (detect platform → download the atlaso binary →
# PATH), styled to match the Clack UI the binary itself renders, then hands off
# to `atlaso connect` so install + device-link is ONE command. Idempotent:
# re-running updates the binary in place.
#
# Env overrides (dev/test):
#   ATLASO_INSTALL_URL   base URL (or local dir via file://) for the binaries
#   ATLASO_NO_CONNECT=1  install only — skip the connect handoff
#   ATLASO_HOME          sandbox home (mock/dev — instead of ~/.atlaso)
#   ATLASO_MOCK=1        mock mode: no shell rc edits, connect is simulated
set -euo pipefail

A_HOME="${ATLASO_HOME:-$HOME/.atlaso}"

# ── Clack-look primitives (the binary continues this exact visual spine) ─────
BAR="\033[90m│\033[0m"
STEP="\033[90m◇\033[0m"
OK="\033[32m◇\033[0m"
ERR="\033[31m■\033[0m"
say()  { printf "%b  %s\n" "$STEP" "$1"; }
good() { printf "%b  %s\n" "$OK" "$1"; }
bar()  { printf "%b\n" "$BAR"; }
die()  { printf "%b  %s\n" "$ERR" "$1" >&2; exit 1; }

# Wordmark only — pictorial logos don't survive arbitrary terminal fonts /
# line-spacing (half-block art shows seams on any terminal with line gaps).
# One dot + the word, bold, plain foreground → crisp on every theme.
printf "\n\033[1m●  Atlaso\033[0m\n"
bar

# ── 1. platform ───────────────────────────────────────────────────────────────
OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS-$ARCH" in
  Darwin-arm64)              TARGET="atlaso-darwin-arm64";  NICE="macOS (Apple Silicon)" ;;
  Darwin-x86_64)             TARGET="atlaso-darwin-x64";    NICE="macOS (Intel)" ;;
  Linux-x86_64)              TARGET="atlaso-linux-x64";     NICE="Linux (x64)" ;;
  Linux-aarch64|Linux-arm64) TARGET="atlaso-linux-arm64";   NICE="Linux (arm64)" ;;
  *) die "Unsupported platform: $OS $ARCH — see https://atlaso.ai/docs/install" ;;
esac
# WSL is Linux to us, but say so — it's what the user typed into.
if [ "$OS" = "Linux" ] && grep -qi microsoft /proc/version 2>/dev/null; then
  NICE="$NICE · WSL"
fi
good "Detected $NICE"

# ── 2. download ───────────────────────────────────────────────────────────────
BASE="${ATLASO_INSTALL_URL:-https://github.com/atlaso-labs/cli/releases/latest/download}"
BIN_DIR="$A_HOME/bin"
mkdir -p "$BIN_DIR"
TMP="$(mktemp)"
if [[ "$BASE" == file://* ]]; then
  cp "${BASE#file://}/$TARGET" "$TMP" || die "Local binary not found: ${BASE#file://}/$TARGET"
else
  curl -fsSL "$BASE/$TARGET" -o "$TMP" || die "Download failed — check your connection and retry"
fi
chmod +x "$TMP"
mv "$TMP" "$BIN_DIR/atlaso"
VERSION="$("$BIN_DIR/atlaso" --version 2>/dev/null || echo "?")"
good "Downloaded atlaso v$VERSION"
good "Installed to ${A_HOME/#$HOME/~}/bin"

# ── 3. PATH ───────────────────────────────────────────────────────────────────
add_path_line() { # $1 = rc file
  local line='export PATH="$HOME/.atlaso/bin:$PATH"'
  [ -f "$1" ] && grep -qsF '.atlaso/bin' "$1" && return 0
  printf '\n# atlaso\n%s\n' "$line" >> "$1"
}
if [ -n "${ATLASO_MOCK:-}" ]; then
  # mock: NEVER touch the user's shell files — same line, honestly labeled
  good "Added to PATH (simulated — mock mode)"
else
  case "${SHELL:-}" in
    */zsh)  add_path_line "$HOME/.zshrc" ;;
    */bash) add_path_line "$HOME/.bashrc"; [ -f "$HOME/.bash_profile" ] && add_path_line "$HOME/.bash_profile" ;;
    */fish) mkdir -p "$HOME/.config/fish/conf.d"
            printf 'fish_add_path -g "$HOME/.atlaso/bin"\n' > "$HOME/.config/fish/conf.d/atlaso.fish" ;;
    *)      add_path_line "$HOME/.profile" ;;
  esac
  good "Added to PATH (new terminals pick it up automatically)"
fi
export PATH="$BIN_DIR:$PATH"
bar

# ── 4. hand off to the binary — the Clack UI continues from here ─────────────
if [ -n "${ATLASO_NO_CONNECT:-}" ]; then
  printf "\033[90m└\033[0m  Run \033[1matlaso connect\033[0m to link this device.\n\n"
  exit 0
fi
# `curl | bash` leaves stdin as the pipe; give the binary the real terminal so
# the connect flow can be interactive. If there's no TTY at all (CI/agents),
# print the next step instead of hanging.
if [ -t 1 ] && [ -e /dev/tty ]; then
  # the binary knows it's continuing THIS banner — it won't print its own
  exec env ATLASO_FROM_INSTALLER=1 "$BIN_DIR/atlaso" connect < /dev/tty
else
  printf "\033[90m└\033[0m  Run \033[1matlaso connect\033[0m to link this device.\n\n"
fi
