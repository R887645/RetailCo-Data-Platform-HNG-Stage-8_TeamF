-- flagged_payments.sql
-- Business justification: data quality artifact that isolates
-- anomalous payment records from fct_payments.
-- Payments with amount_paid = 0 or unexplained negative amounts
-- are stored here for investigation by the compliance team.
-- This is NOT a fact table and does not appear in the bus matrix.

with payments as (
    select * from {{ ref('stg_payments') }}
),

dim_customer as (
    select * from {{ ref('dim_customer') }}
    where is_current = true
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['p.payment_id']
        ) }}                                as flagged_payment_sk,
        p.payment_id,
        p.order_id,
        dc.customer_sk,
        p.amount_paid,
        p.currency,
        p.payment_type,
        case
            when p.amount_paid = 0
                then 'zero amount payment'
            when p.amount_paid < 0
                and p.payment_type != 'refund'
                then 'unexplained negative amount'
            else 'other anomaly'
        end                                 as reason,
        p.created_at                        as flagged_at
    from payments p
    left join dim_customer dc
        on dc.customer_id = p.customer_id
    where p.amount_paid = 0
       or (p.amount_paid < 0 and p.payment_type != 'refund')
)

select * from final
