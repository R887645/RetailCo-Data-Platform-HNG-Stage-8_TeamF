-- Custom test: all sales quantities must be greater than zero
select *
from {{ ref('fct_sales') }}
where quantity <= 0