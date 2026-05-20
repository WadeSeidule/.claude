---
name: cmux
description: Drive the cmux terminal (Ghostty-based macOS app) from the CLI and socket API — manage workspaces, panes, surfaces, send keys to other agents, route notifications, run multi-agent orchestrators (claude-teams, omc, omo, omx), and use the bundled `cmux-worktree` helper to create per-feature git worktrees as cmux workspaces. Use this skill whenever the user mentions cmux, wants to script terminal automation across parallel agents, asks to spawn/coordinate coding agents, mentions worktree-per-feature workflows, references claude-teams or oh-my-claudecode/omc/omo/omx, wants to wire `cmux notify` or hook integrations, or asks how to make several Claude/Codex/Gemini sessions ring you only when blocked.
disable-model-invocation: false
---

# cmux

Reference for driving the cmux terminal app (https://cmux.com, github.com/manaflow-ai/cmux) from scripts and agents. cmux is intentionally **a primitive, not a solution** — there is no `cmux worktree` command; multi-agent and worktree workflows are *composed* from the CLI primitives below.

## When to use

Trigger on any of these:

- "cmux", "open in cmux", "new workspace", "split pane in cmux"
- "claude-teams", "claude code teammate", "omc", "omo", "omx", "oh-my-claudecode"
- worktree-per-feature, parallel agents, racing agents, multi-agent dev
- "ring me when the agent is done", `cmux notify`, agent hooks for Claude/Codex/OpenCode/Cursor/Gemini/Copilot
- automating a terminal pane: `cmux send`, `cmux read-screen`, `cmux send-key`
- sidebar status pills, progress bars, log entries on workspaces

## Mental model (read this first)

```
Window         macOS window         ⌘⇧N
└─ Workspace   sidebar tab          ⌘N    ← unit with cwd + branch + PR + ports + name
   └─ Pane     split region         ⌘D right / ⌘⇧D down
      └─ Surface  tab inside pane   ⌘T    ← terminal or browser session, has CMUX_SURFACE_ID
```

Important consequences:

- **Workspace = the user-visible row in the sidebar.** It carries the git branch, linked PR status, working directory, listening ports, and latest notification. Map one workspace to one feature/worktree/agent — not one pane, because pane metadata is invisible.
- **Surface = the actual shell.** Inside a cmux terminal, `$CMUX_WORKSPACE_ID` and `$CMUX_SURFACE_ID` resolve automatically, so most CLI calls work without explicit `--workspace`/`--surface` flags.
- **Session restore** persists window/workspace/pane layout, cwd, scrollback (best effort), and saved Claude/Codex resume tokens. Live processes are NOT resumed.

For details see `references/object-model.md`.

## The CLI surface (what to reach for)

Use the dedicated CLI command when one fits. Full catalog in `references/cli-reference.md`. The high-leverage commands:

| Goal | Command |
|---|---|
| Open a directory as a workspace | `cmux <path>` |
| New workspace with cwd + startup command | `cmux new-workspace --cwd <path> --name "<title>" --command "<cmd>"` |
| Split current surface | `cmux new-split <left\|right\|up\|down>` |
| Send text to another surface | `cmux send --workspace "$WS" -- "text\n"` (resolve `$WS` once via `cmux list-workspaces --json`) |
| Send a single key | `cmux send-key --surface surface:M Enter` |
| Read what's on screen | `cmux read-screen --workspace workspace:N --scrollback --lines 200` |
| Notify (ring the tab) | `cmux notify --title "..." --body "..." --workspace workspace:N` |
| Sidebar status pill | `cmux set-status --workspace workspace:N "deploying" --color blue` |
| Sidebar log line | `cmux log --workspace workspace:N "queued in CI"` |
| Tree of everything | `cmux tree --json` |
| List + find handles | `cmux list-workspaces --json`, `cmux find-window <query>` |
| Synchronize on a sentinel | `cmux wait-for [-S] <name>` |
| Close workspace | `cmux close-workspace --workspace workspace:N` |

Handles accept UUIDs, refs (`workspace:2`, `surface:3`), or indexes. Pass `--json` for machine-readable output and `--id-format both` if you need both refs and UUIDs.

## Worktree-per-feature workflow

Cmux ships with no worktree command, but this skill bundles `cmux-worktree` (alias **`cwt`**) with two modes:

- **`cwt <slug>`** — one git worktree + a new cmux *workspace* + agent launch (the common case)
- **`cwt tabs <slug...>`** — N git worktrees + N *tabs* in the **current** cmux workspace (must be run from inside a cmux terminal)

Source-of-truth lives in a separate git repo at `~/dev/cmux/` (cloned and run via `./install.sh`). That repo holds:

- `~/dev/cmux/scripts/cmux-worktree.sh` — the script
- `~/dev/cmux/cmux.json` — global palette commands
- `~/dev/cmux/install.sh` — idempotent installer (symlinks into `~/.config/cmux/` and `~/.local/bin/`)

Both `cmux-worktree` and `cwt` resolve to the same script via `~/.local/bin/` symlinks. For plain workspaces (no worktree, no git), use cmux's built-in `cmux new-workspace --cwd <path> --command <cmd>` directly — no helper needed.

```bash
# common case — slug is the only thing you type
cwt fix-leak
cwt PROJ-123 -a codex -d "deadlock in queue"

# explicit subcommand form (still works)
cwt new <slug> [-d "<description>"] [-a "<agent-cmd>"] [-b <branch>] [-p <worktree-path>] [-B <base-ref>]

# tabs mode: N worktrees + N tabs in CURRENT workspace (must be run from inside cmux)
cwt tabs <slug1> <slug2> [<slug3>...] [-a <agent>] [-B <base>] [--no-agent]

# tear down: close workspace + remove worktree + delete branch (with safety checks)
cwt done <slug> [--force] [--keep-branch]

# list worktrees joined with cmux workspaces
cwt list
```

**`cwt new` vs `cwt tabs`** — pick by attention model:

| Use | When |
|---|---|
| `cwt new <slug>` | One feature you'll context-switch to. Each gets a sidebar entry with branch/PR/ports/notification ring. Best when you'll have several features in flight. |
| `cwt tabs <slug...>` | Tightly-coupled parallel work (race the same task across N agents, watch all of them at once). They share a workspace, so sidebar metadata is the workspace's, not each tab's — but tabs all stay visible in one place. |

**Slug → branch derivation** (override with `-b`). The slug shape determines the namespace; slugs without a recognized prefix become the branch name verbatim (no implicit namespace):

| Slug | Branch |
|---|---|
| `fix-leak` | `fix/leak` |
| `hotfix-3.7.3` | `hotfix/3.7.3` |
| `exp-rewrite` | `exp/rewrite` |
| `refactor-types` | `refactor/types` |
| `chore-deps` | `chore/deps` |
| `docs-readme` | `docs/readme` |
| `wip-foo` | `wip/foo` |
| `PROJ-123` | `PROJ-123` (passed through unchanged) |
| `fix/cache` | `fix/cache` (slash kept as-is) |

**Worktree location** (override with `-p`):

| Setting | Resolves to |
|---|---|
| (default) | `<repo-root>/.worktrees/<slug>` |
| `CMUX_WORKTREE_REPO_DIR=foo` | `<repo-root>/foo/<slug>` (relative) |
| `CMUX_WORKTREE_REPO_DIR=/abs/path` | `/abs/path/<slug>` (absolute) |

The path slug is always sanitized: `cwt fix/cache` produces `.worktrees/fix-cache`, never nested. Add `.worktrees/` to your repo's `.gitignore` to keep `git status` quiet.

When to reach for which tool:

- **Feature/bugfix/experiment that earns its own branch** → `cwt <slug>`
- **Ops dashboard, log tail, dev server, exploration of an existing checkout** → `cmux new-workspace --cwd <path> --command <cmd>` (built-in, no helper)
- **Race three agents on one bug** → `cwt` in a loop, one slug per agent

Defaults:
- branch = `feat/<slug>` (from current HEAD)
- worktree path = `../$(basename $PWD)-<slug>`
- agent command = `claude` (override with `-a` or `CMUX_WORKTREE_AGENT` env var)

Examples:

```bash
cmux-worktree new fix-cache-leak -d "race condition in LRU eviction"
cmux-worktree new PROJ-123 -a "codex"
cmux-worktree new exp-rewrite -p ../experiments/rewrite -b experiment/rewrite

# parallel race: same task, three agents, three worktrees
for agent in claude codex opencode; do
  cmux-worktree new "fix-leak-${agent}" -a "${agent} 'fix the leak in src/cache.ts'"
done
```

When an agent finishes the task and the PR is up:

```bash
cmux-worktree done fix-cache-leak     # closes workspace + git worktree remove + branch delete
```

### Registered as a cmux palette command (already wired up)

`cmux-worktree` is registered globally at `~/.config/cmux/cmux.json` so it appears in the command palette of every cmux workspace. Open the palette (⌘K), type "worktree", and pick:

- **New worktree** → types `cmux-worktree new ` into the focused terminal — finish with a slug + Enter
- **New worktree (codex)** → same but with `-a codex`
- **New worktree (no agent)** → opens a plain shell instead of launching `claude`
- **Close worktree** → types `cmux-worktree done ` (prompts before running because `confirm: true`)
- **List worktrees** → runs `cmux-worktree list` immediately

cmux loads `cmux.json` from these paths (precedence top → bottom):

1. `./.cmux/cmux.json` — preferred per-repo location
2. `./cmux.json` — legacy per-repo location
3. `~/.config/cmux/cmux.json` — global, applies everywhere

Local commands override global commands with the same name. Changes are picked up automatically — no reload needed.

The schema for a simple command is:

```json
{
  "commands": [
    {
      "name": "Display name",
      "keywords": ["fuzzy", "search", "terms"],
      "command": "shell command, types into focused terminal",
      "confirm": false
    }
  ]
}
```

`confirm: true` prompts before running — set on `Close worktree` since it removes a worktree. Note that `command` runs in the *currently focused terminal* (not a fresh one), so the user types the slug after the prefix that cmux pastes in.

A workspace-command shape (`type: workspaceCommand` with a `workspace.layout` tree) is also available for actions that should spin up a new layout from scratch — see `assets/cmux.json.example` and the cmux docs at https://cmux.com/docs/custom-commands.

## Multi-agent orchestration

Three layers, pick the simplest that does the job. Full notes in `references/agent-integrations.md`.

1. **Parallel workspaces (no integration)** — spawn N agents in N workspaces. Sidebar rings + ⌘⇧U cycles to whichever is blocked. This is what cmux was built for. Use `cmux-worktree new` in a loop.

2. **`cmux claude-teams`** — Claude Code's experimental teammate mode. Sets `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` and installs a fake `tmux` shim at `~/.cmuxterm/claude-teams-bin/tmux` that translates `tmux split-window` / `send-keys` / `capture-pane` into native cmux splits. Sub-agents Claude spawns appear as real splits with full sidebar metadata.

3. **`cmux omc` / `omo` / `omx`** — same shim trick, hosting oh-my-claudecode, OpenCode, Codex orchestrators. Heavier and more opinionated; only when you want their pre-built agent pipelines.

## Notifications and sidebar status (the multi-agent glue)

Without notifications, parallel agents become a "which terminal needs me?" guessing game. Wire it once:

```bash
cmux setup-hooks    # installs claude/codex/opencode/cursor/gemini/copilot/codebuddy/factory/qoder hooks
```

That makes any agent emit pane-ring events when it's blocked. ⌘⇧U jumps to the next unread.

For your own scripts:

```bash
cmux notify --title "Tests passed" --body "1247/1247 in 8.2s" --workspace workspace:3
cmux set-status --workspace workspace:3 "deploying" --color blue
cmux set-progress --workspace workspace:3 0.42
cmux log --workspace workspace:3 "checkpoint: schema validated"
cmux clear-status --workspace workspace:3
```

You can also drive *another* agent from outside its pane:

```bash
# from workspace 1, hand a finding to the agent in workspace 5
cmux send --workspace workspace:5 "the build broke on line 42, please fix\n"

# observe an agent without joining its pane
cmux read-screen --workspace workspace:5 --scrollback --lines 200
```

## Discovering handles

When you don't know which workspace is which:

```bash
cmux tree --json --all              # full graph
cmux list-workspaces --json         # workspaces with names + cwd + branch
cmux find-window --content <query>  # search by name or content
cmux current-workspace --json       # who am I right now (inside a cmux terminal)
```

In scripts running inside a cmux terminal, prefer the env vars:

```bash
$CMUX_WORKSPACE_ID  $CMUX_SURFACE_ID  $CMUX_TAB_ID
```

## Common patterns (deeper in references/workflows.md)

- Worktree-per-feature with palette command
- Race three agents on one bug, keep the winner
- CI watcher that pings the right workspace when its build breaks
- Browser pane next to terminal for in-app QA via `cmux browser ...`
- SSH-backed workspaces (`cmux ssh user@host`) so localhost tunnels just work

## What to skip on day one

- `cmux browser ...` automation (powerful but orthogonal)
- `cmux vm` / `cmux cloud` (Founder's Edition early access)
- tmux-compat aliases (`bind-key`, `popup`, etc.) unless porting tmux scripts

## Important rules

- **One workspace per worktree, not panes.** Sidebar metadata (branch, PR, ports) is per-workspace.
- **Always run `cmux setup-hooks` once on a fresh machine** so agent rings work.
- **`cmux <path>` auto-launches the app** if not running — safe to use in scripts.
- **Don't `cmux close-workspace` without first checking the agent isn't mid-edit** — there's no undo. Prefer notifying the user, or pair with `cmux-worktree done` which prompts on uncommitted changes.
- **Don't shell-out from inside an agent loop without `< /dev/null` if your shell profile has interactive prompts** — the cmux CLI itself is fine, but user dotfiles can hang automation.

## Related references

- `references/object-model.md` — full window/workspace/pane/surface semantics
- `references/cli-reference.md` — every CLI command with examples
- `references/workflows.md` — concrete recipes (worktree-per-feature, race mode, CI watcher, etc.)
- `references/agent-integrations.md` — `claude-teams`, `omc`, `omo`, `omx`, hook details

## Files this skill manages (outside the skill dir)

The skill itself is documentation. Runtime artifacts live in the **`~/dev/cmux/`** repo, with symlinks into the canonical cmux/PATH locations:

- `~/dev/cmux/scripts/cmux-worktree.sh` — script source
- `~/dev/cmux/cmux.json` — palette config source
- `~/dev/cmux/install.sh` — idempotent installer (creates the symlinks below)
- `~/.config/cmux/cmux.json` → symlink to repo
- `~/.local/bin/cmux-worktree`, `~/.local/bin/cwt` → symlinks to repo's script

To deploy this skill on a fresh machine, `git clone` the cmux repo into `~/dev/cmux/` and run `./install.sh`.

## Bundled in this skill dir

- `assets/cmux.json.example` — copy-paste template for per-repo `cmux.json` overrides
- `references/` — deep-dive docs (object model, CLI, workflows, agent integrations)
- `evals/evals.json` — test prompts
