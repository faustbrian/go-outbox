# Troubleshooting And FAQ

- **Duplicate publication:** expected after ambiguous publisher acceptance,
  delivered-update failure, lease expiry, or replay. Verify consumer dedupe.
- **Later record not claimed:** an earlier scheduled non-terminal record can
  block its ordering key or topic.
- **`ErrLeaseLost`:** the token expired, was reclaimed, or already transitioned.
  Inspect state; do not force the update.
- **Healthy readiness but growing backlog:** readiness proves round trips, not
  capacity. Check latency, quotas, retries, ordering, connections, and plans.
- **Read replica:** never use one for claims or transitions; target the same
  writable-primary path in readiness.
- **Pool instead of transaction:** not supported. Application and outbox writes
  must use the exact same caller-owned `pgx.Tx`.
- **Idempotency key:** prevents duplicate non-empty inserts only; it does not
  cover broker acceptance or consumer effects.
