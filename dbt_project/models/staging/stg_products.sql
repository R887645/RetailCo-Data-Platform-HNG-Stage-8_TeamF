with source as (
    select * from {{ source('raw', 'products') }}
),
final as (
    select
        raw_data__id                                as product_id,
        raw_data__sku                               as sku,
        raw_data__name                              as product_name,
        raw_data__category                          as category,
        raw_data__sub_category                      as sub_category,
        raw_data__brand                             as brand,
        raw_data__supplier                          as supplier,
        raw_data__cost_price::decimal               as cost_price,
        raw_data__selling_price::decimal            as selling_price,
        raw_data__effective_from                    as effective_from,
        raw_data__is_deleted                        as is_deleted,
        raw_data__created_at                        as created_at,
        raw_data__updated_at                        as updated_at
    from source
)
select * from final