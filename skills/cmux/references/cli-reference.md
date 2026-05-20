# cmux CLI reference

Authoritative source: `cmux --help` and per-command `cmux <cmd> --help`. This is a curated catalog organized by use case.

## Global options (place before the command)

| Flag | Effect |
|---|---|
| `--socket <path>` | Override the socket path |
| `--password <value>` | Explicit socket password (also `CMUX_SOCKET_PASSWORD` env) |
| `--json` | Machine-readable JSON output where supported |
| `--id-format <refs\|uuids\|both>` | Handle format for outputs |
| `--window <id\|ref\|index>` | Route the command through a specific window |

## Environment variables (auto-set inside cmux terminals)

| Var | Meaning |
|---|---|
| `CMUX_WORKSPACE_ID` | Default workspace context |
| `CMUX_SURFACE_ID` | Default surface context |
| `CMUX_TAB_ID` | Default tab context |
| `CMUX_SOCKET_PATH` | Primary socket path |
| `CMUX_SOCKET_PASSWORD` | Auth fallback |

## Lifecycle: opening things

```bash
cmux <path>                                    # open dir as workspace, launches cmux if needed
cmux new-workspace \
  --name "<title>" \
  --description "<text>" \
  --cwd <path> \
  --command "<text sent + Enter after creation>"
cmux new-window
cmux new-split <left|right|up|down>            # split current surface
cmux new-pane --type <terminal|browser> --direction <l|r|u|d>
cmux new-surface --type <terminal|browser> [--pane <id|ref>]
cmux ssh <destination> [--name <title>] [--port <n>] [--identity <path>] [-- <remote-command>]
```

## Lifecycle: closing things

```bash
cmux close-surface [--surface <id|ref>]
cmux close-workspace --workspace <id|ref>
cmux close-window --window <id|ref>
```

## Discovery

```bash
cmux tree [--all] [--json]                     # hierarchical dump of windows/workspaces/panes/surfaces
cmux list-windows [--json]
cmux list-workspaces [--json]
cmux list-panes [--workspace <id|ref>] [--json]
cmux list-pane-surfaces [--workspace <id|ref>] [--pane <id|ref>] [--json]
cmux current-window
cmux current-workspace [--json]
cmux identify [--workspace <id|ref>] [--surface <id|ref>]
cmux find-window [--content] <query>           # search names + (with --content) buffer text
cmux capabilities                              # JSON of server capabilities
cmux ping
cmux version
```

## Driving a surface from the outside

```bash
cmux send --workspace <id|ref> [--surface <id|ref>] -- "<text>\n"
# trailing \n is what actually submits — without it, text is typed but not run
# escape sequences: \n and \r send Enter, \t sends Tab
cmux send-key [--workspace <id|ref>] [--surface <id|ref>] <key>
# key examples: Enter, Tab, Escape, Up, Down, ctrl-c, cmd-shift-l

cmux read-screen [--workspace <id|ref>] [--surface <id|ref>] [--scrollback] [--lines <n>]
cmux capture-pane [--scrollback] [--lines <n>]   # tmux-compat alias

cmux focus-pane --pane <id|ref>
cmux focus-panel --panel <id|ref>
cmux trigger-flash [--workspace <id|ref>] [--surface <id|ref>]
```

## Notifications and sidebar UI

```bash
cmux notify --title "<text>" [--subtitle "<text>"] [--body "<text>"] \
            [--workspace <id|ref>] [--surface <id|ref>]
cmux list-notifications [--json]
cmux clear-notifications

cmux set-status     --workspace <id|ref> "<text>" [--color <name|#hex>]
cmux clear-status   --workspace <id|ref>
cmux list-status    [--workspace <id|ref>]

cmux set-progress   --workspace <id|ref> <0..1>
cmux clear-progress --workspace <id|ref>

cmux log            --workspace <id|ref> "<line>"
cmux clear-log      --workspace <id|ref>
cmux list-log       --workspace <id|ref>

cmux sidebar-state  [--workspace <id|ref>]    # debug dump
```

## Workspace actions (context-menu equivalents)

```bash
cmux workspace-action --action <name> --workspace <id|ref> [args...]
# actions: pin, unpin, rename, clear-name, set-description, clear-description,
#          move-up, move-down, move-top, close-others, close-above, close-below,
#          mark-read, mark-unread, set-color, clear-color
cmux rename-workspace [--workspace <id|ref>] <title>
cmux move-workspace-to-window --workspace <id|ref> --window <id|ref>
cmux reorder-workspace --workspace <id|ref> (--index <n> | --before <id|ref> | --after <id|ref>)
```

## Tab actions (horizontal tabs inside a pane)

```bash
cmux tab-action --action <name> [--tab <id|ref>] [--surface <id|ref>] [args...]
# actions: rename, clear-name, close-left, close-right, close-others,
#          new-terminal-right, new-browser-right, reload, duplicate,
#          pin, unpin, mark-unread
cmux rename-tab [--tab <id|ref>] <title>
```

## Synchronization (tmux-compat)

```bash
cmux wait-for [-S|--signal] <name> [--timeout <seconds>]
# wait-for blocks until something else calls wait-for -S <name>
```

## Agent integrations

```bash
cmux setup-hooks                # install hooks for ALL supported agents
cmux uninstall-hooks            # remove all
# per-agent install: codex, opencode, cursor, gemini, copilot, codebuddy, factory, qoder
cmux <agent> install-hooks
cmux <agent> uninstall-hooks

# launchers (forward remaining args to the underlying tool)
cmux claude-teams [claude-args...]
cmux omc [omc-args...]
cmux omo [opencode-args...]
cmux omx [omx-args...]

# hook handlers (called by agent hook scripts; you usually don't run these directly)
cmux claude-hook <session-start|stop|notification|prompt-submit|session-end|pre-tool-use>
cmux codex-hook <session-start|prompt-submit|stop>
cmux <agent>-hook <event>      # opencode, cursor, gemini, copilot, codebuddy, factory, qoder
```

## Browser automation (when you have a browser pane)

```bash
cmux browser open [--url <url>] [--workspace <id|ref>] [--split <l|r|u|d>]
cmux browser navigate <url>     # alias: goto
cmux browser back | forward | reload
cmux browser snapshot           # accessibility-tree DOM dump
cmux browser eval "<js>"
cmux browser click <selector>
cmux browser fill <selector> <text>
cmux browser type <selector> <text>
cmux browser get url|title|text|html|value|attr|count|box|styles
cmux browser is visible|enabled|checked
cmux browser wait selector|text|url|load|js
cmux browser cookies get|set|clear
cmux browser screenshot --output <path>
cmux browser viewport <w>x<h>
cmux browser network route|unroute|list
# legacy aliases: open-browser, navigate, browser-back/forward/reload, get-url
```

## tmux compatibility aliases (for porting tmux scripts)

```bash
cmux capture-pane         # = read-screen
cmux send-keys            # = send
cmux split-window         # = new-split
cmux select-pane          # = focus-pane
cmux select-window        # = select-workspace
cmux next-window | previous-window | last-window
cmux last-pane
cmux clear-history        # clear scrollback on a surface
cmux respawn-pane --command <cmd>
cmux pipe-pane --command <shell-command>
cmux resize-pane --pane <id|ref> -L|-R|-U|-D --amount <n>
cmux swap-pane --pane <id|ref> --target-pane <id|ref>
cmux break-pane           # extract pane → new workspace
cmux join-pane --target-pane <id|ref>
cmux set-buffer <text> | paste-buffer | list-buffers
cmux set-hook <event> <command> | --list | --unset <event>
```

## Themes, settings, misc

```bash
cmux themes [list|set <theme>|set --light <t> --dark <t>|clear]
cmux reload-config
cmux refresh-surfaces
cmux markdown open <path>           # open file in formatted viewer with live reload
cmux feedback [--email <e> --body <b> --image <path> ...]
cmux welcome
cmux shortcuts                      # opens settings → keyboard shortcuts
cmux restore-session
```

## Auth and cloud (Founder's Edition / app-driven)

```bash
cmux auth status [--json]
cmux auth login | logout
cmux vm ls | new | shell | rm | ssh | exec      # cloud is an alias for vm
```

## Raw socket call (for unsupported methods)

```bash
cmux rpc <method> [json-params]    # invoke any v2 RPC method directly
```

## Patterns to remember

- **Use `--json` whenever scripting.** Default output is human-readable text and changes between versions.
- **Pass refs not indexes** in scripts — indexes shift when workspaces are reordered.
- **`cmux <path>` auto-launches** the app if needed; safe in startup scripts.
- **`< /dev/null`** redirect when calling cmux from a hook that runs under a profile-heavy shell, to avoid prompt hangs.
- **`cmux send` requires explicit `\n`** to actually submit a command. `cmux send "ls"` types `ls` and stops; `cmux send "ls\n"` runs it.
