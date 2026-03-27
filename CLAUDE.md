# Claude Code Instructions

## Behavioral Rules

- Do what has been asked; nothing more, nothing less
- NEVER create files unless they're absolutely necessary for achieving your goal
- ALWAYS prefer editing an existing file to creating a new one
- NEVER proactively create documentation files (*.md) or README files unless explicitly requested
- ALWAYS read a file before editing it

## Concurrency

- ALWAYS batch ALL file reads/writes/edits in ONE message
- ALWAYS batch ALL Bash commands in ONE message

## Git/GitHub Behaviors

- Always open PRs in draft mode
- Follow conventional commit format for both commit messages and PR titles
- If a repo has a PR lint workflow, validate that type and scopes are valid for the repo

## Security Rules

- NEVER hardcode API keys, secrets, or credentials in source files
- NEVER commit .env files or any file containing secrets
- Always validate user input at system boundaries

## Kubernetes

- A PreToolUse hook guards kubectl — local contexts (kind-*, orbstack) auto-allow; staging/prod contexts prompt for destructive commands
- NEVER run destructive kubectl commands (delete, apply, scale, drain) in production without confirmation

## Observability & Internal Tools

- Datadog, Grafana, and Glean are available as MCP servers — use them for log analysis, dashboards, and internal search
- Databricks CLI is available for job/cluster/warehouse operations
- Airflow REST API is accessible via the airflow skill
- Oz (ozctl) is used for launching debug pods in Kubernetes

## Airflow & Databricks Safety

- Default to READ-ONLY operations (list, get, describe, status, logs)
- NEVER trigger DAG runs, pause/unpause DAGs, clear task instances, or modify Airflow variables/connections unless the user explicitly asks
- NEVER start/stop/delete clusters, trigger job runs, create/modify jobs, alter warehouse state, or write to DBFS/Unity Catalog via Databricks CLI or MCP unless the user explicitly asks
- When in doubt, show the command you would run and ask for confirmation
