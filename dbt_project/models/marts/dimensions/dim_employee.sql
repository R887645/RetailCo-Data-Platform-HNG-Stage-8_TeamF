-- dim_employee.sql
-- No SCD2 needed : employee role changes are not tracked historically
with source as (
    select * from {{ ref('stg_employees') }}
),
stores as (
    select * from {{ ref('dim_store') }}
),
final as (
    select
        {{ dbt_utils.generate_surrogate_key(['e.employee_id']) }}   as employee_sk,
        e.employee_id,
        s.store_sk,
        e.first_name,
        e.last_name,
        e.email,
        e.role,
        e.hired_date::date                                          as hired_date,
        e.is_deleted
    from source e
    left join stores s
        on s.store_id = e.store_id
)
select * from final
