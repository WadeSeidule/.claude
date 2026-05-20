# cmux workflow recipes

Concrete, copy-pasteable patterns. Each is composed from CLI primitives — cmux itself is unopinionated about workflow.

## 1. Worktree-per-feature

The default. Use `cmux-worktree` (bundled in this skill, installed at `~/.local/bin/cmux-worktree`).

```bash
# create
cmux-worktree new fix-cache-leak -d "race condition in LRU eviction"

# tear down (after PR merged)
cmux-worktree done fix-cache-leak
```

What it does under the hood:

```bash
git worktree add -b feat/fix-cache-leak ../$(basename $PWD)-fix-cache-leak
cmux new-workspace \
  --cwd "../$(basename $PWD)-fix-cache-leak" \
  --name "fix-cache-leak" \
  --description "race condition in LRU eviction" \
  --command "claude"
```

The `--command` runs after the workspace exists, so the agent starts in the worktree's cwd with the right branch.

## 2. Race three agents on one bug

Different agents, different worktrees, same prompt. Whoever finishes first wins.

```bash
TASK="fix the memory leak in src/cache.ts and write a regression test"
for agent in claude codex opencode; do
  cmux-worktree new "leak-${agent}" \
    -d "race: ${agent}" \
    -a "${agent} '${TASK}'"
done
# ⌘⇧U cycles to whichever finishes first.
# After picking a winner:
cmux-worktree done leak-codex
cmux-worktree done leak-opencode
# Keep claude's worktree, gh pr create from it.
```

## 3. CI watcher that pings the right workspace

Run this once in any workspace; it'll annotate the workspace whose branch matches a failing CI run.

```bash
# poll-ci.sh
while true; do
  failed=$(gh run list --status failure --limit 1 --json headBranch --jq '.[0].headBranch')
  if [ -n "$failed" ]; then
    ws=$(cmux list-workspaces --json | \
         jq -r ".[] | select(.branch == \"$failed\") | .ref")
    if [ -n "$ws" ]; then
      cmux notify --workspace "$ws" \
        --title "CI failed" --body "branch $failed"
      cmux set-status --workspace "$ws" "ci-failed" --color red
    fi
  fi
  sleep 60
done
```

## 4. Hand a finding from one agent to another

Agent A finds a bug, dispatches it to Agent B in another workspace.

```bash
# from inside agent A's pane
finding=$(cat << 'EOF'
TypeError in src/parser.ts:142 — `node.children` is undefined when node.kind === "leaf".
Please add a guard and a test.
EOF
)
cmux send --workspace workspace:5 -- "${finding}\n"
```

## 5. Observe an agent without joining its pane

```bash
# tail the last 200 lines of scrollback from workspace 5
cmux read-screen --workspace workspace:5 --scrollback --lines 200

# or watch live
while true; do
  cmux read-screen --workspace workspace:5 --lines 40
  sleep 5
  clear
done
```

## 6. Browser-aided dev loop

Split a browser pane next to your terminal. The agent can drive the browser through `cmux browser ...` and snapshot the rendered page.

```bash
cmux new-pane --type browser --direction right --url http://localhost:3000
# now in the agent's pane:
cmux browser snapshot                    # accessibility tree
cmux browser screenshot --output /tmp/before.png
cmux browser click "button[type=submit]"
cmux browser wait text "Saved"
cmux browser screenshot --output /tmp/after.png
```

## 7. SSH-backed remote workspace

```bash
cmux ssh user@remote-dev --name "remote-staging"
```

Browser panes opened in the remote workspace route through the remote machine's network — `localhost:3000` resolves to the remote server's port. Drag-and-drop image upload uses scp under the hood.

## 8. Pin the on-call workspace

```bash
ws=$(cmux current-workspace --json | jq -r '.ref')
cmux workspace-action --action pin --workspace "$ws"
cmux workspace-action --action set-color --workspace "$ws" --color "#ef4444"
cmux rename-workspace --workspace "$ws" "🚨 oncall"
```

## 9. Synchronize two scripts via wait-for

```bash
# script A: blocks until B signals
cmux wait-for --timeout 600 build-done
echo "build is done, deploying..."

# script B: signals when ready
make build && cmux wait-for -S build-done
```

## 10. JSON pipeline for handle resolution

```bash
# get the workspace ref for branch "fix/cache-leak"
ws=$(cmux list-workspaces --json | \
     jq -r '.[] | select(.branch == "fix/cache-leak") | .ref')

# get the surface ref for the only surface in that workspace
sf=$(cmux list-pane-surfaces --workspace "$ws" --json | jq -r '.[0].ref')

# now drive it
cmux send --surface "$sf" -- "make test\n"
```

## Anti-patterns

- **Two worktrees in one workspace via splits** — sidebar metadata is per-workspace, so the second worktree is invisible. Use two workspaces.
- **`cmux close-workspace` mid-edit** — no undo. Use `cmux-worktree done` (which checks for uncommitted changes) or notify first.
- **Indexes in long-running scripts** — `workspace:2` becomes `workspace:3` when something is added before it. Resolve once, store the UUID.
- **`cmux send "ls"` without `\n`** — it types `ls` and waits forever. Add `\n` to actually run.
- **Forgetting `cmux setup-hooks`** — without it, no agent rings, no notifications, no progress bars.
