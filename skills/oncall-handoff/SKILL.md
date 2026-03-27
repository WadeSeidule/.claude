---
name: oncall-handoff
description: Generate an oncall handoff summary by pulling recent Datadog incidents, firing monitors, Airflow DAG failures, and Kubernetes events. Use at end of oncall shift or when preparing a handoff.
disable-model-invocation: true
---

# Oncall Handoff Summary

Generate a comprehensive handoff document for oncall rotation.

## Arguments

- `period`: Time period to summarize (default: past 24 hours)
- `team`: Team or service area to focus on (optional)

## Workflow

### Step 1: Gather data (run in parallel)

1. **Datadog incidents**: Search for recent incidents, get status and resolution
2. **Datadog monitors**: List currently firing or warning monitors
3. **Airflow**: Check for failed DAG runs in the period
4. **Kubernetes**: Check for pod restarts, OOMKills, and CrashLoopBackOff across namespaces
5. **GitHub**: Check for recent deployments (merged PRs to main) that might correlate with issues

### Step 2: Categorize

Group findings into:
- **Active issues**: Still ongoing, needs attention
- **Resolved**: Fixed during shift, note what was done
- **Recurring**: Known issues that keep coming back
- **Deployments**: Recent changes that could cause problems

### Step 3: Output handoff document

```
## Oncall Handoff — [date range]

### Active Issues (needs attention)
- **[issue]**: [status, what's been tried, next steps]

### Resolved This Shift
- **[issue]**: [what happened, how it was fixed]

### Recurring / Known Issues
- **[issue]**: [frequency, workaround, tracking ticket]

### Recent Deployments
- [repo]#[PR] — [description] — merged [time]

### Monitors to Watch
- [monitor name]: [current state, why it matters]

### Notes for Next Oncall
- [anything the next person should know]
```
