#!/usr/bin/env bash
# ~/.claude/hooks/claude-notify.sh
# macOS banner + sound for Claude Code lifecycle events.
# Wired from ~/.claude/settings.json ("hooks"): Stop / StopFailure / Notification [ / SubagentStop ].
# Reads the hook's JSON payload on stdin, then picks an emoji + sound + label per event.
#
# ── CUSTOMISE ────────────────────────────────────────────────────────────────
# Edit the sound / emoji / label in the case block below. Sounds live in
# /System/Library/Sounds — audition one with:  afplay /System/Library/Sounds/Glass.aiff
#   Basso Blow Bottle Frog Funk Glass Hero Morse Ping Pop Purr Sosumi Submarine Tink
#
# TEST / DEBUG: pipe a fake payload and set CC_DEBUG=1 to print the mapping (no sound/banner):
#   echo '{"hook_event_name":"Stop","cwd":"/x/plivo"}' | CC_DEBUG=1 bash claude-notify.sh
# ──────────────────────────────────────────────────────────────────────────────

input=$(cat)
f() { printf '%s' "$input" | jq -r "$1 // \"\"" 2>/dev/null; }

event=$(f '.hook_event_name')
proj=$(printf '%s' "$input" | jq -r 'if .cwd then (.cwd | split("/") | last) else "" end' 2>/dev/null)
sid=$(f '.session_id' | cut -c1-6)
detail=""   # notification body — kept empty unless the event carries a short, plain string

case "$event" in
  Stop)                                    # turn finished normally  → success
    emoji="✅"; sound="Glass"; label="Done" ;;
  StopFailure)                             # turn ended on API/infra error → failure
    emoji="❌"; sound="Basso"; label="Failed: $(f '.error')" ;;
  SubagentStop)                            # a sub-agent finished (opt-in; can be frequent)
    emoji="🤖"; sound="Submarine"; label="Sub-agent done: $(f '.agent_type')" ;;
  Notification)                            # Claude is waiting on you
    case "$(f '.notification_type')" in
      permission_prompt) emoji="🔐"; sound="Funk";   label="Needs permission" ;;
      idle_prompt)       emoji="💤"; sound="Sosumi"; label="Waiting for input" ;;
      *)                 emoji="🔔"; sound="Ping";   label="$(f '.title')" ;;
    esac
    detail=$(f '.message') ;;             # e.g. "Claude needs your permission to use Bash"
  *)                                       # any other wired event
    emoji="🔔"; sound="Ping"; label="$event" ;;
esac

title="$emoji ${label:-Claude Code}"
subtitle="${proj:-$sid}"
# collapse newlines, strip stray markdown, keep it short
detail=$(printf '%s' "$detail" | tr '\n' ' ' | sed 's/[*_`#]//g' | cut -c1-140)

if [ -n "$CC_DEBUG" ]; then
  printf 'event=%-13s sound=%-9s | title=%s | subtitle=%s | body=%s\n' \
    "$event" "$sound" "$title" "$subtitle" "$detail"
  exit 0
fi

# Sound in the background so the hook never blocks.
afplay "/System/Library/Sounds/${sound}.aiff" >/dev/null 2>&1 &

# Fire the banner from ClaudeNotify.app — a tiny bundle carrying the real Claude icon.
# It reads the payload file (UTF-8), sidestepping osascript's icon + encoding limits.
NOTIFIER="$HOME/.claude/hooks/ClaudeNotify.app"
if [ -d "$NOTIFIER" ]; then
  printf '%s\n%s\n%s' "$title" "$subtitle" "$detail" > "$HOME/.claude/hooks/.notify-payload"
  open -n -a "$NOTIFIER"
else
  # Fallback: plain osascript (shows the generic "Script Editor" icon).
  LC_ALL=en_US.UTF-8 osascript - "$title" "$subtitle" "$detail" >/dev/null 2>&1 <<'APPLESCRIPT'
on run argv
  display notification (item 3 of argv) with title (item 1 of argv) subtitle (item 2 of argv)
end run
APPLESCRIPT
fi

exit 0
