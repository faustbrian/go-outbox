# Compatibility Policy

Before v1, exported APIs and schema may change and every change belongs in
`CHANGELOG.md`. After v1, SemVer applies independently to core, `goqueue`, and
`gotelemetry`. Compatibility surfaces include canonical encoding, migrations,
delivery semantics, errors, metrics, observer events, and publisher behavior.

| Surface | Tested |
|---|---|
| Go | module minimum and stable; Linux, macOS, Windows unit tests |
| PostgreSQL | 14, 15, 16, 17, 18 |
| pgx | v5 |
| go-queue | adapter-pinned contract |
| go-telemetry | runtime standard providers and propagator |

Claims require a writable primary; cloud proxies and pooler modes need their
own validation. Before publishing adapters, replace repository-local core
`replace` directives with a released compatible core version.
