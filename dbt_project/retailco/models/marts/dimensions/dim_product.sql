-- dim_product.sql
-- SCD2 dimension built from snapshot
with snapshot as (
    select * from {{ ref('dim_product_snapshot') }}
),
final as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['product_id', 'dbt_scd_id']
        ) }}                                as product_sk,
        product_id,
        sku,
        product_name,
        category,
        sub_category,
        brand,
        supplier,
        cost_price::decimal                 as cost_price,
        selling_price::decimal              as selling_price,
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