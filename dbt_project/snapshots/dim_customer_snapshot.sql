
{% snapshot dim_customer_snapshot %}

{{
    config
(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

select
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    segment,
    tier,
    address,
    city,
    state,
    effective_from,
    registered_at,
    is_deleted,
    updated_at
from {{ ref('stg_customers') }}

{% endsnapshot %}