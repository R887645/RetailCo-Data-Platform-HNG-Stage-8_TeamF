-- fct_sales.sql
-- Grain: one row per order line item
-- Business justification: transactional fact table capturing every
-- product sold in every order. References surrogate keys from all
-- relevant dimensions. Cancelled orders excluded from revenue analysis.
-- margin_amount calculated as line_total minus cost_price x quantity.

with order_items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
    where status != 'cancelled'
),

dim_date as (
    select * from {{ ref('dim_date') }}
),

dim_customer as (
    select * from {{ ref('dim_customer') }}
    where is_current = true
),

dim_product as (
    select * from {{ ref('dim_product') }}
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
            ['oi.order_item_id']
        ) }}                                as sales_sk,
        oi.order_id,
        oi.order_item_id,
        dd.date_key,
        dc.customer_sk,
        dp.product_sk,
        ds.store_sk,
        de.employee_sk,
        oi.quantity,
        oi.unit_price,
        oi.line_total                       as gross_amount,
        round(
            oi.line_total * oi.discount_pct / 100, 2
        )                                   as discount_amount,
        round(
            oi.line_total - (oi.line_total * oi.discount_pct / 100), 2
        )                                   as net_amount,
        round(
            oi.line_total - (dp.cost_price * oi.quantity), 2
        )                                   as margin_amount
    from order_items oi
    join orders o
        on oi.order_id = o.order_id
    join dim_date dd
        on dd.full_date = o.ordered_at::date
    join dim_customer dc
        on dc.customer_id = o.customer_id
    join dim_product dp
        on dp.product_id = oi.product_id
    join dim_store ds
        on ds.store_id = o.store_id
    left join dim_employee de
        on de.employee_id = o.employee_id
)

select * from final