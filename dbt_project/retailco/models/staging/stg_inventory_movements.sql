-- stg_inventory_movements.sql
with
    source
    as
    (
    select *
    from {{ source('raw', 'inventory_movements') }}
),
final as
(
    select
        raw_data->>'id'                             as movement_id,
        raw_data->>'productId'                      as product_id,
        raw_data->>'storeId'                        as store_id,
        raw_data->>'movementType'                   as movement_type,
        (raw_data->>'quantity')::int                as quantity,
        raw_data->>'referenceId'                    as reference_id,
        raw_data->>'referenceType'                  as reference_type,
        raw_data->>'notes'                          as notes,
        (raw_data->>'movedAt')::timestamp           as moved_at,
        (raw_data->>'createdAt')::timestamp         as created_at,
        (raw_data->>'updatedAt')::timestamp         as updated_at
    from source
)
select * from final