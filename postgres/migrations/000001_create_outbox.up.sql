CREATE TABLE outbox_messages (
    id text PRIMARY KEY,
    topic text NOT NULL,
    payload bytea NOT NULL,
    payload_version smallint NOT NULL,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    ordering_key text NOT NULL DEFAULT '',
    idempotency_key text NOT NULL DEFAULT '',
    attempts integer NOT NULL DEFAULT 0,
    available_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    state text NOT NULL DEFAULT 'pending',
    lease_owner text,
    lease_token text,
    leased_until timestamptz,
    delivered_at timestamptz,
    dead_lettered_at timestamptz,
    last_error text,
    CONSTRAINT outbox_messages_id_length CHECK (octet_length(id) BETWEEN 1 AND 255),
    CONSTRAINT outbox_messages_topic_length CHECK (octet_length(topic) BETWEEN 1 AND 255),
    CONSTRAINT outbox_messages_payload_version CHECK (payload_version > 0),
    CONSTRAINT outbox_messages_attempts CHECK (attempts >= 0),
    CONSTRAINT outbox_messages_ordering_key_length CHECK (octet_length(ordering_key) <= 255),
    CONSTRAINT outbox_messages_idempotency_key_length CHECK (octet_length(idempotency_key) <= 255),
    CONSTRAINT outbox_messages_state CHECK (state IN ('pending', 'leased', 'delivered', 'dead')),
    CONSTRAINT outbox_messages_state_fields CHECK (
        (state = 'pending'
            AND lease_owner IS NULL
            AND lease_token IS NULL
            AND leased_until IS NULL
            AND delivered_at IS NULL
            AND dead_lettered_at IS NULL)
        OR (state = 'leased'
            AND lease_owner IS NOT NULL
            AND lease_token IS NOT NULL
            AND leased_until IS NOT NULL
            AND delivered_at IS NULL
            AND dead_lettered_at IS NULL)
        OR (state = 'delivered'
            AND lease_owner IS NULL
            AND lease_token IS NULL
            AND leased_until IS NULL
            AND delivered_at IS NOT NULL
            AND dead_lettered_at IS NULL)
        OR (state = 'dead'
            AND lease_owner IS NULL
            AND lease_token IS NULL
            AND leased_until IS NULL
            AND delivered_at IS NULL
            AND dead_lettered_at IS NOT NULL)
    )
);

CREATE INDEX outbox_messages_claim_idx
    ON outbox_messages (available_at, created_at, id)
    WHERE state IN ('pending', 'leased');

CREATE INDEX outbox_messages_lease_expiry_idx
    ON outbox_messages (leased_until, id)
    WHERE state = 'leased';

CREATE INDEX outbox_messages_ordering_idx
    ON outbox_messages (ordering_key, created_at, id)
    WHERE state IN ('pending', 'leased') AND ordering_key <> '';

CREATE INDEX outbox_messages_delivered_retention_idx
    ON outbox_messages (delivered_at, id)
    WHERE state = 'delivered';

CREATE INDEX outbox_messages_dead_retention_idx
    ON outbox_messages (dead_lettered_at, id)
    WHERE state = 'dead';

CREATE UNIQUE INDEX outbox_messages_idempotency_idx
    ON outbox_messages (idempotency_key)
    WHERE idempotency_key <> '';

COMMENT ON TABLE outbox_messages IS
    'At-least-once transactional outbox; publisher acceptance before delivery marking can produce duplicates';
COMMENT ON COLUMN outbox_messages.lease_token IS
    'Opaque claim generation token required for lease-safe updates';

CREATE TABLE outbox_replay_audit (
    replay_id text NOT NULL,
    message_id text NOT NULL,
    previous_state text NOT NULL,
    requested_by text NOT NULL,
    reason text NOT NULL,
    requested_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    available_at timestamptz NOT NULL,
    PRIMARY KEY (replay_id, message_id),
    CONSTRAINT outbox_replay_audit_previous_state
        CHECK (previous_state IN ('delivered', 'dead')),
    CONSTRAINT outbox_replay_audit_requested_by
        CHECK (octet_length(requested_by) BETWEEN 1 AND 255),
    CONSTRAINT outbox_replay_audit_reason
        CHECK (octet_length(reason) BETWEEN 1 AND 4096)
);

CREATE INDEX outbox_replay_audit_requested_at_idx
    ON outbox_replay_audit (requested_at, replay_id);

COMMENT ON TABLE outbox_replay_audit IS
    'Immutable operator audit for duplicate-producing replay actions';
