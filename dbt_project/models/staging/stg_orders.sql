with source as (
    select * from {{ source('raw', 'orders') }}
),
final as (
    select
        raw_data__id                                as order_id,
        raw_data__customer_id                       as customer_id,
        raw_data__store_id                          as store_id,
        raw_data__employee_id                       as employee_id,
        raw_data__status                            as status,
        raw_data__discount_code                     as discount_code,
        raw_data__discount_amount::decimal          as discount_amount,
        raw_data__total_amount::decimal             as total_amount,
        raw_data__ordered_at                        as ordered_at,
        raw_data__paid_at                           as paid_at,
        raw_data__shipped_at                        as shipped_at,
        raw_data__delivered_at                      as delivered_at,
        raw_data__cancelled_at                      as cancelled_at,
        raw_data__created_at                        as created_at,
        raw_data__updated_at                        as updated_at
    from source
)
select * from final