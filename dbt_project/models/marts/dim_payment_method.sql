-- dim_payment_method.sql
-- Business justification: payment method dimension with surrogate key.
-- Describes how customers pay — cash, card, transfer, mobile money.
-- is_digital flag enables payment channel analysis separating
-- digital payments from cash transactions.
-- No SCD2 needed — payment methods do not change historically.

with payment_methods as (
    select * from {{ ref('stg_payment_methods') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['payment_method_id']
        ) }}                        as payment_method_sk,
        payment_method_id,
        payment_method_name,
        provider,
        is_digital
    from payment_methods
)

select * from final