---
name: incident-response
description: Structured incident investigation combining Datadog incidents/monitors, Grafana dashboards, kubectl status, and Airflow/Databricks job health. Use when user mentions an incident, outage, alert firing, pages, or service degradation.
disable-model-invocation: true
---

# Incident Response

Rapid incident investigation pulling from all observability sources.

## Arguments

- `service`: Service name, monitor name, or incident ID
- `severity`: Optional — sev1/sev2/sev3 to set urgency level

## Workflow

### Step 1: Gather signals (run in parallel)

1. **Datadog**:
   - Search incidents for the service name
   - Check firing monitors related to the service
   - Pull error logs from the last 30 minutes
   - Get recent traces with error status

2. **Grafana**:
   - Check the service's dashboard for anomalies
   - Look at error rate, latency p99, and throughput

3. **Kubernetes** (if applicable):
   - `kubectl get pods` for the service namespace — check for restarts, CrashLoopBackOff
   - `kubectl get events --sort-by='.lastTimestamp'` for recent cluster events

4. **Upstream dependencies**:
   - Check if Airflow DAGs feeding this service are healthy
   - Check if Databricks jobs this service depends on are running

### Step 2: Build timeline

Correlate timestamps across sources to build a timeline:
- When did the anomaly start?
- What changed? (deployments, config changes, upstream failures)
- What's the blast radius? (affected services, users, data)

### Step 3: Output incident brief

```
## Incident Brief

**Service**: [name]
**Started**: [timestamp]
**Status**: [active/mitigated/resolved]
**Impact**: [what's affected]

### Timeline
- HH:MM — [event]
- HH:MM — [event]

### Root Cause (suspected)
[description]

### Immediate Actions
- [ ] [action item]
- [ ] [action item]

### Related Links
- Datadog incident: [link]
- Grafana dashboard: [link]
- Runbook: [link if found]
```
