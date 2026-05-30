-- stg_payment_methods.sql
-- Business justification: standardises raw payment method data
-- from ERP API. Payment methods describe how customers pay —
-- cash, card, bank transfer, mobile money etc.
-- is_digital cast to boolean for payment channel analysis.

with source as (
    select * from {{ source('raw', 'payment_methods') }}
),

renamed as (
    select
        id::varchar                as payment_method_id,
        team_id::varchar           as team_id,
        name::varchar              as payment_method_name,
        provider::varchar          as provider,
        is_digital::boolean        as is_digital,
        created_at::timestamp      as created_at,
        updated_at::timestamp      as updated_at
    from source
)

select * from renamed