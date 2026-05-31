-- Custom test: closing stock should never be negative
select *
from {{ ref('fct_inventory_daily') }}
where closing_stock < 0