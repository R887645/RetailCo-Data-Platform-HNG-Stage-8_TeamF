-- Custom test: fct_payments must contain no zero amount payments
-- those should be in flagged_payments instead
select *
from {{ ref('fct_payments') }}
where amount_paid = 0