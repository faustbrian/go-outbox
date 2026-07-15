// Package goqueue adapts go-outbox envelopes to go-queue producers.
package goqueue

import (
	"context"
	"errors"
	"fmt"

	"github.com/faustbrian/go-outbox"
	"github.com/faustbrian/go-queue/core"
	"github.com/faustbrian/go-queue/job"
)

var ErrQueueRequired = errors.New("outbox/goqueue: queue is required")

// Queue is the narrow go-queue producer surface used by Publisher.
type Queue interface {
	Queue(core.QueuedMessage, ...job.AllowOption) error
}

// Publisher enqueues canonical outbox envelopes through go-queue.
type Publisher struct {
	queue Queue
}

// New creates a go-queue publisher adapter.
func New(queue Queue) (*Publisher, error) {
	if queue == nil {
		return nil, ErrQueueRequired
	}

	return &Publisher{queue: queue}, nil
}

// Publish checks cancellation before entering go-queue, whose producer API is
// synchronous and does not accept a context. A nil result means go-queue
// accepted the message; it does not change the relay's at-least-once contract.
func (publisher *Publisher) Publish(ctx context.Context, envelope outbox.Envelope) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	if err := publisher.queue.Queue(message(envelope.CanonicalJSON())); err != nil {
		return fmt.Errorf("outbox/goqueue: queue envelope %q: %w", envelope.ID, err)
	}

	return nil
}

type message []byte

func (value message) Bytes() []byte {
	return append([]byte(nil), value...)
}
