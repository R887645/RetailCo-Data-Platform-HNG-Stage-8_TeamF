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
        {{ dbt_utils.generate_surrogate_key(
            ['o.order_id']
        ) }}                                    as order_lifecycle_sk,
        o.order_id,
        dc.customer_sk,
        ds.store_sk,
        de.employee_sk,

        -- date keys for each status milestone
        created_dd.date_key                     as created_date_key,
        paid_dd.date_key                        as paid_date_key,
        shipped_dd.date_key                     as shipped_date_key,
        delivered_dd.date_key                   as delivered_date_key,
        cancelled_dd.date_key                   as cancelled_date_key,

        -- raw timestamps for detailed analysis
        o.ordered_at                            as order_created_at,
        o.paid_at,
        o.shipped_at,
        o.delivered_at,
        o.cancelled_at,

        o.status                                as current_status,

        -- lifecycle days from order creation to final status
        case
            when o.delivered_at is not null
                then extract(
                    day from o.delivered_at - o.ordered_at
                )::int
            when o.cancelled_at is not null
                then extract(
                    day from o.cancelled_at - o.ordered_at
                )::int
            else extract(
                day from now() - o.ordered_at
            )::int
        end                                     as lifecycle_days

    from orders o

    join dim_customer dc
        on dc.customer_id = o.customer_id

    join dim_store ds
        on ds.store_id = o.store_id

    left join dim_employee de
        on de.employee_id = o.employee_id

    -- join dim_date for each timestamp
    join dim_date created_dd
        on created_dd.full_date = o.ordered_at::date

    left join dim_date paid_dd
        on paid_dd.full_date = o.paid_at::date

    left join dim_date shipped_dd
        on shipped_dd.full_date = o.shipped_at::date

    left join dim_date delivered_dd
        on delivered_dd.full_date = o.delivered_at::date

    left join dim_date cancelled_dd
        on cancelled_dd.full_date = o.cancelled_at::date
)

select * from final