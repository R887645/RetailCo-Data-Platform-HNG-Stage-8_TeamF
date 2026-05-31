-- stg_products.sql
with
    source
    as
    (
    select *
    from {{ source('raw', 'products') }}
),
final as
(
    select
        raw_data->>'id'                             as product_id,
        raw_data->>'sku'                            as sku,
        raw_data->>'name'                           as product_name,
        raw_data->>'category'                       as category,
        raw_data->>'subCategory'                    as sub_category,
        raw_data->>'brand'                          as brand,
        raw_data->>'supplier'                       as supplier,
        (raw_data->>'costPrice')::decimal           as cost_price,
        (raw_data->>'sellingPrice')::decimal        as selling_price,
        (raw_data->>'effectiveFrom')::timestamp     as effective_from,
        (raw_data->>'isDeleted')::boolean           as is_deleted,
        (raw_data->>'createdAt')::timestamp         as created_at,
        (raw_data->>'updatedAt')::timestamp         as updated_at
    from source
)
select * from final