---
name: pr-preflight
description: Pre-flight check before creating a PR. Validates conventional commit format, checks CI status patterns, scans for secrets, reviews IaC changes, and ensures CLAUDE.md rules are followed. Use before creating or pushing a PR.
disable-model-invocation: true
---

# PR Pre-flight Check

Validate changes before creating a PR.

## Workflow

### Step 1: Analyze changes

- `git diff main...HEAD` — review all changes on the branch
- `git log main..HEAD --oneline` — check commit messages follow conventional commit format

### Step 2: Run checks (in parallel)

1. **Commit message format**:
   - Verify all commits use conventional format (`feat:`, `fix:`, `chore:`, `refactor:`, etc.)
   - Check if the repo has `.github/workflows/prlint.yml` and validate against its rules
   - Flag any commits that will fail PR lint

2. **Secret scan**:
   - Grep staged files for patterns: `AKIA`, `sk-`, `token=`, `password=`, `secret=`, `-----BEGIN`
   - Check for `.env` files in the diff
   - Flag any matches

3. **IaC review** (if changes include `.tf`, `cdk`, `k8s`, `helm` files):
   - Spawn the infra-reviewer agent for a quick review

4. **File hygiene**:
   - Check for accidentally committed large files (>1MB)
   - Check for debug/TODO comments added in the diff
   - Verify no lock files were modified without corresponding package changes

### Step 3: Generate PR metadata suggestion

- Suggest a PR title in conventional commit format
- Draft a PR description body from the commit log
- Flag if the PR should be marked as draft

### Step 4: Output report

```
## PR Pre-flight Report

**Branch**: [name]
**Commits**: [count]
**Files changed**: [count]

### Checks
- [ ] Commit format: PASS/FAIL
- [ ] Secret scan: PASS/FAIL
- [ ] IaC review: PASS/FAIL/SKIPPED
- [ ] File hygiene: PASS/FAIL

### Suggested PR Title
[title]

### Issues Found
[list or "None — ready to ship"]
```
