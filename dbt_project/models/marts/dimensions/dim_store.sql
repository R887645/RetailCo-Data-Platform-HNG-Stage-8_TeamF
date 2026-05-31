-- dim_store.sql
-- Business justification: store dimension with surrogate key.
-- Stores represent physical retail locations across Nigeria.
-- No SCD2 needed: store changes are not tracked historically.
-- Surrogate key store_sk used in all fact tables instead of
-- natural key store_id to follow Kimball principles.

with stores as (
    select * from {{ ref('stg_stores') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['store_id']) }}
                                   as store_sk,
        store_id,
        store_name,
        city,
        state,
        address,
        manager_name
    from stores
)

select * from final
