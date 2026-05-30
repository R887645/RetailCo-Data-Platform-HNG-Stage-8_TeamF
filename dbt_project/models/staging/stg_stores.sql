-- stg_stores.sql
-- Business justification: standardises raw store data from ERP API.
-- Stores represent physical retail locations across Nigeria.
-- opened_date cast to date for store age analysis.

with source as (
    select * from {{ source('raw', 'stores') }}
),

renamed as (
    select
        id::varchar                as store_id,
        team_id::varchar           as team_id,
        name::varchar              as store_name,
        city::varchar              as city,
        state::varchar             as state,
        address::varchar           as address,
        phone::varchar             as phone,
        manager_name::varchar      as manager_name,
        opened_date::date          as opened_date,
        created_at::timestamp      as created_at,
        updated_at::timestamp      as updated_at
    from source
)

select * from renamed