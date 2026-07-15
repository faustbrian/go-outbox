# Kubernetes Operations And Capacity

Run the relay embedded or as a Deployment. Give every pod a unique `Owner`.
Multiple pods coordinate through `SKIP LOCKED`; leader election is unnecessary.
Use `maxUnavailable: 0` and a termination grace period longer than the longest
publisher call plus `TransitionTimeout`. Cancellation stops polling; hard-kill
recovery waits for lease expiry.

Readiness should call `Relay.Readiness`. Liveness should report process health,
not dependency health, to avoid restart storms. Protect replay and retention
endpoints with application authentication and authorization.

Maximum in-flight work is approximately `replicas * Workers`; one claim cycle
leases at most `replicas * BatchSize`. Keep leases longer than high-percentile
publisher latency plus scheduling pauses. Check broker quotas, PostgreSQL
connections, and ordering contention before scaling.

Collect `Store.Backlog` at low frequency. Alert on oldest pending age,
sustained depth growth, dead-count growth, readiness failure, retry rate, and
publish latency. Calibrate thresholds to the service SLO; a useful starting
point is oldest age above twice normal publish latency for three intervals.

Keep pending and leased rows a small hot set. Run bounded archive/prune jobs,
vacuum normally, and benchmark representative payload sizes. Before large
rollouts, use `EXPLAIN (ANALYZE, BUFFERS)` on claim and retention queries with
production-shaped data. Configure statement and lock timeouts. A timeout is
not proof that an ambiguous database operation failed.
