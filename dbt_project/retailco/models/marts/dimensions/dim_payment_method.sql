-- dim_payment_method.sql
with source as (
    select * from {{ ref('stg_payment_methods') }}
),
final as (
    select
        {{ dbt_utils.generate_surrogate_key(['payment_method_id']) }}  as payment_method_sk,
        payment_method_id,
        payment_method_name,
        provider,
        is_digital
    from source
)
select * from final