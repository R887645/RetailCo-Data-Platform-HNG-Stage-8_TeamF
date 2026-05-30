-- stg_order_items.sql
-- Business justification: standardises raw order item data from the ERP API.
-- unit_price, discount_pct and line_total cast to decimal
-- for accurate revenue and margin calculations in fct_sales.

with source as (
    select * from {{ source('raw', 'order_items') }}
),

renamed as (
    select
        id::varchar               as order_item_id,
        team_id::varchar          as team_id,
        order_id::varchar         as order_id,
        product_id::varchar       as product_id,
        quantity::int             as quantity,
        unit_price::decimal       as unit_price,
        discount_pct::decimal     as discount_pct,
        line_total::decimal       as line_total,
        created_at::timestamp     as created_at,
        updated_at::timestamp     as updated_at
    from source
)

select * from renamed