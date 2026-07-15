# Security Policy

## Supported versions

The latest v1 release receives security fixes. Fixes first land on the default
branch and are then included in a supported patch release.

## Reporting

Report vulnerabilities privately through GitHub's security advisory workflow.
Do not open a public issue containing credentials, payloads, exploit details,
or tenant data.

## Operational responsibilities

- Restrict database roles to the required schema and statements.
- Treat payloads and metadata as sensitive; do not include them in logs,
  metrics, traces, or support tickets.
- Authorize replay and retention outside the library and audit every operator.
- Use TLS and authenticated connections to PostgreSQL and publishers.
- Keep consumers idempotent and bound their own retries.

Lease tokens prevent stale transitions but do not authorize callers. Replay
request fields provide audit context but do not replace application access
control.
