-- stg_orders.sql
with
    source
    as
    (
    select *
    from {{ source('raw', 'orders') }}
),
final as
(
    select
        raw_data->>'id'                             as order_id,
        raw_data->>'customerId'                     as customer_id,
        raw_data->>'storeId'                        as store_id,
        raw_data->>'employeeId'                     as employee_id,
        raw_data->>'status'                         as status,
        raw_data->>'discountCode'                   as discount_code,
        (raw_data->>'discountAmount')::decimal      as discount_amount,
        (raw_data->>'totalAmount')::decimal         as total_amount,
        (raw_data->>'orderedAt')::timestamp         as ordered_at,
        (raw_data->>'paidAt')::timestamp            as paid_at,
        (raw_data->>'shippedAt')::timestamp         as shipped_at,
        (raw_data->>'deliveredAt')::timestamp       as delivered_at,
        (raw_data->>'cancelledAt')::timestamp       as cancelled_at,
        (raw_data->>'createdAt')::timestamp         as created_at,
        (raw_data->>'updatedAt')::timestamp         as updated_at
    from source
)
select * from final