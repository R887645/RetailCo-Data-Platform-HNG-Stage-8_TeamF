-- stg_customers.sql
-- Business justification: standardises raw customer data from the ERP API.
-- Casts all columns to correct types, renames to snake_case,
-- and keeps is_deleted rows so SCD2 snapshots can track
-- the full history of customer changes including deletions.

with source as (
    select * from {{ source('raw', 'customers') }}
),

renamed as (
    select
        id::varchar                  as customer_id,
        team_id::varchar             as team_id,
        first_name::varchar          as first_name,
        last_name::varchar           as last_name,
        email::varchar               as email,
        phone::varchar               as phone,
        segment::varchar             as segment,
        tier::varchar                as tier,
        address::varchar             as address,
        city::varchar                as city,
        state::varchar               as state,
        effective_from::timestamp    as effective_from,
        registered_at::timestamp     as registered_at,
        is_deleted::boolean          as is_deleted,
        created_at::timestamp        as created_at,
        updated_at::timestamp        as updated_at
    from source
)

select * from renamed
