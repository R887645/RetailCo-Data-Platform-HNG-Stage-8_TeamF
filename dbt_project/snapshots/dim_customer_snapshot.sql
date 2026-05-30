-- dim_customer_snapshot.sql
-- Business justification: SCD2 snapshot for dim_customer.
-- Tracks changes to customer segment, tier, address over time.
-- Uses updated_at as the strategy column so any API update
-- triggers a new snapshot row.
-- Soft deleted customers kept as final history slice
-- with is_current = false in dim_customer.

{% snapshot dim_customer_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

select * from {{ ref('stg_customers') }}

{% endsnapshot %}