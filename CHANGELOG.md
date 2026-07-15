# Changelog

All notable changes to this project will be documented in this file. The
format follows Keep a Changelog, and releases follow Semantic Versioning.

Schema, envelope encoding, delivery semantics, exported errors, metrics, and
publisher contracts are public compatibility surfaces.

## [Unreleased]

## [1.0.0] - 2026-07-15

### Added

- Bounded deterministic envelope construction.
- Caller-owned pgx transactional writer and atomic batch insertion.
- PostgreSQL schema, claims, leases, retries, dead letters, replay audit, and
  delivered-record pruning.
- Bounded cancellation-aware relay with scoped ordering and error
  classification.
- Payload-safe publisher panic containment through normal retry policy.
- Automatic in-flight lease renewal with cancellation on ownership uncertainty.
- Separately versioned `go-queue` publisher adapter.
- Payload-safe lifecycle events, structured logging, readiness checks, and
  PostgreSQL backlog diagnostics.
- Archive-before-delete retention with idempotent archive guidance.
- Bounded payload-free administrative inspection and replay/retention events.
- Bounded dead-letter pruning and archive-before-delete retention.
- Separately versioned `go-telemetry` metrics and trace-linkage adapter.
- Low-cardinality backlog depth and oldest-pending-age gauges.
- PostgreSQL 14-18 CI matrix, safety checks, fuzz targets, allocation
  benchmarks, and meaningful 100% production coverage gates.
- Goroutine-leak detection, real migration rollback, and hot-set/retention
  query-plan assertions.
- Real PostgreSQL duplicate-window fault injection after publisher acceptance.
- Real PostgreSQL graceful-cancellation lease-release evidence.
- Compiled duplicate-consumer and go-queue relay examples.
- Exact `go-idempotency` consumer integration and atomic completion guidance.
- Real PostgreSQL canceled-context atomicity matrix for every store transition.
- Workspace-disabled publisher adapter integration matrix in CI.
- Writer-side envelope and batch validation that prevents direct construction
  from bypassing resource or new-record bounds.
- Infallible canonical timestamp encoding with insert-time JSON range checks.
- Observer and structured-logger panic containment at diagnostic boundaries.
- Conduct, support, contribution, and custom-schema migration policies.
