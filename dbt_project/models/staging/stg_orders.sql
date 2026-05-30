-- stg_orders.sql
-- Business justification: standardises raw order data from the ERP API.
-- All status timestamps cast to timestamp for lifecycle tracking.
-- Keeps all orders including cancelled for fct_order_lifecycle.

with source as (
    select * from {{ source('raw', 'orders') }}
),

renamed as (
    select
        id::varchar                as order_id,
        team_id::varchar           as team_id,
        customer_id::varchar       as customer_id,
        store_id::varchar          as store_id,
        employee_id::varchar       as employee_id,
        status::varchar            as status,
        discount_code::varchar     as discount_code,
        discount_amount::decimal   as discount_amount,
        total_amount::decimal      as total_amount,
        ordered_at::timestamp      as ordered_at,
        paid_at::timestamp         as paid_at,
        shipped_at::timestamp      as shipped_at,
        delivered_at::timestamp    as delivered_at,
        cancelled_at::timestamp    as cancelled_at,
        created_at::timestamp      as created_at,
        updated_at::timestamp      as updated_at
    from source
)

select * from renamed