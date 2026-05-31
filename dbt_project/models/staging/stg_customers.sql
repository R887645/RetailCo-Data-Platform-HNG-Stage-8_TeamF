-- stg_customers.sql
with
    source
    as
    (
    select *
    from {{ source('raw', 'customers') }}
),
final as
(
    select
        raw_data->>'id'                             as customer_id,
        raw_data->>'firstName'                      as first_name,
        raw_data->>'lastName'                       as last_name,
        raw_data->>'email'                          as email,
        raw_data->>'phone'                          as phone,
        raw_data->>'segment'                        as segment,
        raw_data->>'tier'                           as tier,
        raw_data->>'address'                        as address,
        raw_data->>'city'                           as city,
        raw_data->>'state'                          as state,
        (raw_data->>'effectiveFrom')::timestamp     as effective_from,
        (raw_data->>'registeredAt')::timestamp      as registered_at,
        (raw_data->>'isDeleted')::boolean           as is_deleted,
        (raw_data->>'createdAt')::timestamp         as created_at,
        (raw_data->>'updatedAt')::timestamp         as updated_at
    from source
)
select * from final