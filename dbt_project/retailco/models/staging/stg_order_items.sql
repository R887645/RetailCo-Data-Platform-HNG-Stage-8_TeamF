-- stg_order_items.sql
with
    source
    as
    (
    select *
    from {{ source('raw', 'order_items') }}
),
final as
(
    select
        raw_data->>'id'                             as order_item_id,
        raw_data->>'orderId'                        as order_id,
        raw_data->>'productId'                      as product_id,
        (raw_data->>'quantity')::int                as quantity,
        (raw_data->>'unitPrice')::decimal           as unit_price,
        (raw_data->>'discountPct')::decimal         as discount_pct,
        (raw_data->>'lineTotal')::decimal           as line_total,
        (raw_data->>'createdAt')::timestamp         as created_at,
        (raw_data->>'updatedAt')::timestamp         as updated_at
    from source
)
select * from final