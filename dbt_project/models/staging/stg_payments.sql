-- stg_payments.sql
with
    source
    as
    (
    select *
    from {{ source('raw', 'payments') }}
),
final as
(
    select
        raw_data->>'id'                             as payment_id,
        raw_data->>'orderId'                        as order_id,
        raw_data->>'customerId'                     as customer_id,
        raw_data->>'paymentMethodId'                as payment_method_id,
        (raw_data->>'amountPaid')::decimal          as amount_paid,
        raw_data->>'currency'                       as currency,
        raw_data->>'status'                         as status,
        raw_data->>'paymentType'                    as payment_type,
        raw_data->>'reference'                      as reference,
        (raw_data->>'paidAt')::timestamp            as paid_at,
        (raw_data->>'createdAt')::timestamp         as created_at,
        (raw_data->>'updatedAt')::timestamp         as updated_at
    from source
)
select * from final