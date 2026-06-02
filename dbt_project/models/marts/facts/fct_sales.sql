-- fct_sales.sql
-- Grain: one row per order line item
-- Business justification: transactional fact table capturing every
-- product sold in every order. References surrogate keys from all
-- relevant dimensions. Cancelled orders excluded from revenue analysis.
-- margin_amount calculated as line_total minus cost_price x quantity.
-- fct_sales.sql
-- Grain: one row per order line item

with order_items as (

    select * from {{ ref('stg_order_items') }}
),

orders as (

    select *
    from {{ ref('stg_orders') }}
    where status != 'cancelled'

),

dim_date as (
    select * from {{ ref('dim_date') }}
),

dim_customer as (
    select * from {{ ref('dim_customer') }}
),

dim_product as (
    select * from {{ ref('dim_product') }}

),

dim_store as (
    select * from {{ ref('dim_store') }}
),

dim_employee as (
    select * from {{ ref('dim_employee') }}
),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['oi.order_item_id']) }} as sales_sk,

        oi.order_id,
        oi.order_item_id,

        dd.date_key,
        dc.customer_sk,
        dp.product_sk,
        ds.store_sk,
        de.employee_sk,

        o.status as order_status,

        oi.quantity,
        oi.unit_price,

        (oi.quantity * oi.unit_price) as gross_amount,

        coalesce(oi.discount_pct, 0) as discount_pct,

        round(
            (oi.quantity * oi.unit_price)
            * coalesce(oi.discount_pct, 0) / 100,
            2
        ) as discount_amount,

        oi.line_total as net_amount,

        round(
            oi.line_total -
            (
                coalesce(dp.cost_price, 0) * oi.quantity
            ),
            2
        ) as margin_amount

    from order_items oi

    join orders o
        on oi.order_id = o.order_id

    join dim_date dd
        on dd.full_date = o.ordered_at::date

    join dim_customer dc
        on dc.customer_id = o.customer_id
        and o.ordered_at >= dc.valid_from
        and (
            dc.valid_to is null
            or o.ordered_at < dc.valid_to
        )

    join dim_product dp
        on dp.product_id = oi.product_id
        and o.ordered_at >= dp.valid_from
        and (
            dp.valid_to is null
            or o.ordered_at < dp.valid_to
        )

    join dim_store ds
        on ds.store_id = o.store_id

    left join dim_employee de
        on de.employee_id = o.employee_id
)
select * from final
