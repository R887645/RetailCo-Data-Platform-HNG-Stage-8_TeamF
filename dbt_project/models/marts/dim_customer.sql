-- dim_customer.sql
-- Business justification: SCD2 customer dimension with surrogate key.
-- Reads from dim_customer_snapshot which tracks all changes to
-- customer segment, tier and address over time.
-- Soft deleted customers kept with is_current = false so historical
-- facts that reference them still resolve correctly.

with snapshot as (
    select * from {{ ref('dim_customer_snapshot') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['customer_id', 'dbt_scd_id']
        ) }}                        as customer_sk,
        customer_id,
        first_name,
        last_name,
        email,
        phone,
        segment,
        tier,
        address,
        city,
        state,
        is_deleted,
        dbt_valid_from              as valid_from,
        dbt_valid_to                as valid_to,
        case
            when dbt_valid_to is null
            then true else false
        end                         as is_current
    from snapshot
)

select * from final