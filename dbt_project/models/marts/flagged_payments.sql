-- flagged_payments.sql
-- Business justification: data quality artifact that isolates
-- anomalous payment records from fct_payments.
-- Payments with amount_paid = 0 or unexplained negative amounts
-- are stored here for investigation by the compliance team.
-- This is NOT a fact table and does not appear in the bus matrix.
-- It does not need conformed dimensions.

with payments as (
    select * from {{ ref('stg_payments') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['payment_id']
        ) }}                                as flagged_payment_sk,
        payment_id,
        order_id,
        customer_id,
        amount_paid,
        currency,
        case
            when amount_paid = 0
                then 'zero amount payment'
            when amount_paid < 0
                and payment_type != 'refund'
                then 'unexplained negative amount'
            else 'other anomaly'
        end                                 as flag_reason,
        created_at                          as flagged_at
    from payments
    where amount_paid = 0
       or (amount_paid < 0 and payment_type != 'refund')
)

select * from final