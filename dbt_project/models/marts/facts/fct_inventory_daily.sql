-- fct_inventory_daily.sql
-- Grain: one row per product per store per day
-- Built by aggregating raw inventory_movements into daily snapshots
with movements as (
    select * from {{ ref('stg_inventory_movements') }}
),
dim_date as (
    select * from {{ ref('dim_date') }}
),
dim_product as (
    select * from {{ ref('dim_product') }}
    where is_current = true
),
dim_store as (
    select * from {{ ref('dim_store') }}
),
daily_movements as (
    select
        moved_at::date                          as movement_date,
        product_id,
        store_id,
        sum(case
            when movement_type in (
                'purchase', 'return_in', 'adjustment_in'
            )
            then quantity else 0
        end)                                    as stock_received,
        sum(case
            when movement_type in (
                'sale', 'return_out', 'adjustment_out'
            )
            then quantity else 0
        end)                                    as stock_sold
    from movements
    group by 1, 2, 3
),
with_running_totals as (
    select
        movement_date,
        product_id,
        store_id,
        stock_received,
        stock_sold,
        coalesce(
            sum(stock_received - stock_sold) over (
                partition by product_id, store_id
                order by movement_date
                rows between unbounded preceding and 1 preceding
            ), 0
        )                                       as opening_stock,
        coalesce(
            sum(stock_received - stock_sold) over (
                partition by product_id, store_id
                order by movement_date
                rows between unbounded preceding and current row
            ), 0
        )                                       as closing_stock
    from daily_movements
),
final as (
    select
        {{ dbt_utils.generate_surrogate_key([
            'wrt.movement_date',
            'wrt.product_id',
            'wrt.store_id'
        ]) }}                                   as inventory_snapshot_sk,
        dd.date_key,
        dp.product_sk,
        ds.store_sk,
        wrt.opening_stock,
        wrt.stock_received,
        wrt.stock_sold,
        wrt.closing_stock
    from with_running_totals wrt
    join dim_date dd
        on dd.full_date = wrt.movement_date
    join dim_product dp
        on dp.product_id = wrt.product_id
    join dim_store ds
        on ds.store_id = wrt.store_id
)
select * from final