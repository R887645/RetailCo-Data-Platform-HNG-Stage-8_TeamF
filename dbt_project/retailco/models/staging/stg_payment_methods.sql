-- stg_payment_methods.sql
with 
    source 
    as(
        
    select * 
    from {{ source('raw', 'payment_methods') }}
),
final as (
    select
        raw_data->>'id'                         as payment_method_id,
        raw_data->>'name'                       as payment_method_name,
        raw_data->>'provider'                   as provider,
        (raw_data->>'isDigital')::boolean       as is_digital,
        (raw_data->>'createdAt')::timestamp     as created_at,
        (raw_data->>'updatedAt')::timestamp     as updated_at
    from source
)
select * from final