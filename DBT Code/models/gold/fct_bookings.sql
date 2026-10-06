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
    created_at
from {{ ref('silver_bookings') }}
