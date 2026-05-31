-- stg_stores.sql
-- Unpacks raw JSON from lake, casts to correct types, renames to snake_case

with 
    source 
    as (

    select * 
    from {{ source('raw', 'stores') }}
),
final as (
    select
        raw_data->>'id'                         as store_id,
        raw_data->>'name'                       as store_name,
        raw_data->>'city'                       as city,
        raw_data->>'state'                      as state,
        raw_data->>'address'                    as address,
        raw_data->>'managerName'                as manager_name,
        (raw_data->>'createdAt')::timestamp     as created_at,
        (raw_data->>'updatedAt')::timestamp     as updated_at
    from source
)
select * from final