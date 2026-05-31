with source as (
    select * from {{ source('raw', 'inventory_movements') }}
),
final as (
    select
        raw_data__id                                as movement_id,
        raw_data__product_id                        as product_id,
        raw_data__store_id                          as store_id,
        raw_data__movement_type                     as movement_type,
        raw_data__quantity::int                     as quantity,
        raw_data__reference_id                      as reference_id,
        raw_data__reference_type                    as reference_type,
        raw_data__notes                             as notes,
        raw_data__moved_at                          as moved_at,
        raw_data__created_at                        as created_at,
        raw_data__updated_at                        as updated_at
    from source
)
select * from final