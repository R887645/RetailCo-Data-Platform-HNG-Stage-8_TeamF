with source as (
    select * from {{ source('raw', 'order_items') }}
),
final as (
    select
        raw_data__id                                as order_item_id,
        raw_data__order_id                          as order_id,
        raw_data__product_id                        as product_id,
        raw_data__quantity::int                     as quantity,
        raw_data__unit_price::decimal               as unit_price,
        raw_data__discount_pct::decimal             as discount_pct,
        raw_data__line_total::decimal               as line_total,
        raw_data__created_at                        as created_at,
        raw_data__updated_at                        as updated_at
    from source
)
select * from final