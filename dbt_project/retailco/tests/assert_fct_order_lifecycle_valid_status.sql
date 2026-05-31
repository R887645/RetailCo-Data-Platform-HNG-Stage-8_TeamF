-- Custom test: all orders must have a recognised status
select *
from {{ ref('fct_order_lifecycle') }}
where current_status not in (
    'pending',
    'paid',
    'shipped',
    'delivered',
    'cancelled'
)