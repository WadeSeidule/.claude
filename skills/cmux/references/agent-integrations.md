# Agent integrations

cmux integrates with several coding agents. They share a common trick: a fake `tmux` shim that translates tmux calls into native cmux socket calls, so tools written for tmux render as native cmux splits.

## Three layers, pick the simplest

### Layer 1 — Parallel workspaces (no integration)

Just spawn N agents in N workspaces. The sidebar handles attention routing.

```bash
for slug in fix-a fix-b fix-c; do
  cmux-worktree new "$slug" -a "claude"
done
```

Use this for racing agents, parallel features, or "I want N separate Claude sessions on different branches." No setup needed beyond `cmux setup-hooks`.

### Layer 2 — `cmux claude-teams`

Claude Code has an experimental teammate mode (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) where the lead Claude can spawn sub-agents via tmux. `cmux claude-teams` makes those sub-agents render as native cmux splits.

```bash
cmux claude-teams [any-claude-args...]
cmux claude-teams --continue
cmux claude-teams --model sonnet
```

What it does:

1. Sets `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
2. Prepends `~/.cmuxterm/claude-teams-bin/` to `PATH`
3. Drops a fake `tmux` script there that intercepts:
   - `tmux split-window` → `cmux new-split`
   - `tmux send-keys` → `cmux send`
   - `tmux capture-pane` → `cmux read-screen`
   - `tmux select-pane` / `select-window` → `cmux focus-*`
4. Sets `TMUX=` and `TMUX_PANE=` so Claude believes it's already in tmux
5. Persistent buffer/hook state at `~/.cmuxterm/tmux-compat-store.json`

When Claude spawns a teammate, it appears as a real cmux split — your sidebar shows it, your notifications ring it, ⌘⇧U jumps to it.

### Layer 3 — `cmux omc` / `omo` / `omx`

Heavier, opinionated multi-agent orchestrators. Same shim mechanism.

| Launcher | Tool | Install |
|---|---|---|
| `cmux omc` | oh-my-claudecode (19 specialized agents, model routing) | `npm install -g oh-my-claude-sisyphus` |
| `cmux omo` | OpenCode | `bun install -g opencode-ai` (varies) |
| `cmux omx` | Codex | per Codex docs |

Example:

```bash
cmux omc team 3:claude "implement feature"
cmux omc --watch
```

Workers and the HUD render as cmux splits in the workspace.

## Hook setup (do this once)

```bash
cmux setup-hooks
```

That installs hooks for: claude, codex, opencode, cursor, gemini, copilot, codebuddy, factory, qoder.

Per-agent if you want fine control (Claude is included in `setup-hooks` only — there is no `cmux claude install-hooks`):

```bash
cmux codex   install-hooks
cmux opencode install-hooks
cmux cursor  install-hooks
cmux gemini  install-hooks
cmux copilot install-hooks
cmux codebuddy install-hooks
cmux factory install-hooks
cmux qoder   install-hooks
```

What hooks do (Claude as the example):

| Event | Effect |
|---|---|
| `session-start` | Marks workspace running |
| `prompt-submit` | Clears notification, sets running status |
| `notification` | Fires `cmux notify`, blue ring on tab |
| `stop` | Marks idle, fires "done" notification |
| `pre-tool-use` | Records context for the sidebar |
| `session-end` | Marks ended |

To remove:

```bash
cmux uninstall-hooks
```

## Manual hook calls (rare; for custom integrations)

```bash
echo '{...event-json...}' | cmux claude-hook session-start
cmux claude-hook stop          # mark idle, ring tab
cmux claude-hook notification  # fire a notification
```

The shape of stdin JSON varies per agent — let `cmux setup-hooks` write the wiring; only handle hooks manually if you're integrating a custom agent.

## Choosing a layer

| If you want... | Use |
|---|---|
| N agents on N tasks, my own orchestration | Layer 1 |
| One Claude that delegates sub-tasks to teammates | Layer 2 (`claude-teams`) |
| A pre-built multi-agent pipeline (planner → coder → reviewer) | Layer 3 (`omc`) |
| Agents I drive from scripts (CI bot, watcher, observer) | Layer 1 + `cmux send`/`notify` |

## Caveats

- The shim only intercepts tmux commands the agent actually uses. If the agent calls something obscure (e.g., `tmux source-file`), it falls through to a real tmux if available, or no-ops if not.
- `claude-teams` is **experimental** in Claude Code itself. Stable usage is Layer 1.
- `omc`, `omo`, `omx` are external projects — version drift can break the shim. If splits stop appearing, check the launcher's release notes against cmux changelog.
