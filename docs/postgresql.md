# PostgreSQL Schema And Operations

## Migrations

`postgres.Migrations()` returns an `fs.FS` rooted at versioned `.up.sql` and
`.down.sql` files. A migration runner, including `go-migrations`, can consume
that filesystem without exposing Goose to application code.

The initial schema creates `outbox_messages`, its hot-set and retention
indexes, and immutable `outbox_replay_audit` rows. Apply migrations before
constructing a writer or relay store. Schema and delivery-semantics changes are
SemVer-sensitive public contracts.

The embedded SQL targets `public.outbox_messages` and
`public.outbox_replay_audit`. `WriterConfig` and `StoreConfig` can select a
different schema or message table, but the application then owns an equivalent
versioned migration. Keep the replay audit table in the selected schema, retain
all constraints and indexes, and test every transition against that layout.
Configuration does not rewrite embedded migration SQL.

## States and important columns

- `pending`: eligible after `available_at`; no lease or terminal timestamp.
- `leased`: owner, opaque token, and expiry are all present.
- `delivered`: `delivered_at` is present and lease fields are clear.
- `dead`: `dead_lettered_at` is present and lease fields are clear.

Database constraints reject inconsistent state-field combinations, negative
attempts, empty identifiers/topics, and invalid payload versions.

## Indexes

- `outbox_messages_claim_idx`: available/created/ID order for the non-terminal
  hot set.
- `outbox_messages_lease_expiry_idx`: expired lease recovery.
- `outbox_messages_ordering_idx`: non-empty ordering-key serialization.
- delivered and dead retention indexes: bounded terminal maintenance.
- partial unique idempotency index: non-empty writer keys only.

Keep pending and leased rows a small fraction of retained history. Monitor
query plans and vacuum behavior at representative backlog sizes.

Integration tests seed a terminal-heavy table and assert that both the claim
hot-set query and delivered-retention query avoid sequential scans and use the
partial indexes on every supported PostgreSQL major.

## Claim coordination

Claims run as one CTE update using `FOR UPDATE SKIP LOCKED`. Concurrent relay
instances obtain disjoint records without a coordinator. Scoped ordering adds
a correlated earliest-non-terminal predicate before locking; it does not add a
global lock.

Lease deadlines use the database clock. Late updates require the original
token and affect exactly one still-leased row or return `ErrLeaseLost`.

## Retention and archival

Pruning is intentionally limited to delivered or dead rows older than a
supplied cutoff through separate APIs. Never delete pending or leased rows,
even when they appear old. Retaining or archiving dead letters preserves
incident evidence; deleting them also removes their replay source.

Use `ArchiveAndPruneDelivered` when policy requires archive-before-delete. It
locks a bounded terminal batch with `SKIP LOCKED`, calls the supplied archive
hook while the transaction remains open, and deletes only after success.
Archive implementations must deduplicate by envelope ID because a successful
archive followed by an ambiguous PostgreSQL commit can repeat the hook.

Use `PruneDelivered` only when direct permanent deletion is intentional.
The parallel dead-letter APIs are `ArchiveAndPruneDead` and `PruneDead`.

## Partitioning

Partitioning is optional. Start with an unpartitioned table and the partial
indexes above. Consider time-based partitions only when retained terminal
history, vacuum cost, or maintenance windows justify the operational burden.

Partition boundaries must not allow dropping a partition containing pending,
leased, or retained dead records. Route and verify all supported state
transitions against partition keys before adopting partitioning.

## Timeouts and connections

Use primary read-write connections. Configure context deadlines plus sensible
PostgreSQL `statement_timeout` and `lock_timeout` values at the application
boundary. Do not run writers or relays against replicas or read-only sessions.

Pool sizing must account for relay worker concurrency, application
transactions, and administrative operations. Workers publish outside a
database transaction; leases bound recovery if publication stalls.
