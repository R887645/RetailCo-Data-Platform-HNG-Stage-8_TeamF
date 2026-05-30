-- dim_product_snapshot.sql
-- Business justification: SCD2 snapshot for dim_product.
-- Tracks changes to product price and category over time.
-- Uses updated_at as the strategy column so any API update
-- triggers a new snapshot row with correct valid_from
-- and valid_to dates.
-- Discontinued products kept as final history slice
-- with is_current = false in dim_product so historical
-- sales facts still resolve with correct price at time of sale.

{% snapshot dim_product_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='product_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

select * from {{ ref('stg_products') }}

{% endsnapshot %}