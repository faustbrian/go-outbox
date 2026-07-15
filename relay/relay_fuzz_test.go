package relay_test

import (
	"context"
	"testing"
	"time"

	"github.com/faustbrian/go-outbox/postgres"
	"github.com/faustbrian/go-outbox/relay"
)

func FuzzRelayOptions(f *testing.F) {
	f.Add(int16(1), int16(1), int16(3), int64(time.Second), byte(0))
	f.Add(int16(-1), int16(0), int16(-1), int64(-1), byte(255))

	f.Fuzz(func(t *testing.T, batch, workers, attempts int16, duration int64, serialization byte) {
		worker, err := relay.New(&recordingStore{}, &recordingPublisher{}, relay.Config{
			Owner: "fuzz", BatchSize: int(batch), Workers: int(workers),
			MaxAttempts: int(attempts), LeaseDuration: time.Duration(duration),
			Serialization: postgres.SerializationMode(serialization),
		})
		if err != nil {
			return
		}
		if _, err := worker.RunOnce(context.Background()); err != nil {
			t.Fatalf("run once: %v", err)
		}
	})
}

func BenchmarkRelayRunOnce1000(b *testing.B) {
	b.ReportAllocs()
	claims := make([]postgres.Claim, 1000)
	for index := range claims {
		claims[index] = claim("benchmark", 1)
	}

	for b.Loop() {
		store := &recordingStore{claims: claims}
		worker, err := relay.New(store, &recordingPublisher{}, relay.Config{
			Owner: "benchmark", BatchSize: len(claims), Workers: 8,
		})
		if err != nil {
			b.Fatalf("create relay: %v", err)
		}
		if _, err := worker.RunOnce(context.Background()); err != nil {
			b.Fatalf("run once: %v", err)
		}
	}
}
