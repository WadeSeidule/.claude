---
name: cost-check
description: Estimate infrastructure cost impact of IaC changes by analyzing Terraform plans, CDK diffs, Databricks cluster configs, and Kubernetes resource requests. Use when reviewing infra PRs or planning resource changes.
disable-model-invocation: true
---

# Infrastructure Cost Check

Estimate cost impact of infrastructure changes.

## Arguments

- `scope`: PR number, branch name, or "current" for uncommitted changes

## Workflow

### Step 1: Identify infrastructure changes

Scan the diff for:
- Terraform files (`.tf`) — instance types, storage, scaling configs
- CDK constructs — new resources, changed instance classes
- Kubernetes manifests — resource requests/limits changes
- Databricks configs — cluster sizes, instance types, auto-scaling ranges
- Airflow configs — worker counts, resource allocations

### Step 2: Analyze cost-relevant changes

For each changed resource, extract:
- **Before**: current config (from base branch or running state)
- **After**: proposed config
- **Delta**: what changed (instance type, count, storage, etc.)

### Step 3: Estimate impact

Use known pricing patterns:
- AWS instance types → approximate hourly/monthly cost
- EBS volumes → per-GB/month
- Databricks DBUs → per-hour by instance type
- Kubernetes resource requests → map to node capacity impact

### Step 4: Output cost summary

```
## Cost Impact Estimate

| Resource | Change | Before | After | Monthly Delta |
|----------|--------|--------|-------|---------------|
| [resource] | [what changed] | [cost] | [cost] | [+/- amount] |

**Net monthly impact**: [+/- total]

### Recommendations
- [any cost optimization suggestions]
```

Note: These are rough estimates. For precise costs, check AWS Cost Explorer or Databricks account usage.
