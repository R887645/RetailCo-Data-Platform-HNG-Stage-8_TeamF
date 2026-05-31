-- dim_product.sql
-- Business justification: SCD2 product dimension with surrogate key.
-- Reads from dim_product_snapshot which tracks all changes to
-- product price and category over time.
-- Discontinued products kept with is_current = false so historical
-- sales facts still resolve correctly with correct price at time of sale.
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
