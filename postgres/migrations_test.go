package postgres_test

import (
	"io/fs"
	"strings"
	"testing"

	"github.com/faustbrian/go-outbox/postgres"
)

func TestMigrationsExposeReversibleSchema(t *testing.T) {
	t.Parallel()

	migrations := postgres.Migrations()
	up, err := fs.ReadFile(migrations, "000001_create_outbox.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := fs.ReadFile(migrations, "000001_create_outbox.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	for _, fragment := range []string{
		"CREATE TABLE outbox_messages",
		"CREATE TABLE outbox_replay_audit",
		"CHECK (state IN ('pending', 'leased', 'delivered', 'dead'))",
		"CREATE INDEX outbox_messages_claim_idx",
		"CREATE UNIQUE INDEX outbox_messages_idempotency_idx",
	} {
		if !strings.Contains(string(up), fragment) {
			t.Fatalf("up migration does not contain %q", fragment)
		}
	}
	for _, fragment := range []string{"DROP TABLE outbox_replay_audit", "DROP TABLE outbox_messages"} {
		if !strings.Contains(string(down), fragment) {
			t.Fatalf("down migration does not contain %q: %s", fragment, down)
		}
	}
}
