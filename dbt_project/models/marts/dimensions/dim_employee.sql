-- dim_employee.sql
-- Business justification: employee dimension with surrogate key.
-- Employees are linked to stores via store_sk foreign key.
-- is_deleted is kept to identify former employees.
-- Soft-deleted employees are kept in the dimension so that historical
-- facts that reference them still resolve correctly.
-- No SCD2 needed — employee changes not tracked historically.

with employees as (
    select * from {{ ref('stg_employees') }}
),

dim_store as (
    select * from {{ ref('dim_store') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['e.employee_id']) }}
                                   as employee_sk,
        e.employee_id,
        ds.store_sk,
        e.first_name,
        e.last_name,
        e.email,
        e.role,
        e.hired_date,
        e.is_deleted
    from employees e
    left join dim_store ds
        on ds.store_id = e.store_id
)

select * from final
