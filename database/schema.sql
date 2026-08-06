-- ASCIP database schema
-- Run automatically on first container start via docker-compose (see docker-compose.yml).
-- Mirrors app/models/*.py for tables the backend currently manages (suppliers);
-- the remaining tables are defined ahead of the backend code that will use them,
-- per the roadmap in docs/ASCIP_Pro_Build_Spec.md.

CREATE EXTENSION IF NOT EXISTS vector;

-- ============ Master data ============

CREATE TABLE IF NOT EXISTS suppliers (
    id              SERIAL PRIMARY KEY,
    name            TEXT NOT NULL,
    location        TEXT,
    category        TEXT,
    lead_time_days  INTEGER,
    quality_score   NUMERIC(5,2),          -- 0-100, maintained by risk engine
    status          TEXT NOT NULL DEFAULT 'active'
                    CHECK (status IN ('preferred', 'active', 'inactive', 'high_risk')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS parts (
    id              SERIAL PRIMARY KEY,
    part_number     TEXT UNIQUE NOT NULL,
    name            TEXT NOT NULL,
    category        TEXT,
    unit_of_measure TEXT DEFAULT 'each',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS plants (
    id      SERIAL PRIMARY KEY,
    name    TEXT NOT NULL,
    location TEXT
);

CREATE TABLE IF NOT EXISTS warehouses (
    id       SERIAL PRIMARY KEY,
    plant_id INTEGER REFERENCES plants(id),
    name     TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
    id            SERIAL PRIMARY KEY,
    email         TEXT UNIQUE NOT NULL,
    hashed_password TEXT NOT NULL,
    role          TEXT NOT NULL DEFAULT 'procurement'
                  CHECK (role IN ('admin', 'procurement', 'read_only')),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============ Transaction data ============

CREATE TABLE IF NOT EXISTS inventory (
    id              SERIAL PRIMARY KEY,
    part_id         INTEGER NOT NULL REFERENCES parts(id),
    warehouse_id    INTEGER NOT NULL REFERENCES warehouses(id),
    quantity_on_hand INTEGER NOT NULL DEFAULT 0,
    reorder_point   INTEGER,
    safety_stock    INTEGER,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (part_id, warehouse_id)
);

CREATE TABLE IF NOT EXISTS purchase_requests (
    id          SERIAL PRIMARY KEY,
    part_id     INTEGER NOT NULL REFERENCES parts(id),
    quantity    INTEGER NOT NULL,
    requested_by INTEGER REFERENCES users(id),
    status      TEXT NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'approved', 'rejected', 'converted_to_po')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rfqs (
    id            SERIAL PRIMARY KEY,
    part_id       INTEGER REFERENCES parts(id),
    source_file   TEXT,                     -- path/URL of uploaded PDF
    status        TEXT NOT NULL DEFAULT 'uploaded'
                  CHECK (status IN ('uploaded', 'extracted', 'needs_review', 'reviewed')),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS quotations (
    id              SERIAL PRIMARY KEY,
    rfq_id          INTEGER NOT NULL REFERENCES rfqs(id),
    supplier_id     INTEGER REFERENCES suppliers(id),
    part_number     TEXT,
    quantity        INTEGER,
    unit_price      NUMERIC(12,2),
    lead_time_days  INTEGER,
    payment_terms   TEXT,
    extraction_confidence NUMERIC(4,3),     -- 0-1, per-record confidence from the extraction pipeline
    needs_review    BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS purchase_orders (
    id                SERIAL PRIMARY KEY,
    purchase_request_id INTEGER REFERENCES purchase_requests(id),
    supplier_id       INTEGER REFERENCES suppliers(id),
    quotation_id      INTEGER REFERENCES quotations(id),
    status            TEXT NOT NULL DEFAULT 'open'
                      CHECK (status IN ('open', 'fulfilled', 'cancelled')),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS shipments (
    id                SERIAL PRIMARY KEY,
    purchase_order_id INTEGER REFERENCES purchase_orders(id),
    expected_date     DATE,
    actual_date       DATE,
    status            TEXT DEFAULT 'in_transit'
);

-- ============ Analytical data ============

CREATE TABLE IF NOT EXISTS supplier_performance (
    id                    SERIAL PRIMARY KEY,
    supplier_id           INTEGER NOT NULL REFERENCES suppliers(id),
    period_month          DATE NOT NULL,          -- first-of-month bucket
    on_time_delivery_rate NUMERIC(5,4),            -- 0-1
    quality_reject_rate   NUMERIC(5,4),            -- 0-1
    price_volatility      NUMERIC(6,4),            -- coefficient of variation
    single_source_flag    BOOLEAN DEFAULT false,
    UNIQUE (supplier_id, period_month)
);

CREATE TABLE IF NOT EXISTS risk_scores (
    id            SERIAL PRIMARY KEY,
    supplier_id   INTEGER NOT NULL REFERENCES suppliers(id),
    score         NUMERIC(5,2) NOT NULL,     -- final weighted scorecard value
    factors       JSONB,                     -- component breakdown, for explainability in the UI
    computed_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS forecasts (
    id            SERIAL PRIMARY KEY,
    part_id       INTEGER NOT NULL REFERENCES parts(id),
    forecast_date DATE NOT NULL,
    predicted_demand NUMERIC(12,2),
    model_version TEXT,
    mape          NUMERIC(6,4),               -- backtested accuracy for this model version
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER REFERENCES users(id),
    action      TEXT NOT NULL,
    entity_type TEXT,
    entity_id   INTEGER,
    metadata    JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============ GenAI copilot support ============

-- Embeddings for RAG over internal spec/policy docs (pgvector, same Postgres
-- instance — avoids standing up a separate vector DB for a portfolio project).
CREATE TABLE IF NOT EXISTS doc_embeddings (
    id          SERIAL PRIMARY KEY,
    source      TEXT,
    chunk_text  TEXT NOT NULL,
    embedding   vector(1536),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS copilot_logs (
    id            SERIAL PRIMARY KEY,
    user_id       INTEGER REFERENCES users(id),
    question      TEXT NOT NULL,
    tools_called  JSONB,     -- which internal APIs the agent invoked, for traceability
    answer        TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_inventory_part ON inventory(part_id);
CREATE INDEX IF NOT EXISTS idx_quotations_rfq ON quotations(rfq_id);
CREATE INDEX IF NOT EXISTS idx_risk_scores_supplier ON risk_scores(supplier_id);
CREATE INDEX IF NOT EXISTS idx_forecasts_part_date ON forecasts(part_id, forecast_date);
