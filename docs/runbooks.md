# Recovery Runbooks

## Backlog or publisher outage

Record backlog, oldest age, readiness, retry rate, and publisher status. Leave
pending and leased rows intact; expired leases are recovery. Restore the
publisher, then increase concurrency gradually within broker and database
limits. Never replay pending or leased rows to accelerate draining.

## Dead letters and replay

Inspect ID, topic, attempts, timestamps, and `last_error` under restricted
access; never copy payload into logs or tickets. Fix the cause, authorize an
explicit bounded terminal-ID list, and call `Replay` with requester and
incident reason. Missing or non-terminal IDs fail atomically. Verify replay
audit rows and consumer deduplication. For an ambiguous response, inspect state
and audit before repeating.

Use `Store.Inspect` for bounded state/topic/time summaries. It deliberately
omits payload and metadata; direct database payload access should require a
separate, audited break-glass path.

## Retention incident

Pause maintenance. Where archival is mandatory, use only
`ArchiveAndPruneDelivered`. Hook failure preserves rows. Ambiguous commit can
archive again, so reconcile by envelope ID. `PruneDelivered` is only for
intentional permanent deletion.

Use `ArchiveAndPruneDead` before dead-letter deletion when incident evidence
must be retained. `PruneDead` is irreversible and removes replay capability.

## Disaster recovery

Restore application tables, outbox messages, and replay audit to one consistent
point. An older snapshot can republish formerly delivered records. Validate
schema, constraints, state counts, and lease timestamps, then resume one relay
and scale after normal draining. Never reconstruct records from broker state
without stable application identities and a reconciliation plan.
