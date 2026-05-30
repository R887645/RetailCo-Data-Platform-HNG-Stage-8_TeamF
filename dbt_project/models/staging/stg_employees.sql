-- stg_employees.sql
-- Business justification: standardises raw employee data from ERP API.
-- Employees are linked to stores via store_id.
-- is_deleted kept for soft delete handling in dim_employee.
-- hired_date cast to date for employee tenure analysis.

with source as (
    select * from {{ source('raw', 'employees') }}
),

renamed as (
    select
        id::varchar                as employee_id,
        team_id::varchar           as team_id,
        store_id::varchar          as store_id,
        first_name::varchar        as first_name,
        last_name::varchar         as last_name,
        email::varchar             as email,
        role::varchar              as role,
        hired_date::date           as hired_date,
        is_deleted::boolean        as is_deleted,
        created_at::timestamp      as created_at,
        updated_at::timestamp      as updated_at
    from source
)

select * from renamed