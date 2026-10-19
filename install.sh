#!/usr/bin/env bash
# Installs claude-code-notify: copies the hook files into ~/.claude/hooks and
# merges the Stop / StopFailure / Notification hooks into ~/.claude/settings.json.
#
# From a clone:   ./install.sh
# Straight curl:  curl -fsSL https://raw.githubusercontent.com/Priyans-hu/claude-code-notify/main/install.sh | bash
#
# Idempotent — safe to re-run. Backs up settings.json before touching it.
set -euo pipefail

REPO_URL="https://github.com/Priyans-hu/claude-code-notify.git"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"

# ── preflight ────────────────────────────────────────────────────────────────
[ "$(uname)" = "Darwin" ] || { echo "error: macOS only (uses afplay + terminal-notifier)"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "error: jq is required  ->  brew install jq"; exit 1; }

echo "==> Installing claude-code-notify into $CLAUDE_DIR"

# ── locate source files: use a local checkout if present, else fetch the repo ─
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd || true)"
if [ -z "${SRC_DIR:-}" ] || [ ! -d "$SRC_DIR/hooks" ]; then
  command -v git >/dev/null 2>&1 || { echo "error: git is required to fetch the files"; exit 1; }
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  echo "    fetching files from $REPO_URL"
  git clone --depth 1 -q "$REPO_URL" "$TMP/repo"
  SRC_DIR="$TMP/repo"
fi

# ── 1. copy hook files ───────────────────────────────────────────────────────
mkdir -p "$HOOKS_DIR"
cp -R "$SRC_DIR/hooks/claude-notify.sh" "$SRC_DIR/hooks/ClaudeNotify.app" "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR/claude-notify.sh"
echo "    copied hook files -> $HOOKS_DIR"

# ── 2. merge hooks block into settings.json ─────────────────────────────────
HOOK_CMD="bash $HOOKS_DIR/claude-notify.sh"
NEW_HOOKS=$(jq -n --arg cmd "$HOOK_CMD" '
  { hooks: [ { type: "command", command: $cmd, async: true } ] } as $entry
  | { Stop: [$entry], StopFailure: [$entry], Notification: [$entry] }')

if [ -f "$SETTINGS" ]; then
  backup="$SETTINGS.bak.$(date +%s)"
  cp "$SETTINGS" "$backup"
  tmp="$(mktemp)"
  jq --argjson h "$NEW_HOOKS" '.hooks = ((.hooks // {}) + $h)' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "    merged hooks into $SETTINGS (backup: $backup)"
else
  mkdir -p "$CLAUDE_DIR"
  jq -n --argjson h "$NEW_HOOKS" '{ hooks: $h }' > "$SETTINGS"
  echo "    created $SETTINGS"
fi

# ── done ─────────────────────────────────────────────────────────────────────
cat <<EOF

==> Done. Next steps:
  1. Grant permission: System Settings > Notifications > "Claude Code" -> allow
  2. Reload hooks in an open session with  /hooks  (new sessions auto-pick-up)
  3. Test it:
       echo '{"hook_event_name":"Stop","cwd":"/x/demo"}' | CC_DEBUG=1 bash "$HOOKS_DIR/claude-notify.sh"
     drop CC_DEBUG=1 to actually see the banner + hear the sound.
EOF
