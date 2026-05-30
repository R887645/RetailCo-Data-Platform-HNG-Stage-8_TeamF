-- stg_products.sql
-- Business justification: standardises raw product data from the ERP API.
-- Keeps is_deleted rows for SCD2 history tracking.
-- cost_price and selling_price cast to decimal for margin calculations.

with source as (
    select * from {{ source('raw', 'products') }}
),

renamed as (
    select
        id::varchar                as product_id,
        team_id::varchar           as team_id,
        sku::varchar               as sku,
        name::varchar              as product_name,
        category::varchar          as category,
        sub_category::varchar      as sub_category,
        brand::varchar             as brand,
        supplier::varchar          as supplier,
        cost_price::decimal        as cost_price,
        selling_price::decimal     as selling_price,
        effective_from::timestamp  as effective_from,
        is_deleted::boolean        as is_deleted,
        created_at::timestamp      as created_at,
        updated_at::timestamp      as updated_at
    from source
)

select * from renamed