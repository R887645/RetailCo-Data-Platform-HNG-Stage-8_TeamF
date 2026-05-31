with source as (
    select * from {{ source('raw', 'payment_methods') }}
),
final as (
    select
        raw_data__id                                as payment_method_id,
        raw_data__name                              as payment_method_name,
        raw_data__provider                          as provider,
        raw_data__is_digital                        as is_digital,
        raw_data__created_at                        as created_at,
        raw_data__updated_at                        as updated_at
    from source
)
select * from final