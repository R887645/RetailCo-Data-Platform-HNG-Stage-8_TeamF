# RetailCo Data Platform

**Team F | HNG Stage 8 | Data Engineering Pipeline**

---

## Overview

RetailCo is a Nigerian retail chain operating stores in Lagos, Abuja, Port Harcourt, and Kano. This project builds the company's complete data platform from scratch, extracting data from a legacy ERP system, loading it into a data warehouse, transforming it into analytics-ready Kimball dimensional models, and orchestrating the entire pipeline on a daily automated schedule.

The platform answers five management questions every week:
- Revenue performance across stores, products, and categories
- Customer behaviour, purchase frequency, and average order value
- Product and discount analysis with margin impact
- Payment channel insights and anomaly detection
- Operational data quality monitoring

---

## Architecture

```
ERP API (Heroku)
      ↓  Python extractor (pagination + backoff + watermark)
Lake PostgreSQL — schema: raw
      ↓  dlt incremental pipeline (merge on primary key)
Warehouse PostgreSQL — schema: raw
      ↓  dbt staging (type casting + renaming)
Warehouse PostgreSQL — schema: staging
      ↓  dbt snapshots (SCD2 for customers + products)
      ↓  dbt marts (dimensions + facts)
Warehouse PostgreSQL — schema: marts
```

All components run inside Docker containers and are orchestrated by Apache Airflow on a daily schedule.

---

## Tools and Versions

| Layer | Tool | Version |
|---|---|---|
| Extraction | Python 3.11+ | Hand-written extractor |
| Lake Storage | PostgreSQL | 17 (port 5433) |
| Loading | dlt | 1.27.2 |
| Warehouse Storage | PostgreSQL | 17 (port 5434) |
| Transformation | dbt-core + dbt-postgres | 1.7+ |
| Orchestration | Apache Airflow | 2.9+ |
| Containerisation | Docker + Docker Compose | Latest |

---

## Project Structure

```
RetailCo-Data-Platform-HNG-Stage-8_TeamF/
├── design/                         # CP1: Design artifacts
│   ├── bus_matrix.png              # Kimball bus matrix
│   ├── warehouse_erd.png           # Warehouse ERD
│   └── architecture_diagram.png   # Architecture diagram
├── extractor/                      # CP2: Python ERP extractor
│   ├── erp_extractor.py            # Main extraction logic
│   └── cp2_extract_dag.py          # Airflow DAG for extraction
├── dlt_pipeline/                   # CP3: dlt load pipeline
│   └── lake_to_warehouse.py        # Lake to warehouse pipeline
├── dbt_project/                    # CP4: Kimball dimensional models
│   ├── models/
│   │   ├── staging/                # 9 staging views (type casts + renaming)
│   │   └── marts/
│   │       ├── dimensions/         # 6 dimension tables
│   │       └── facts/              # 4 fact tables + flagged_payments
│   ├── snapshots/                  # SCD2 snapshots for customer + product
│   └── tests/                      # Custom data quality tests
├── airflow/
│   └── dags/
│       └── retailco_pipeline.py    # CP5: Full end-to-end orchestration DAG
├── docker/
│   ├── lake_init.sql               # Creates raw schema and tables in Lake
│   └── warehouse_init.sql          # Creates raw, staging, and marts schemas
├── docker-compose.yml              # Starts all services
├── .env.example                    # Environment variable template
└── README.md                       # This file
```

---

## Kimball Bus Matrix

| Fact Table | Grain | dim_date | dim_customer | dim_product | dim_store | dim_employee | dim_payment_method |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|
| fct_sales | One row per order line | ✓ | ✓ SCD2 | ✓ SCD2 | ✓ | ✓ | — |
| fct_payments | One row per payment | ✓ | ✓ SCD2 | — | ✓ | — | ✓ |
| fct_inventory_daily | Product × store × day | ✓ | — | ✓ SCD2 | ✓ | — | — |
| fct_order_lifecycle | One row per order | ✓ | ✓ SCD2 | — | ✓ | ✓ | — |

**Note:** `flagged_payments` is a data quality artifact: it is NOT a fact table and does not appear in the bus matrix.

---

## Setup Instructions

### Prerequisites
- Docker Desktop installed and running
- Python 3.11+
- Git

### Step 1: Clone the repository
```bash
git clone https://github.com/R887645/RetailCo-Data-Platform-HNG-Stage-8_TeamF.git
cd RetailCo-Data-Platform-HNG-Stage-8_TeamF
```

### Step 2: Configure environment variables
```bash
cp .env.example .env
```

Open `.env` and fill in your values:
```
ERP_BASE_URL=https://hngstage8da-55c7f5f769c8.herokuapp.com
ERP_API_KEY=your_api_key_here
LAKE_CONN=host=postgres-lake port=5432 dbname=lake user=lake password=lake
WAREHOUSE_CONN=postgresql://warehouse:warehouse@postgres-warehouse:5432/warehouse
```

### Step 3: Start all services
```bash
docker-compose up -d
```

Wait 60 seconds for all services to initialise, then verify:
```bash
docker ps
```

You should see all five containers running:
```
postgres-lake        Up    0.0.0.0:5433->5432/tcp
postgres-warehouse   Up    0.0.0.0:5434->5432/tcp
postgres-meta        Up
airflow-webserver    Up    0.0.0.0:8080->8080/tcp
airflow-scheduler    Up
```

### Step 4: Access the Airflow UI
Open your browser at:
```
http://localhost:8080
Username: admin
Password: admin
```

---

## How to Run the DAG

### Option 1: Airflow UI (recommended)
1. Open `http://localhost:8080`
2. Find the `retailco_pipeline` DAG
3. Click the toggle to **unpause** it
4. Click the **▶ Trigger DAG** button to run immediately

### Option 2: Command line
```bash
docker-compose exec airflow-scheduler \
  airflow dags trigger retailco_pipeline
```

### Option 3: Backfill historical data
```bash
docker-compose exec airflow-scheduler \
  airflow dags backfill retailco_pipeline \
  --start-date 2024-01-01 \
  --end-date 2024-12-31
```

### DAG Task Execution Order

```
extract_stores          ──┐
extract_employees         ├──→ load_lake_to_warehouse
extract_payment_methods   │          ↓
extract_customers         │     dbt_snapshot
extract_products          │          ↓
extract_orders            │     dbt_staging
extract_order_items       │          ↓
extract_payments          │     dbt_marts
extract_inventory_movements┘         ↓
                                 dbt_test
```

All 9 extract tasks run in **parallel**. The load task runs only after **all** extracts succeed. dbt tasks run in a strict sequence. Failure at any task stops all downstream tasks automatically.

### Task retry policy
Every task has:
- 2 retries minimum
- 5-minute initial retry delay
- Exponential backoff (5min → 10min → 20min)

---

## How to Query the Warehouse

Connect to the warehouse database using any SQL client:
```
Host:     localhost
Port:     5434
Database: warehouse
User:     warehouse
Password: warehouse
Schema:   marts
```

### Revenue by store (last 30 days)
```sql
SELECT
    s.store_name,
    s.city,
    SUM(f.net_amount)          AS total_revenue,
    COUNT(DISTINCT f.order_id) AS total_orders,
    AVG(f.net_amount)          AS avg_order_line_value
FROM marts.fct_sales f
JOIN marts.dim_store s ON f.store_sk = s.store_sk
JOIN marts.dim_date d  ON f.order_date_key = d.date_key
WHERE d.full_date >= CURRENT_DATE - 30
GROUP BY 1, 2
ORDER BY 3 DESC;
```

### Top 10 products by revenue
```sql
SELECT
    p.product_name,
    p.category,
    SUM(f.net_amount)   AS total_revenue,
    SUM(f.margin_amount) AS total_margin,
    AVG(f.discount_pct) AS avg_discount_pct
FROM marts.fct_sales f
JOIN marts.dim_product p ON f.product_sk = p.product_sk
WHERE p.is_current = TRUE
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 10;
```

### Customer behaviour by segment
```sql
SELECT
    c.segment,
    COUNT(DISTINCT f.order_id)                              AS total_orders,
    COUNT(DISTINCT f.order_id) / COUNT(DISTINCT c.customer_id)
                                                            AS avg_orders_per_customer,
    ROUND(SUM(f.net_amount) / COUNT(DISTINCT f.order_id), 2) AS avg_order_value,
    SUM(f.net_amount)                                       AS total_revenue
FROM marts.fct_sales f
JOIN marts.dim_customer c ON f.customer_sk = c.customer_sk
WHERE c.is_current = TRUE
GROUP BY 1
ORDER BY 5 DESC;
```

### Payment channel breakdown
```sql
SELECT
    pm.payment_method,
    pm.payment_category,
    COUNT(*)              AS transactions,
    SUM(f.amount_paid)    AS total_collected,
    SUM(CASE WHEN f.is_refund THEN 1 ELSE 0 END) AS refunds
FROM marts.fct_payments f
JOIN marts.dim_payment_method pm
    ON f.payment_method_sk = pm.payment_method_sk
GROUP BY 1, 2
ORDER BY 3 DESC;
```

### Order fulfilment speed by store
```sql
SELECT
    s.store_name,
    ROUND(AVG(o.lifecycle_days), 1) AS avg_days_to_deliver,
    COUNT(*)                         AS delivered_orders,
    MIN(o.lifecycle_days)            AS fastest_delivery,
    MAX(o.lifecycle_days)            AS slowest_delivery
FROM marts.fct_order_lifecycle o
JOIN marts.dim_store s ON o.store_sk = s.store_sk
WHERE o.lifecycle_days IS NOT NULL
GROUP BY 1
ORDER BY 2;
```

### Inventory levels by product and store
```sql
SELECT
    p.product_name,
    p.category,
    s.store_name,
    i.closing_stock,
    i.units_sold,
    i.units_restocked
FROM marts.fct_inventory_daily i
JOIN marts.dim_product p ON i.product_sk = p.product_sk
JOIN marts.dim_store s   ON i.store_sk   = s.store_sk
WHERE i.snapshot_date = CURRENT_DATE - 1
AND p.is_current = TRUE
ORDER BY i.closing_stock ASC;
```

### Data quality: flagged payments
```sql
SELECT
    flag_reason,
    COUNT(*)                AS count,
    SUM(ABS(amount_paid))   AS amount_at_risk
FROM marts.flagged_payments
GROUP BY 1
ORDER BY 2 DESC;
```

---

## Key Design Decisions

### SCD Type 2
`dim_customer` and `dim_product` implement Slowly Changing Dimension Type 2 using dbt snapshots. When a customer changes segment or a product changes price, a new row is added, and the old row is closed. This means historical fact rows always reference the correct version of the dimension at the time of the transaction.

### Surrogate Keys
All dimension tables use MD5-based surrogate keys generated by `dbt_utils.generate_surrogate_key`. Fact tables reference surrogate keys only, never natural keys from the source system.

### Incremental Loading
Both layers are incremental:
- **Extractor:** stores a watermark (last `updated_at`) per entity and passes `?updated_after=<watermark>` to the API on subsequent runs
- **dlt pipeline:** uses `dlt.sources.incremental` on `updated_at` so only changed rows move each run

### Idempotency
Running the pipeline twice on the same date produces identical results:
- Extractor uses `INSERT ... ON CONFLICT (id) DO UPDATE`
- dlt uses `write_disposition="merge"` with primary key
- No duplicate rows are ever created

### Flagged Payments
Anomalous payments (zero amount and unexplained negatives) are isolated in `flagged_payments` and excluded from `fct_payments`. This keeps revenue analysis clean while preserving the anomalous records for investigation.

---

## Checkpoints Summary

| Checkpoint | Description | Deliverable |
|---|---|---|
| CP1 | Design | Bus matrix, Warehouse ERD, Architecture diagram |
| CP2 | Extract | Python ERP extractor with Airflow DAG |
| CP3 | Load | dlt incremental pipeline (lake → warehouse) |
| CP4 | Model | dbt Kimball dimensional models (6 dims, 4 facts) |
| CP5 | Operate | Full Airflow orchestration + Docker Compose |

---

## Team

**Team F: HNG Stage 8 Data Engineering**

Team ID: fce38a75-4c91-4440-b01a-d407db52d54e
GitHub: https://github.com/R887645/RetailCo-Data-Platform-HNG-Stage-8_TeamF
