---
name: post-review
description: Post agent code review feedback to a GitHub PR as a pending review with inline comments anchored to the changed code. Use this skill whenever an agent (code-reviewer, security-scanner, pr-test-analyzer, silent-failure-hunter, comment-analyzer, type-design-analyzer, or any review-style agent) has produced findings that need to land on a GitHub PR. Translates findings into inline comments on the corresponding lines, rewrites them in a concise human voice, leaves the review in PENDING state (does NOT submit), and prints the URL so the user can read and click Submit themselves in the GitHub UI. Trigger on phrases like "post this review to PR #123", "publish the review on the PR", "put these comments on the GitHub PR", "post the agent feedback to GitHub", "land this review on the PR", or any time you've just finished an agent code review and GitHub is the destination.
disable-model-invocation: false
---

# post-review

Take the output of an agent code review and land it on a GitHub PR as a **pending** review made of inline comments. Do not submit it — the user opens the URL and clicks Submit themselves after reading.

## When to use

- After any review-style agent (code-reviewer, security-scanner, silent-failure-hunter, pr-test-analyzer, comment-analyzer, type-design-analyzer, custom review agents) produces findings that need to reach a teammate.
- When the user says "post this to the PR", "publish the review", "put these comments on GitHub", "land the review on PR #N".
- After `/review`, `/security-review`, `/code-review:code-review`, `/pr-review-toolkit:review-pr`, or `/ultrareview` — when their output is ready to share.

Do **not** use this skill to leave a single drive-by comment on a PR (`gh pr comment` is fine for that), or to post a review that should be submitted immediately and visibly. This skill is specifically for staging a multi-comment review for the user to sign off on.

## What you need before posting

1. **The PR ref** — owner, repo, and PR number, or a PR URL. If the user didn't say, infer from the current branch with `gh pr view --json number,headRepository,headRepositoryOwner -q '{n:.number, owner:.headRepositoryOwner.login, repo:.headRepository.name}'`. If that returns nothing, ask once.
2. **The PR's head commit SHA** — needed so comments anchor to the right revision:
   ```bash
   gh pr view <num> --repo <owner>/<repo> --json headRefOid -q .headRefOid
   ```
3. **The review findings** — usually already in the agent's output. Each actionable finding needs a file path and a line number that's part of the diff. Findings without a line (architectural notes, scope concerns, summary) go in the review `body`, not as inline comments.

## Comments must be inline against the corresponding code

Every actionable finding becomes a comment on the **specific line** in the **specific file** the finding is about — the line a reviewer would point at if they were reading the diff in the browser. That's the entire reason this is more useful than pasting the agent's output into a PR comment box: the reader sees each note exactly where the problem lives.

- Single line: pass `path` + `line`. `side` defaults to `RIGHT` (the new version), which is what you want unless commenting on a removed line.
- Multi-line range: pass `path` + `start_line` + `line` (and matching `start_side`/`side`).
- Removed line: pass `side: "LEFT"`.
- Doesn't pin to a hunk (overall verdict, scope feedback): put it in the top-level review `body`, not in `comments[]`.

If a finding is about an unchanged line that isn't part of the diff, GitHub will reject it (`pull_request_review_thread.line must be part of the diff`). Either move that finding to the body, or anchor it to the nearest changed line and reference the unchanged line in the comment text ("the helper at line 42 above…").

## Voice: human, friendly, concise, direct

Comments should read like a colleague leaving a note, not a compliance report. The reader is a busy human — keep notes short, plain, and pointed at the actual thing.

**Do:**
- One or two sentences. Say what's off and (when not obvious) what to do about it.
- Phrase as observations or light suggestions: "Worth using…", "This will throw if…", "Could pull this into…", "Any reason not to…".
- Name the actual identifier (`userId`, `parseTimestamp`) in backticks.
- Lead with the issue. The reader can see the line.

**Don't:**
- No "🚨", "❌", "✅" or other emoji unless the user asked for them.
- No "Great work, but…" preambles. No "I would gently suggest perhaps…". No "It might be worth considering whether…".
- No restating the code at the reader — they wrote it.
- No general principles or lectures. Stay specific to this line.
- No "**Summary:**" or grade-school structure. The PR description handles framing.
- No author flattery, no apologising for the comment, no "feel free to ignore".

### Examples

Agent finding: *"The function `parseTimestamp` does not handle the case where the input string is empty, which could lead to a runtime exception."*

❌ Flowery:
> 💭 I noticed that the `parseTimestamp` function as currently implemented may not gracefully handle scenarios where an empty string is provided as input. It would be wonderful if we could add some defensive validation here to ensure robustness! Great work otherwise though!

✅ Human:
> Empty string falls through and throws — worth an early return or a `default` branch.

---

Agent finding: *"SQL query is constructed via string concatenation with user-supplied input."*

❌ Alarmist:
> 🚨 CRITICAL SECURITY VULNERABILITY 🚨 SQL Injection!!!

✅ Human:
> `userId` comes straight from the request — needs to be a parameter, not concatenated.

---

Agent finding: *"This block of code duplicates logic from `helpers.ts`."*

✅ Human:
> Same logic as `formatRange` in `helpers.ts` — pull from there?

---

Agent finding: *"Missing test coverage for the error path."*

✅ Human:
> No test for the `404` branch — easy to add alongside the existing happy-path test.

## How to post (PENDING state)

POST to the reviews endpoint with `gh api`. **Omit the `event` field entirely** — that's what keeps the review pending. Including `event: "COMMENT"`, `"APPROVE"`, or `"REQUEST_CHANGES"` would submit it immediately, which is the opposite of what we want.

```bash
PR=123
OWNER=acme
REPO=widgets
COMMIT=$(gh pr view "$PR" --repo "$OWNER/$REPO" --json headRefOid -q .headRefOid)

gh api -X POST "repos/$OWNER/$REPO/pulls/$PR/reviews" --input - <<EOF | jq -r '.html_url'
{
  "commit_id": "$COMMIT",
  "body": "A few notes from a pass over the diff — nothing blocking.",
  "comments": [
    {
      "path": "src/auth/session.go",
      "line": 42,
      "body": "Empty string falls through and throws — worth an early return."
    },
    {
      "path": "src/db/query.go",
      "line": 88,
      "body": "\`userId\` comes straight from the request — parameterize this."
    },
    {
      "path": "src/db/query.go",
      "start_line": 95,
      "line": 102,
      "body": "Same logic as \`formatRange\` in helpers.ts — pull from there?"
    }
  ]
}
EOF
```

Notes on the call:
- `--input -` reads JSON from stdin. Cleaner than building nested arrays with `-f` flags.
- The heredoc is unquoted (`<<EOF`, not `<<'EOF'`) so `$COMMIT` interpolates. Backticks inside the JSON must be escaped as `\``.
- Pipe through `jq -r '.html_url'` to extract just the link.
- `body` on the review is optional — if there's no overall framing to add, omit it.

## What to print to the user

Print the URL on its own line, then one short sentence confirming it's pending. Nothing else. Don't summarize the comments back — the user will see them in the UI.

```
https://github.com/acme/widgets/pull/123#pullrequestreview-2345678
Pending review created. Open the URL and click Submit when you're ready.
```

## Common pitfalls

- **Line not part of the diff.** GitHub rejects comments on lines outside the diff hunks. If a finding is about unchanged code, put it in the review `body` or anchor to the nearest changed line.
- **Forgot `commit_id`.** Without it the API uses the latest, which usually works but can drift if the PR gets new commits between fetching and posting. Always pin to the head SHA you read.
- **Accidentally submitted.** If you ever pass `event` in the JSON, the review goes live immediately. There is no `event` field anywhere in the call you write.
- **Too many comments.** If the agent produced 30 findings and 20 are nits, ask the user before dumping all of them. The reviewer on the receiving end has to read every one.
- **`body` missing on a comment.** A comment without `body` returns 422. Every entry in `comments[]` needs `path`, a line anchor, and `body`.
- **Wrong repo.** If the user is on a fork branch, `gh pr view` may resolve to the fork. Double-check `OWNER/REPO` matches the upstream PR.

## When you're done

Print the URL. One short line confirming pending state. Stop.
