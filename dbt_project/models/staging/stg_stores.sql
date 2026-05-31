-- stg_stores.sql
with source as (
    select * from {{ source('raw', 'stores') }}
),
final as (
    select
        raw_data__id                                as store_id,
        raw_data__name                              as store_name,
        raw_data__city                              as city,
        raw_data__state                             as state,
        raw_data__address                           as address,
        raw_data__manager_name                      as manager_name,
        raw_data__created_at                        as created_at,
        raw_data__updated_at                        as updated_at
    from source
)
select * from final