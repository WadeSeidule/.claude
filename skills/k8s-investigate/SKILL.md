---
name: k8s-investigate
description: Investigate Kubernetes pod/service issues by combining kubectl, Datadog traces, and Grafana dashboards. Use when user mentions pod crashes, service errors, OOMKills, restarts, or deployment issues.
disable-model-invocation: true
---

# Kubernetes Investigation

Structured investigation of Kubernetes issues combining kubectl, Datadog, and Grafana.

## Arguments

- `target`: Pod name, deployment, service, or namespace to investigate
- `namespace`: Kubernetes namespace (optional, will detect from context)

## Workflow

### Step 1: Assess current state

Run in parallel:
- `kubectl get pods -n <namespace> | grep <target>` — check pod status, restarts, age
- `kubectl describe pod <target> -n <namespace>` — events, conditions, resource limits
- `kubectl top pod <target> -n <namespace>` — current CPU/memory usage

### Step 2: Check logs

- `kubectl logs <pod> -n <namespace> --tail=200` — recent logs
- `kubectl logs <pod> -n <namespace> --previous` — if pod restarted, get previous container logs
- Look for: OOMKilled, CrashLoopBackOff, connection refused, timeout, auth errors

### Step 3: Correlate with observability

Run in parallel:
- **Datadog**: Search logs and traces for the service name, filter by error status
- **Grafana**: Check the service's dashboard for latency, error rate, and resource usage trends
- **Datadog monitors**: Check if any monitors fired for this service

### Step 4: Common patterns

| Symptom | Likely Cause | Action |
|---------|-------------|--------|
| OOMKilled | Memory limit too low or leak | Check resource limits, profile memory |
| CrashLoopBackOff | App crashing on startup | Check previous logs, config/secrets |
| ImagePullBackOff | Bad image tag or registry auth | Verify image exists, check pull secrets |
| Pending | No schedulable node | Check node resources, taints, PDBs |
| Connection refused | Service not ready or wrong port | Check readiness probe, service ports |
| 5xx from downstream | Dependency issue | Trace the request through Datadog |

### Step 5: If deeper access needed

- Use the oz skill to launch a debug pod in the namespace for interactive troubleshooting
- `ozctl create pod-access-request` for temporary shell access

### Step 6: Present findings

Output a summary:
- **Target**: pod/service and namespace
- **Status**: current state and recent events
- **Root cause**: what's going wrong
- **Evidence**: key log lines, metrics, traces
- **Suggested fix**: actionable next steps
