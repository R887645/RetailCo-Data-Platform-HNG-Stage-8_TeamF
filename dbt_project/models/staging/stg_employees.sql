-- stg_employees.sql
with 
    source 
    as(

    select * 
    from {{ source('raw', 'employees') }}
),
final as(
    select
        raw_data->>'id'                         as employee_id,
        raw_data->>'storeId'                    as store_id,
        raw_data->>'firstName'                  as first_name,
        raw_data->>'lastName'                   as last_name,
        raw_data->>'email'                      as email,
        raw_data->>'role'                       as role,
        raw_data->>'hiredDate'                  as hired_date,
        (raw_data->>'isDeleted')::boolean       as is_deleted,
        (raw_data->>'createdAt')::timestamp     as created_at,
        (raw_data->>'updatedAt')::timestamp     as updated_at
    from source
)
select *from final