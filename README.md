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
- `hooks/hooks.json`, `.claude-plugin/` — the same hooks packaged as a Claude Code plugin.
- `skills/claude-code-notify/SKILL.md` — Agent Skill that sets up, customises, tests and removes the hooks.

## Install as a plugin or Agent Skill

Plugin (hooks wired for you, no hand edits to `settings.json`), in a Claude Code session:

```text
/plugin install cc-notify --marketplace Priyans-hu/claude-code-notify
```

or from a shell:

```bash
claude plugin marketplace add Priyans-hu/claude-code-notify
claude plugin install cc-notify@claude-code-notify
```

Agent Skill, which lets your agent set up, customise, test and remove the notifications. It asks before touching `~/.claude/settings.json`:

```bash
npx skills add Priyans-hu/claude-code-notify
```

Use the plugin or the script install below, not both, or every event fires twice. To customise sounds, use the script install: plugin updates replace the plugin's copy of the script.

## Install

One-liner (no clone needed):

```bash
curl -fsSL https://raw.githubusercontent.com/Priyans-hu/claude-code-notify/main/install.sh | bash
```

Or from a clone:

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
cp -R hooks/claude-notify.sh hooks/ClaudeNotify.app ~/.claude/hooks/
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

## Credits

Notification bundle built on [`terminal-notifier`](https://github.com/julienXX/terminal-notifier) © Eloy Durán, Julien Blanchard (MIT).
