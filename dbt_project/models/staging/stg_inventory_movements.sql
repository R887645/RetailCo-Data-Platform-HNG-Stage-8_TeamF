-- stg_inventory_movements.sql
-- Business justification: standardises raw inventory movement data.
-- quantity cast to int for daily snapshot aggregation in
-- fct_inventory_daily. moved_at cast to timestamp for date bucketing.

with source as (
    select * from {{ source('raw', 'inventory_movements') }}
),

renamed as (
    select
        id::varchar               as movement_id,
        team_id::varchar          as team_id,
        product_id::varchar       as product_id,
        store_id::varchar         as store_id,
        movement_type::varchar    as movement_type,
        quantity::int             as quantity,
        reference_id::varchar     as reference_id,
        reference_type::varchar   as reference_type,
        notes::text               as notes,
        moved_at::timestamp       as moved_at,
        created_at::timestamp     as created_at,
        updated_at::timestamp     as updated_at
    from source
)

select * from renamed