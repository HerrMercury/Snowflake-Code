{{
    config(
        materialized='incremental',
        unique_key='booking_id'
    )
}}

select
    booking_id,
    listing_id,
    host_id,
    booking_date,
    nights_booked,
    booking_amount,
    cleaning_fee,
    service_fee,
    total_amount,
    booking_status,
    created_at,
    {{ loaded_at_column('gold') }}
from {{ ref('silver_bookings') }}
{% if is_incremental() %}
where created_at > (select max(created_at) from {{ this }})
{% endif %}
