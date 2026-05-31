with source as (
    select * from {{ source('raw', 'customers') }}
),
final as (
    select
        raw_data__id                                as customer_id,
        raw_data__first_name                        as first_name,
        raw_data__last_name                         as last_name,
        raw_data__email                             as email,
        raw_data__phone                             as phone,
        raw_data__segment                           as segment,
        raw_data__tier                              as tier,
        raw_data__address                           as address,
        raw_data__city                              as city,
        raw_data__state                             as state,
        raw_data__effective_from                    as effective_from,
        raw_data__registered_at                     as registered_at,
        raw_data__is_deleted                        as is_deleted,
        raw_data__created_at                        as created_at,
        raw_data__updated_at                        as updated_at
    from source
)
select * from final