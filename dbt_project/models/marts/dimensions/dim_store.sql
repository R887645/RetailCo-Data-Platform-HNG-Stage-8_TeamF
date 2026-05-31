-- dim_store.sql
-- No SCD2 needed — store attributes are stable
with source as (
    select * from {{ ref('stg_stores') }}
),
final as (
    select
        {{ dbt_utils.generate_surrogate_key(['store_id']) }}    as store_sk,
        store_id,
        store_name,
        city,
        state,
        address,
        manager_name
    from source
)
select * from final