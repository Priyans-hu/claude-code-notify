# claude-code-notify

macOS desktop banner **+ distinct sound** when a [Claude Code](https://docs.claude.com/en/docs/claude-code) turn ends or is waiting on you, so you can step away and still know the moment you need to unblock it.

Banners fire from a tiny re-skinned [`terminal-notifier`](https://github.com/julienXX/terminal-notifier) bundle carrying the real Claude icon (plain `osascript` only ever shows the generic "Script Editor" icon).

## What you get

| Event | Emoji | Sound | Meaning |
|-------|:-----:|-------|---------|
| `Stop` | ✅ | Glass | turn finished normally |
| `StopFailure` | ❌ | Basso | turn ended on an API / infra error |
| `Notification` → permission | 🔐 | Funk | Claude needs your permission |
| `Notification` → idle | 💤 | Sosumi | waiting for your input |
| `SubagentStop` | 🤖 | Submarine | sub-agent done (wired off by default — noisy) |

## Files

- `hooks/claude-notify.sh` — the hook. Reads the event JSON on stdin, picks emoji + sound + label, plays the sound and fires the banner. Customise the `case` block.
- `hooks/ClaudeNotify.app` — `terminal-notifier` bundle, ad-hoc signed, `LSUIElement`, display name "Claude Code". Firing from this app is what puts the Claude icon on the banner.
- `hooks/claude.png` — icon source used when building the app bundle.
- `settings.hooks.example.json` — the `hooks` block to merge into `~/.claude/settings.json`.

## Install

```bash
./install.sh
```

It copies the hook files into `~/.claude/hooks/` and merges the `Stop` / `StopFailure` / `Notification` hooks into `~/.claude/settings.json` (backing it up first). Idempotent and safe to re-run. Requires `jq` (`brew install jq`).

Then:

1. Grant permission: **System Settings ▸ Notifications ▸ "Claude Code"** → allow.
2. In an already-open session, run `/hooks` to reload (new sessions pick it up automatically).

<details>
<summary>Manual install</summary>

```bash
cp -R hooks/* ~/.claude/hooks/
chmod +x ~/.claude/hooks/claude-notify.sh
# then merge the "hooks" block from settings.hooks.example.json into ~/.claude/settings.json
```
</details>

## Customise

Edit the `case` block in `hooks/claude-notify.sh`. Available system sounds live in `/System/Library/Sounds` — audition one with:

```bash
afplay /System/Library/Sounds/Glass.aiff
# Basso Blow Bottle Frog Funk Glass Hero Morse Ping Pop Purr Sosumi Submarine Tink
```

## Test (no session needed)

Pipe a fake payload; `CC_DEBUG=1` prints the mapping without playing a sound or firing a banner:

```bash
echo '{"hook_event_name":"Stop","cwd":"/x/plivo"}' | CC_DEBUG=1 bash hooks/claude-notify.sh
```

Drop `CC_DEBUG=1` to actually see the banner and hear the sound.

## Notes

- Requires `jq` and `afplay` (afplay ships with macOS).
- If `~` isn't expanded in your hook command, use the absolute path to `claude-notify.sh`.
- `hooks/.notify-payload` is a transient runtime file (git-ignored).

## Credits

Notification bundle built on [`terminal-notifier`](https://github.com/julienXX/terminal-notifier) © Eloy Durán, Julien Blanchard (MIT).
