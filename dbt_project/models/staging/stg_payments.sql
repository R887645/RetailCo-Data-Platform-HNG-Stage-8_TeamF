-- stg_payments.sql
-- Business justification: standardises raw payment data from ERP API.
-- Keeps all payments including refunds and anomalous records.
-- Refunds have negative amount_paid and payment_type = refund.
-- Anomalous payments are filtered out in flagged_payments model.
-- amount_paid cast to decimal for accurate financial calculations.

with source as (
    select * from {{ source('raw', 'payments') }}
),

renamed as (
    select
        id::varchar                as payment_id,
        team_id::varchar           as team_id,
        order_id::varchar          as order_id,
        customer_id::varchar       as customer_id,
        payment_method_id::varchar as payment_method_id,
        amount_paid::decimal       as amount_paid,
        currency::varchar          as currency,
        status::varchar            as status,
        payment_type::varchar      as payment_type,
        reference::varchar         as reference,
        paid_at::timestamp         as paid_at,
        created_at::timestamp      as created_at,
        updated_at::timestamp      as updated_at
    from source
)

select * from renamed