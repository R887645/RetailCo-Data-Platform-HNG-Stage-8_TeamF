# RetailCo Data Platform
**Team F: HNG Stage 8 Data Engineering Pipeline**

Nigerian retail chain data engineering platform built with Python, dlt, dbt, Airflow, and PostgreSQL.

---

## What This Builds

```
ERP REST API → Lake (PostgreSQL) → Warehouse (PostgreSQL)
                                           ↓
                                 dbt dimensional models
                                 (Kimball: 6 dims, 4 facts)
```

The platform extracts data from RetailCo's legacy ERP system across 4 Nigerian stores (Lagos, Abuja, Port Harcourt, Kano), loads it into a warehouse, and transforms it into analytics-ready models that answer five weekly management questions.

---

## Prerequisites

- Docker Desktop installed and running
- At least 4GB RAM available for Docker
- Python 3.11+
- Git

---

## Setup — Step by Step

### 1. Clone the repository
```bash
git clone https://github.com/R887645/RetailCo-Data-Platform-HNG-Stage-8_TeamF.git
cd RetailCo-Data-Platform-HNG-Stage-8_TeamF
```

### 2. Configure environment variables
```bash
cp .env.example .env
```

Open `.env` and fill in your API key:
```
ERP_BASE_URL=https://hngstage8da-55c7f5f769c8.herokuapp.com
ERP_API_KEY=your_api_key_here
LAKE_CONN=host=postgres-lake port=5432 dbname=lake user=lake password=lake
WAREHOUSE_CONN=postgresql://warehouse:warehouse@postgres-warehouse:5432/warehouse
```

### 3. Start all containers
```bash
docker-compose up -d
```

This starts:
- `postgres-lake` on port **5433** — raw data lake
- `postgres-warehouse` on port **5434** — analytics warehouse
- `postgres-meta` — Airflow metadata database
- `airflow-webserver` on port **8080** — DAG UI
- `airflow-scheduler` — runs DAGs in background

Wait about 60 seconds for Airflow to initialise.

### 4. Open Airflow UI
Go to `http://localhost:8080`

```
Username: admin
Password: admin
```

### 5. Enable and trigger the pipeline
- Find the DAG called `retailco_pipeline`
- Toggle it **ON** (the switch on the left)
- Click the **▶ Run** button to trigger manually, or wait for the daily schedule at 02:00 WAT

---

## Running the Pipeline

### Trigger manually from CLI
```bash
docker-compose exec airflow-scheduler \
    airflow dags trigger retailco_pipeline
```

### Backfill a date range
```bash
docker-compose exec airflow-scheduler \
    airflow dags backfill retailco_pipeline \
    --start-date 2024-01-01 \
    --end-date 2024-12-31
```

### Check DAG status
```bash
docker-compose exec airflow-scheduler \
    airflow dags list-runs -d retailco_pipeline
```

---

## Pipeline Task Order

```
extract_stores              ──┐
extract_employees             │
extract_payment_methods       │
extract_customers             ├──→ load_lake_to_warehouse
extract_products              │          ↓
extract_orders                │     dbt_snapshot
extract_order_items           │          ↓
extract_payments              │     dbt_staging
extract_inventory_movements ──┘          ↓
                                     dbt_marts
                                          ↓
                                      dbt_test
```

All 9 extract tasks run in **parallel**. Each subsequent stage only starts when all tasks before it complete successfully. Any failure stops all downstream tasks. Every task retries **2 times** with exponential backoff before failing.

---

## Querying the Warehouse

Connect using any SQL client (pgAdmin, DBeaver, TablePlus):

```
Host:     localhost
Port:     5434
User:     warehouse
Password: warehouse
Database: warehouse
Schema:   marts
```

Or connect directly via terminal:
```bash
docker-compose exec postgres-warehouse \
    psql -U warehouse -d warehouse
```

### Question 1 — Revenue Performance
```sql
SELECT
    s.store_name,
    s.city,
    p.category,
    p.product_name,
    d.year,
    d.month_name,
    d.year_month,
    COUNT(DISTINCT f.order_id)                              AS total_orders,
    SUM(f.quantity)                                         AS total_units_sold,
    ROUND(SUM(f.gross_amount), 2)                           AS gross_revenue,
    ROUND(SUM(f.discount_amount), 2)                        AS total_discounts,
    ROUND(SUM(f.net_amount), 2)                             AS net_revenue,
    ROUND(SUM(f.margin_amount), 2)                          AS gross_profit,
    ROUND(SUM(f.net_amount) /
          NULLIF(COUNT(DISTINCT f.order_id), 0), 2)         AS avg_order_value,
    ROUND(SUM(f.margin_amount) /
          NULLIF(SUM(f.net_amount), 0) * 100, 2)            AS margin_pct
FROM marts.fct_sales        f
JOIN marts.dim_store        s  ON f.store_sk       = s.store_sk
JOIN marts.dim_product      p  ON f.product_sk     = p.product_sk
JOIN marts.dim_date         d  ON f.order_date_key = d.date_key
WHERE p.is_current = TRUE
GROUP BY
    s.store_name, s.city, p.category, p.product_name,
    d.year, d.month_name, d.year_month
ORDER BY d.year_month ASC, net_revenue DESC;
```

### Question 2 — Customer Behaviour
```sql
SELECT
    c.segment,
    c.tier,
    COUNT(DISTINCT c.customer_id)                           AS total_customers,
    COUNT(DISTINCT f.order_id)                              AS total_orders,
    ROUND(COUNT(DISTINCT f.order_id)::NUMERIC /
          NULLIF(COUNT(DISTINCT c.customer_id), 0), 2)      AS avg_orders_per_customer,
    ROUND(SUM(f.net_amount) /
          NULLIF(COUNT(DISTINCT f.order_id), 0), 2)         AS avg_order_value,
    ROUND(SUM(f.net_amount), 2)                             AS total_revenue,
    ROUND(SUM(f.net_amount) /
          NULLIF(COUNT(DISTINCT c.customer_id), 0), 2)      AS avg_revenue_per_customer,
    MAX(d.full_date)                                        AS most_recent_purchase
FROM marts.fct_sales        f
JOIN marts.dim_customer     c  ON f.customer_sk    = c.customer_sk
JOIN marts.dim_date         d  ON f.order_date_key = d.date_key
WHERE c.is_current = TRUE
GROUP BY c.segment, c.tier
ORDER BY total_revenue DESC;
```

### Question 3 — Product & Discount Analysis
```sql
SELECT
    p.product_name,
    p.category,
    p.sub_category,
    p.brand,
    COUNT(DISTINCT f.order_id)                              AS total_orders,
    SUM(f.quantity)                                         AS total_units_sold,
    ROUND(SUM(f.gross_amount), 2)                           AS gross_revenue,
    ROUND(SUM(f.net_amount), 2)                             AS net_revenue,
    ROUND(AVG(f.discount_pct), 2)                           AS avg_discount_pct,
    ROUND(SUM(f.discount_amount), 2)                        AS total_discount_given,
    COUNT(CASE WHEN f.discount_pct > 0 THEN 1 END)          AS discounted_orders,
    ROUND(SUM(f.margin_amount), 2)                          AS total_margin,
    ROUND(SUM(f.margin_amount) /
          NULLIF(SUM(f.net_amount), 0) * 100, 2)            AS margin_pct
FROM marts.fct_sales        f
JOIN marts.dim_product      p  ON f.product_sk = p.product_sk
WHERE p.is_current = TRUE
GROUP BY
    p.product_name, p.category, p.sub_category, p.brand
ORDER BY net_revenue DESC;
```

### Question 4 — Payment Channel Insights
```sql
-- Payment method breakdown
SELECT
    pm.payment_method,
    pm.payment_category,
    COUNT(f.payment_key)                                    AS total_transactions,
    ROUND(COUNT(f.payment_key)::NUMERIC /
          SUM(COUNT(f.payment_key)) OVER () * 100, 2)       AS pct_of_transactions,
    ROUND(SUM(f.amount_paid), 2)                            AS total_amount_collected,
    ROUND(AVG(f.amount_paid), 2)                            AS avg_payment_amount,
    COUNT(CASE WHEN f.is_refund = TRUE THEN 1 END)          AS refund_count,
    ROUND(SUM(CASE WHEN f.is_refund = TRUE
                   THEN ABS(f.amount_paid) ELSE 0 END), 2)  AS total_refund_amount
FROM marts.fct_payments         f
JOIN marts.dim_payment_method   pm ON f.payment_method_sk = pm.payment_method_sk
GROUP BY pm.payment_method, pm.payment_category
ORDER BY total_transactions DESC;

-- Anomalous payments
SELECT
    flag_reason                                             AS anomaly_type,
    COUNT(payment_id)                                       AS anomaly_count,
    ROUND(SUM(ABS(amount_paid)), 2)                         AS total_amount_at_risk,
    MIN(payment_date)                                       AS earliest_occurrence,
    MAX(payment_date)                                       AS latest_occurrence
FROM marts.flagged_payments
GROUP BY flag_reason
ORDER BY anomaly_count DESC;
```

### Question 5 — Operational Data Quality
```sql
-- Flagged payments detail
SELECT
    fp.payment_id,
    fp.order_id,
    fp.amount_paid,
    fp.flag_reason,
    fp.flagged_at,
    o.current_status                                        AS order_status
FROM marts.flagged_payments         fp
LEFT JOIN marts.fct_order_lifecycle o  ON fp.order_id = o.order_id
ORDER BY fp.flagged_at DESC;

-- Inventory stock anomalies
SELECT
    p.product_name,
    p.category,
    s.store_name,
    s.city,
    i.snapshot_date,
    i.closing_stock,
    i.units_sold,
    i.units_restocked
FROM marts.fct_inventory_daily  i
JOIN marts.dim_product          p  ON i.product_sk = p.product_sk
JOIN marts.dim_store            s  ON i.store_sk   = s.store_sk
WHERE i.closing_stock < 0
ORDER BY i.closing_stock ASC;

-- Order lifecycle health
SELECT
    o.current_status,
    COUNT(o.order_id)                                       AS order_count,
    ROUND(AVG(o.total_cycle_days), 1)                       AS avg_cycle_days,
    MAX(o.total_cycle_days)                                 AS max_cycle_days,
    COUNT(CASE WHEN o.is_cancelled = TRUE THEN 1 END)       AS cancelled_count,
    COUNT(CASE WHEN o.total_cycle_days > 30 THEN 1 END)     AS orders_over_30_days
FROM marts.fct_order_lifecycle o
GROUP BY o.current_status
ORDER BY order_count DESC;
```

---

## Project Structure

```
RetailCo-Data-Platform-HNG-Stage-8_TeamF/
├── docker-compose.yml              # All containers
├── .env.example                    # Environment variable template
├── docker/
│   ├── lake_init.sql               # Lake schema + raw tables setup
│   └── warehouse_init.sql          # Warehouse schema setup
├── extractor/
│   ├── erp_extractor.py            # CP2: ERP API → Lake
│   └── cp2_extract_dag.py          # CP2: Airflow DAG for extraction
├── dlt_pipeline/
│   └── lake_to_warehouse.py        # CP3: Lake → Warehouse (dlt)
├── dbt_project/
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── models/
│   │   ├── staging/                # 9 views: type-cast + rename
│   │   └── marts/
│   │       ├── dimensions/         # 6 dimension tables
│   │       └── facts/              # 4 fact tables + flagged_payments
│   ├── snapshots/                  # SCD2 for customers + products
│   └── tests/                      # Custom data quality tests
├── airflow/
│   └── dags/
│       └── retailco_pipeline.py    # CP5: Full end-to-end DAG
└── design/
    ├── bus_matrix.png              # Kimball bus matrix
    ├── warehouse_erd.png           # All tables, PKs, FKs, SCD2 columns
    └── architecture_diagram.png   # Full system architecture
```

---

## Kimball Bus Matrix

| Fact Table | dim_date | dim_customer | dim_product | dim_store | dim_employee | dim_payment_method |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| fct_sales (order lines) | ✓ | ✓ SCD2 | ✓ SCD2 | ✓ | ✓ | — |
| fct_payments (payment events) | ✓ | ✓ SCD2 | — | ✓ | — | ✓ |
| fct_inventory_daily (product × store × day) | ✓ | — | ✓ SCD2 | ✓ | — | — |
| fct_order_lifecycle (per order) | ✓ | ✓ SCD2 | — | ✓ | ✓ | — |

`flagged_payments` is a data quality artifact — it is **not** a fact table and does not appear in the bus matrix.

---

## Key Design Decisions

**SCD Type 2** — `dim_customer` and `dim_product` track historical changes using `valid_from`, `valid_to`, and `is_current` columns. Historical fact rows always join to the correct version of the dimension at the time of the transaction.

**Surrogate Keys** — All dimensions use MD5-based surrogate keys. Facts reference surrogate keys only, never natural keys from the source system.

**Incremental Loading** — The extractor stores a watermark (last `updated_at`) per entity and passes `?updated_after=<watermark>` on subsequent runs. The dlt pipeline uses `dlt.sources.incremental` so only changed rows move each run.

**Idempotency** — Running the pipeline twice on the same date produces identical results. The extractor uses `INSERT ... ON CONFLICT (id) DO UPDATE`. dlt uses `write_disposition=merge` on primary key.

**Flagged Payments** — Zero-amount payments and unexplained negative amounts are isolated in `flagged_payments` and excluded from `fct_payments`, keeping revenue analysis clean.

---

## Troubleshooting

**Airflow shows heartbeat errors on startup:**
Wait 60–90 seconds. The scheduler takes time to initialise on first run.

**dbt models fail with "relation does not exist":**
Make sure the extract and load tasks completed first. Check `warehouse.raw` schema has data before running dbt.

**429 errors in extractor logs:**
Expected. The extractor handles these automatically with exponential backoff. If a task fails after 5 retries, re-trigger the DAG.

**Containers not starting:**
```bash
docker-compose down -v
docker-compose up -d
```

**Cannot connect to warehouse on port 5434:**
```bash
docker ps
# Confirm postgres-warehouse shows "Up" and "healthy"
```

---

## Team

**Team F — HNG Stage 8 Data Engineering**
Team ID: `fce38a75-4c91-4440-b01a-d407db52d54e`
GitHub: https://github.com/R887645/RetailCo-Data-Platform-HNG-Stage-8_TeamF
