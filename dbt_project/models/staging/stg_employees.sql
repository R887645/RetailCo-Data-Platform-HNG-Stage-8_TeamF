with source as (
    select * from {{ source('raw', 'employees') }}
),
final as (
    select
        raw_data__id                                as employee_id,
        raw_data__store_id                          as store_id,
        raw_data__first_name                        as first_name,
        raw_data__last_name                         as last_name,
        raw_data__email                             as email,
        raw_data__role                              as role,
        raw_data__hired_date                        as hired_date,
        raw_data__is_deleted                        as is_deleted,
        raw_data__created_at                        as created_at,
        raw_data__updated_at                        as updated_at
    from source
)
select * from final