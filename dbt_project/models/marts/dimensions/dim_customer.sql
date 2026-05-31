-- dim_customer.sql
-- SCD2 dimension built from snapshot
with snapshot as (
    select * from {{ ref('dim_customer_snapshot') }}
),
final as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['customer_id', 'dbt_scd_id']
        ) }}                                as customer_sk,
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
        dbt_valid_from                      as valid_from,
        dbt_valid_to                        as valid_to,
        case
            when dbt_valid_to is null
            then true else false
        end                                 as is_current
    from snapshot
)
select * from final