# go-outbox

`go-outbox` is a PostgreSQL-first Go implementation of the transactional
outbox pattern. It writes application state and publishable envelopes in the
same caller-owned `pgx` transaction, then relays committed envelopes to a
small publisher contract with at-least-once delivery.

Version 1 guarantees the compatibility surfaces described in
[the compatibility policy](docs/compatibility.md). Delivery remains at least
once; upgrading the library does not remove the consumer's idempotency duty.

## Guarantees

- Atomic application and outbox persistence only when both writes use the
  same successful `pgx.Tx`.
- At-least-once relay delivery. Publisher acceptance followed by a failed or
  ambiguous delivered update can publish the same envelope again.
- Concurrent claims use PostgreSQL row locks and `SKIP LOCKED`.
- Every mutation of a leased record requires its current opaque lease token.
- Batch, worker, lease, retry, administrative, payload, and polling limits are
  explicit and bounded.
- Optional ordering-key or topic serialization is enforced at the PostgreSQL
  claim seam across relay processes. There is no global ordering guarantee.

Consumers **must be idempotent**. This project does not provide distributed
transactions or exactly-once delivery.

## Packages

- `github.com/faustbrian/go-outbox`: envelope construction and validation.
- `github.com/faustbrian/go-outbox/postgres`: migrations, transactional writer,
  claims, leases, retries, dead letters, replay, and retention.
- `github.com/faustbrian/go-outbox/relay`: bounded embedded relay.
- `github.com/faustbrian/go-outbox/adapters/goqueue`: separately versioned
  `go-queue` publisher adapter; importing core does not add `go-queue`.
- `github.com/faustbrian/go-outbox/adapters/gotelemetry`: separately versioned
  metrics and trace-linkage integration compatible with `go-telemetry`.

## Quick start

```go
builder, err := outbox.NewEnvelopeBuilder()
if err != nil {
    return err
}

envelope, err := builder.Build(outbox.NewEnvelopeParams{
    Topic:          "orders.created",
    Payload:        payload,
    OrderingKey:    customerID,
    IdempotencyKey: commandID,
})
if err != nil {
    return err
}

tx, err := pool.Begin(ctx)
if err != nil {
    return err
}
defer tx.Rollback(ctx)

if _, err := tx.Exec(ctx, insertOrderSQL, orderID); err != nil {
    return err
}
writer, err := postgres.NewWriter(postgres.WriterConfig{})
if err != nil {
    return err
}
if err := writer.Insert(ctx, tx, envelope); err != nil {
    return err
}

return tx.Commit(ctx)
```

The writer never opens or commits a transaction. Passing a pool or standalone
connection is impossible because the API requires `pgx.Tx`.

See the [documentation index](docs/README.md),
[full quickstart](docs/quickstart.md), [delivery guarantees](docs/guarantees.md),
and [architecture and crash matrix](docs/architecture.md).

## Development gates

```sh
go test ./...
go test -race -tags=integration ./...
go test -tags=integration -coverprofile=coverage.out ./...
(cd adapters/goqueue && go test -race ./...)
```

Integration tests use ephemeral Testcontainers PostgreSQL instances. They do
not use an existing application or production database.

## Status

Version 1 includes the core state machine, concurrency tests, payload-safe
lifecycle events, health diagnostics, PostgreSQL backlog statistics,
`go-queue` and telemetry adapters, CI matrices, fuzzing, benchmarks, and
archive-before-delete retention.

## License

MIT. See [LICENSE](LICENSE).

Contribution, conduct, support, and vulnerability-reporting policies are in
[CONTRIBUTING.md](CONTRIBUTING.md),
[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), [SUPPORT.md](SUPPORT.md), and
[SECURITY.md](SECURITY.md).
