# cmux object model

Four levels, in order of containment:

```
Window
└─ Workspace
   └─ Pane
      └─ Surface
```

## Window

A native macOS window. Created with `⌘⇧N` or `cmux new-window`. Each window has its own sidebar with independent workspaces. Most workflows live in one window; a second window is useful for side-by-side rooms (e.g., "agents" window vs "review" window).

CLI: `list-windows`, `current-window`, `new-window`, `focus-window`, `close-window`.

## Workspace

A sidebar entry. **This is the unit you map to a feature, worktree, or long-running agent session.** Created with `⌘N` or `cmux new-workspace`. The sidebar tab shows:

- Git branch (auto-detected from cwd)
- Linked PR status + number (when the branch has an open PR)
- Working directory
- Listening ports (e.g., `:3000` if your dev server is up)
- Latest unread notification body
- Optional name, description, color, status pill, log line, progress bar (set via CLI)

A workspace contains one or more panes. Closing a workspace does NOT remove the underlying git worktree — that's a separate `git` operation.

CLI: `list-workspaces`, `new-workspace`, `select-workspace`, `rename-workspace`, `close-workspace`, `workspace-action --action <pin|set-color|...>`.

In the UI and shortcuts, workspaces are sometimes called "tabs" because they behave like tabs in the sidebar.

## Pane

A split region inside a workspace. Created by splitting (`⌘D` right, `⌘⇧D` down) or `cmux new-split <direction>`. Each pane is a rectangle that holds one or more surfaces (browser tabs/terminal tabs).

Panes have no sidebar metadata — they are layout. If you put two worktrees in two panes of one workspace, the sidebar still shows only the *workspace's* branch (which is the cwd of whichever surface was active when the workspace was created). Don't do that — use two workspaces.

CLI: `list-panes`, `new-pane`, `focus-pane`, `new-split`, `swap-pane`, `break-pane`, `join-pane`, `resize-pane`.

## Surface

The actual terminal or browser session. Created with `⌘T` or `cmux new-surface`. Panes can have multiple surfaces; only one is visible at a time (horizontal tabs across the top of the pane). A surface holds:

- For terminal type: a PTY-attached shell process
- For browser type: a webview with its own URL/history

Inside a cmux terminal surface, two env vars are set:

- `CMUX_WORKSPACE_ID` — UUID of the containing workspace
- `CMUX_SURFACE_ID` — UUID of this surface
- `CMUX_TAB_ID` — UUID for tab-context commands

These mean most `cmux send`, `cmux notify`, `cmux read-screen` calls work without explicit handle flags.

CLI: `list-pane-surfaces`, `new-surface`, `close-surface`, `move-surface`, `reorder-surface`, `tab-action`, `rename-tab`, `read-screen`, `send`, `send-key`.

## Panel (advanced)

Mostly internal. The "panel" is the actual content widget (terminal vs browser) inside a surface. Most CLI commands operate on surfaces, not panels. The compatibility commands `list-panels`, `focus-panel`, `send-panel`, `send-key-panel` exist mainly for legacy scripts; prefer the surface-oriented forms.

## Refs and handles

Anywhere a window/workspace/pane/surface argument is accepted:

- **UUID** — `7d2a-...-9f3c`
- **Ref** — `workspace:2`, `surface:3`, `window:1`
- **Index** — `2` (positional within the parent)

Default output is refs. Use `--id-format uuids` for UUID-only or `--id-format both` to include both. Use `--json` for machine-readable output.

## Session restore

Quitting saves session state. On relaunch, cmux restores:

- Window / workspace / pane layout
- Working directories
- Terminal scrollback (best effort)
- Browser URL + navigation history
- Saved Claude Code and Codex sessions when a resume token is present

Cmux does NOT resume arbitrary in-process state. tmux/vim/REPL/agent sessions without a resume flow reopen as fresh shells.

To force a restore: `File → Reopen Previous Session`, `⌘⇧O`, or `cmux restore-session`.

## Composition example

A typical "fixing 3 bugs in parallel" layout:

```
Window 1
├─ Workspace "fix-cache-leak"   cwd=../app-fix-cache-leak  branch=fix/cache  PR #1234 ✓
│   └─ Pane (full)
│       └─ Surface 1: claude    (running)
│
├─ Workspace "fix-auth-bug"     cwd=../app-fix-auth-bug    branch=fix/auth  PR #1235 ⚠
│   └─ Pane (full)
│       └─ Surface 1: codex     (waiting on input)  ← blue ring
│
└─ Workspace "review"           cwd=~/dev/app             branch=main
    ├─ Pane (left)
    │   └─ Surface 1: zsh
    └─ Pane (right)
        └─ Surface 1: browser → http://localhost:3000
```

⌘⇧U jumps to the second workspace because it has the unread ring.
