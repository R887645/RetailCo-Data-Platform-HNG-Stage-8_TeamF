with source as (
    select * from {{ source('raw', 'payments') }}
),
final as (
    select
        raw_data__id                                as payment_id,
        raw_data__order_id                          as order_id,
        raw_data__customer_id                       as customer_id,
        raw_data__payment_method_id                 as payment_method_id,
        raw_data__amount_paid::decimal              as amount_paid,
        raw_data__currency                          as currency,
        raw_data__status                            as status,
        raw_data__payment_type                      as payment_type,
        raw_data__reference                         as reference,
        raw_data__paid_at                           as paid_at,
        raw_data__created_at                        as created_at,
        raw_data__updated_at                        as updated_at
    from source
)
select * from final