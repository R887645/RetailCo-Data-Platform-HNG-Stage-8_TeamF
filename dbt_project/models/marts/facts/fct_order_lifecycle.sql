-- fct_order_lifecycle.sql
-- Grain: one row per order
-- Business justification: accumulating snapshot fact table that
-- tracks each order through its full lifecycle from creation to
-- delivery or cancellation. Status timestamps fill in over time
-- as the order progresses through each stage.
-- lifecycle_days calculated as days from order creation to
-- final status for operational efficiency analysis.
with orders as (
    select * from {{ ref('stg_orders') }}
),
dim_date as (
    select * from {{ ref('dim_date') }}
),
dim_customer as (
    select * from {{ ref('dim_customer') }}
    where is_current = true
),
dim_store as (
    select * from {{ ref('dim_store') }}
),
dim_employee as (
    select * from {{ ref('dim_employee') }}
),
final as (
    select
        {{ dbt_utils.generate_surrogate_key(['o.order_id']) }}      as order_lifecycle_sk,
        o.order_id,
        dc.customer_sk,
        ds.store_sk,
        de.employee_sk,
        dd.date_key                                                 as created_date_key,
        case
            when o.paid_at is not null
            then (
                select date_key from {{ ref('dim_date') }}
                where full_date = o.paid_at::date
            )
        end                                                         as paid_date_key,
        case
            when o.shipped_at is not null
            then (
                select date_key from {{ ref('dim_date') }}
                where full_date = o.shipped_at::date
            )
        end                                                         as shipped_date_key,
        case
            when o.delivered_at is not null
            then (
                select date_key from {{ ref('dim_date') }}
                where full_date = o.delivered_at::date
            )
        end                                                         as delivered_date_key,
        case
            when o.cancelled_at is not null
            then (
                select date_key from {{ ref('dim_date') }}
                where full_date = o.cancelled_at::date
            )
        end                                                         as cancelled_date_key,
        o.ordered_at                                                as order_created_at,
        o.paid_at,
        o.shipped_at,
        o.delivered_at,
        o.cancelled_at,
        o.status                                                    as current_status,
        case
            when o.delivered_at is not null
            then extract(
                day from o.delivered_at - o.ordered_at
            )::int
        end                                                         as lifecycle_days
    from orders o
    join dim_date dd
        on dd.full_date = o.ordered_at::date
    join dim_customer dc
        on dc.customer_id = o.customer_id
    join dim_store ds
        on ds.store_id = o.store_id
    left join dim_employee de
        on de.employee_id = o.employee_id
)
select * from final
