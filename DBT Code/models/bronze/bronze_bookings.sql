{{
    config(
        materialized='incremental',
        unique_key='booking_id'
    )
}}

with source as (
    select * from {{ source('airbnb_staging', 'bookings') }}
),

cleaned as (
    select
        booking_id,
        listing_id,
        booking_date,
        nights_booked,
        booking_amount,
        cleaning_fee,
        service_fee,
        trim(lower(booking_status)) as booking_status,
        created_at,
        {{ loaded_at_column('bronze') }}
    from source
    where booking_id is not null
      and listing_id is not null
      and nights_booked > 0
      and booking_amount >= 0

    {% if is_incremental() %}
      and created_at > (select max(created_at) from {{ this }})
    {% endif %}
)

select * from cleaned
