---
name: claude-code-notify
description: Sets up, customizes, tests, troubleshoots and removes macOS banner and sound notifications for Claude Code (Stop, StopFailure and Notification hooks from Priyans-hu/claude-code-notify). Use when the user wants Claude Code to alert them on a Mac when a turn finishes, fails, or needs permission or input, wants different sounds or events, says the notifications are silent or not showing, or wants them removed.
license: MIT
compatibility: macOS only. Needs Claude Code, jq and git. Changes ~/.claude/settings.json only after the user confirms.
metadata:
  author: Priyans-hu
  version: "1.0.0"
---

# claude-code-notify

A hook script plays a sound and shows a banner per event: `Stop` (Glass), `StopFailure` (Basso), `Notification` permission prompt (Funk) or idle prompt (Sosumi).

**Rule:** before any change to `~/.claude/settings.json`, `~/.claude/hooks/` or installed plugins, show the user the exact change and wait for a yes. Never pipe a download into a shell.

## 1. Check what is installed

- Plugin: `claude plugin list` shows `cc-notify@claude-code-notify`.
- Manual: `~/.claude/hooks/claude-notify.sh` exists and `jq .hooks ~/.claude/settings.json` lists it.

Keep only one of the two, or every event fires twice.

## 2. Set up

**Plugin** (recommended, no hand edits). Ask, then run in a shell:

```bash
claude plugin marketplace add Priyans-hu/claude-code-notify
claude plugin install cc-notify@claude-code-notify
```

In a session, the user can run `/plugin install cc-notify --marketplace Priyans-hu/claude-code-notify` instead. Both record the plugin in user settings. Then run `/reload-plugins` or start a new session.

**Manual** (needed to customize):

1. `git clone https://github.com/Priyans-hu/claude-code-notify` into a temp dir and read `hooks/claude-notify.sh`.
2. Copy `hooks/claude-notify.sh` and `hooks/ClaudeNotify.app` into `~/.claude/hooks/`.
3. Preview the merge. It appends to existing hooks and writes nothing:
   ```bash
   jq --arg cmd "bash $HOME/.claude/hooks/claude-notify.sh" '{hooks: [{type: "command", command: $cmd, async: true}]} as $e
     | reduce ("Stop", "StopFailure", "Notification") as $ev (.; .hooks[$ev] += [$e])' ~/.claude/settings.json
   ```
   Show the diff. After a yes, back up `settings.json` and write the result. If the file doesn't exist, use `{}` as the input.

## 3. Customize (manual install)

- Sounds, emoji, labels: edit the `case` block in `~/.claude/hooks/claude-notify.sh`. Sounds are in `/System/Library/Sounds`; preview one with `afplay /System/Library/Sounds/Hero.aiff`.
- Events: add or remove event keys in the settings `hooks` block, such as `SubagentStop`. A `"matcher": "permission_prompt|idle_prompt"` on `Notification` limits which notifications alert.
- The plugin copy is replaced on update. To customize, uninstall the plugin and use the manual install.

## 4. Test and troubleshoot

```bash
S=~/.claude/hooks/claude-notify.sh   # plugin: find ~/.claude/plugins/cache -name claude-notify.sh
echo '{"hook_event_name":"Stop","cwd":"/x/demo"}' | CC_DEBUG=1 bash "$S"   # prints the mapping only
echo '{"hook_event_name":"Stop","cwd":"/x/demo"}' | bash "$S"              # real sound + banner
```

- Sound but no banner: in System Settings > Notifications > "Claude Code", allow notifications with the Banners style. Check Focus and Do Not Disturb.
- Banners come from the bundled "Claude Code" app, not from the terminal, so the terminal app's notification setting doesn't matter. Hooks run in any terminal, IDE or tmux.
- If the app is missing or macOS won't open it (the bundle needs macOS 26), the script falls back to osascript, which posts as "Script Editor". Allow that app instead.
- Nothing at all: check that `/hooks` lists the hooks, that `jq` is installed (`brew install jq`), and that the script runs with `CC_DEBUG=1`.

## 5. Remove

- Plugin: `claude plugin uninstall cc-notify@claude-code-notify`, then optionally `claude plugin marketplace remove claude-code-notify`.
- Manual: show the user, then delete the hook entries whose command runs `claude-notify.sh` from `~/.claude/settings.json`, and delete `~/.claude/hooks/claude-notify.sh` and `~/.claude/hooks/ClaudeNotify.app`.
