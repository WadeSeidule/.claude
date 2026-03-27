---
name: dataflow-debug
description: Debug Nextdoor data pipelines by combining Airflow DAG status, Datadog logs/traces, and Databricks job runs into a single investigation workflow. Use when user mentions a failing pipeline, DAG, job, or data issue.
disable-model-invocation: true
---

# Dataflow Pipeline Debugger

Investigate data pipeline issues across Airflow, Databricks, and Datadog in a structured workflow.

## Arguments

- `pipeline`: Pipeline name, DAG ID, or Databricks job name to investigate
- `timeframe`: How far back to look (default: past 24 hours)

## Workflow

### Step 1: Identify the pipeline layer

Determine which system(s) are involved:
- **Airflow DAG**: Check DAG run status, task instance states, and task logs via the airflow skill
- **Databricks job**: Check job run status, cluster health, and driver logs via `databricks` CLI
- **Both**: Many pipelines trigger Databricks jobs from Airflow — check the full chain

### Step 2: Gather failure context

Run these in parallel where possible:

1. **Airflow** (use the airflow skill):
   - Get recent DAG runs and their states
   - Find the failed task instance
   - Pull task logs for the failure

2. **Databricks** (use `databricks` CLI):
   - List recent job runs: `databricks jobs list --output json | jq '.[] | select(.settings.name | contains("<pipeline>"))'`
   - Get run details: `databricks runs get --run-id <id>`
   - Check cluster events if OOM/timeout suspected

3. **Datadog** (use Datadog MCP):
   - Search logs for the pipeline name with error/exception filters
   - Check relevant traces for latency spikes
   - Look at related monitors/alerts

### Step 3: Correlate and diagnose

- Match timestamps across systems to find the root cause
- Common patterns:
  - **Airflow timeout → Databricks still running**: Airflow task timeout too low, or Spark job regressed
  - **Databricks OOM**: Check shuffle spill, partition skew (use spark-optimization skill)
  - **Airflow sensor timeout**: Upstream dependency not landing
  - **Connection error**: Check Okta/auth tokens, VPN, or service availability

### Step 4: Present findings

Output a summary:
- **Pipeline**: name and system(s)
- **Failure point**: which task/job/step failed
- **Root cause**: what went wrong
- **Logs**: key error messages
- **Suggested fix**: actionable next steps
