# Security And Hardening Audit

Protected properties are committed-record durability, lease ownership,
bounded resources, operator accountability, and payload confidentiality.
Threats include process death, clock skew, database/publisher ambiguity, stale
workers, poison payloads, replay abuse, premature deletion, tenant escape, and
diagnostic disclosure.

| Severity | Finding | Disposition |
|---|---|---|
| High | Mandatory history could be deleted before archival. | Closed by archive-before-delete with rollback on hook failure. |
| High | A stale relay could acknowledge a newer lease. | Closed by generation tokens and PostgreSQL tests. |
| Medium | Diagnostics could disclose payload or error content. | Closed by typed safe events and disclosure tests. |
| Medium | A diagnostic callback panic could interrupt delivery. | Closed by observer and slog-handler containment tests. |
| Medium | Health and queue pressure were indistinguishable. | Closed by readiness and backlog statistics. |
| Medium | Cross-process ordering could be overstated. | Closed by database serialization and scoped documentation. |

Consumer idempotency, credentials, TLS, broker policy, and tenant authorization
remain application responsibilities. This report alone is not a release
verdict. Any red gate, record-loss path, false exactly-once claim, premature
deletion, or unproven released-schema upgrade blocks release.

## Release-candidate verdict (2026-07-15)

The local release candidate passes `make check` and independent
`make integration POSTGRES_VERSION=N` runs for PostgreSQL 14, 15, 16, 17, and
18. This includes format/module drift, GO-SAFETY-1, vet, cgo-disabled tests,
integration and race tests, meaningful 100% production coverage for all three
modules, fuzzing, allocation benchmarks, documentation, and `govulncheck`.
Relay tests also run goroutine-leak detection, and PostgreSQL integration proves
initial migration rollback plus claim/retention index plans on representative
terminal-heavy data.
CI runs each publisher/telemetry adapter as a workspace-disabled matrix entry,
including module drift, race detection, and coverage.
The duplicate window is executable rather than documentary: a real store is
faulted after publisher acceptance, then lease expiry proves the second
acceptance and final delivered state.
Graceful cancellation is also exercised through the full relay and PostgreSQL
path, proving a blocked publisher returns its row to pending without a lease
token by using the detached cleanup context.
Every PostgreSQL store transition also has a deterministic canceled-context
case that proves no durable state or audit mutation occurs before the matching
successful recovery path.

The coordinated publication procedure is:

1. tag and push the verified core module;
2. replace adapter `replace` directives with that released core SemVer;
3. run adapter module checks without the workspace; and
4. tag the adapters only after their GitHub Actions matrices pass.

Residual contract risks remain expected: publisher acceptance followed by an
ambiguous database result can duplicate delivery; replay and disaster restore
can duplicate delivery; an archive can be written twice after ambiguous commit;
and consumer idempotency, authorization, credentials, and transport security
remain application responsibilities.
