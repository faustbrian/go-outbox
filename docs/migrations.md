# Schema Migrations And Upgrades

`postgres.Migrations()` exposes SQL through `fs.FS`; applications choose the
runner and timing. The library never migrates during initialization.

For every release, test clean install and upgrade from every released schema,
run old code during additive phases where compatibility is claimed, deploy the
required schema before code, and verify constraints, indexes, and integration
tests. Never edit a released migration; add a reversible version. Destructive
changes require expand/migrate/contract planning.

The initial schema has no older released upgrade source. Its down migration is
for development and deletes data. Production rollback should normally roll
forward or restore a consistent backup, not run destructive down SQL because
an application deployment failed.

The integration matrix executes the initial up migration, exercises the full
state machine, applies the down migration, and verifies both managed tables are
removed on every supported PostgreSQL major. Future schema versions must add
an upgrade fixture for every released predecessor.
