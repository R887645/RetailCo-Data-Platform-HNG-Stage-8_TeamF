-- fct_payments.sql
-- Grain: one row per payment event
-- Business justification: transactional fact table capturing every
-- clean payment made against an order. Anomalous payments
-- (zero amount and unexplained negatives) are excluded here
-- and isolated in flagged_payments for data quality investigation.
-- Refunds with negative amount_paid are kept as valid records.
-- is_refund flag allows separate analysis of refund patterns.

with payments as (
    select * from {{ ref('stg_payments') }}
    where not (
        amount_paid = 0
        or (amount_paid < 0 and payment_type != 'refund')
    )
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

dim_payment_method as (
    select * from {{ ref('dim_payment_method') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['p.payment_id']
        ) }}                                as payment_sk,
        p.payment_id,
        p.order_id,
        dd.date_key,
        dc.customer_sk,
        ds.store_sk,
        dpm.payment_method_sk,
        p.amount_paid,
        p.currency,
        p.payment_type,
        case
            when p.amount_paid < 0
            then true else false
        end                                 as is_refund
    from payments p
    join dim_date dd
        on dd.full_date = p.paid_at::date
    join dim_customer dc
        on dc.customer_id = p.customer_id
    join orders o
        on o.order_id = p.order_id
    join dim_store ds
        on ds.store_id = o.store_id
    join dim_payment_method dpm
        on dpm.payment_method_id = p.payment_method_id
)

select * from final