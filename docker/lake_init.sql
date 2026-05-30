-- ============================================================
-- Lake Database — raw schema
-- All columns match the EXACT API response fields from the ERD
-- ============================================================

CREATE SCHEMA IF NOT EXISTS raw;

-- Watermark table: tracks last successful extract per entity
-- This is what makes incremental loading work
CREATE TABLE IF NOT EXISTS raw.watermarks (
    entity          TEXT PRIMARY KEY,
    last_updated_at TIMESTAMPTZ,
    last_run_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ── stores ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS raw.stores (
    id              UUID PRIMARY KEY,
    team_id         UUID,
    name            VARCHAR,
    city            VARCHAR,
    state           VARCHAR,
    address         VARCHAR,
    phone           VARCHAR,
    manager_name    VARCHAR,
    opened_date     DATE,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ,
    _extracted_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── employees ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS raw.employees (
    id              UUID PRIMARY KEY,
    team_id         UUID,
    store_id        UUID,
    first_name      VARCHAR,
    last_name       VARCHAR,
    email           VARCHAR,
    role            VARCHAR,
    hired_date      DATE,
    is_deleted      BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ,
    _extracted_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── payment_methods ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS raw.payment_methods (
    id              UUID PRIMARY KEY,
    team_id         UUID,
    name            VARCHAR,
    provider        VARCHAR,
    is_digital      BOOLEAN,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ,
    _extracted_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── customers ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS raw.customers (
    id              UUID PRIMARY KEY,
    team_id         UUID,
    first_name      VARCHAR,
    last_name       VARCHAR,
    email           VARCHAR,
    phone           VARCHAR,
    segment         VARCHAR,
    tier            VARCHAR,
    address         VARCHAR,
    city            VARCHAR,
    state           VARCHAR,
    effective_from  TIMESTAMPTZ,
    registered_at   TIMESTAMPTZ,
    is_deleted      BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ,
    _extracted_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── products ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS raw.products (
    id              UUID PRIMARY KEY,
    team_id         UUID,
    sku             VARCHAR,
    name            VARCHAR,
    category        VARCHAR,
    sub_category    VARCHAR,
    brand           VARCHAR,
    supplier        VARCHAR,
    cost_price      DECIMAL(12,2),
    selling_price   DECIMAL(12,2),
    effective_from  TIMESTAMPTZ,
    is_deleted      BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ,
    _extracted_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── orders ────────────────────────────────────────────────────
-- NOTE: status timestamps (paid_at, shipped_at etc.) live directly
-- on orders — confirmed from real API ERD
CREATE TABLE IF NOT EXISTS raw.orders (
    id              UUID PRIMARY KEY,
    team_id         UUID,
    customer_id     UUID,
    store_id        UUID,
    employee_id     UUID,
    status          VARCHAR,
    discount_code   VARCHAR,
    discount_amount DECIMAL(12,2),
    total_amount    DECIMAL(12,2),
    ordered_at      TIMESTAMPTZ,
    paid_at         TIMESTAMPTZ,
    shipped_at      TIMESTAMPTZ,
    delivered_at    TIMESTAMPTZ,
    cancelled_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ,
    _extracted_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── order_items ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS raw.order_items (
    id              UUID PRIMARY KEY,
    team_id         UUID,
    order_id        UUID,
    product_id      UUID,
    quantity        INTEGER,
    unit_price      DECIMAL(12,2),
    discount_pct    DECIMAL(5,2),
    line_total      DECIMAL(12,2),
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ,
    _extracted_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── payments ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS raw.payments (
    id                  UUID PRIMARY KEY,
    team_id             UUID,
    order_id            UUID,
    customer_id         UUID,
    payment_method_id   UUID,
    amount_paid         DECIMAL(12,2),
    currency            VARCHAR,
    status              VARCHAR,
    payment_type        VARCHAR,
    reference           VARCHAR,
    paid_at             TIMESTAMPTZ,
    created_at          TIMESTAMPTZ,
    updated_at          TIMESTAMPTZ,
    _extracted_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ── inventory_movements ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS raw.inventory_movements (
    id              UUID PRIMARY KEY,
    team_id         UUID,
    product_id      UUID,
    store_id        UUID,
    movement_type   VARCHAR,
    quantity        INTEGER,
    reference_id    VARCHAR,
    reference_type  VARCHAR,
    notes           TEXT,
    moved_at        TIMESTAMPTZ,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ,
    _extracted_at   TIMESTAMPTZ DEFAULT NOW()
);
