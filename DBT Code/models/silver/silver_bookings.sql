with bookings as (
    select * from {{ ref('bronze_bookings') }}
),

listings as (
    select * from {{ ref('silver_listings') }}
),

joined as (
    select
        bookings.booking_id,
        bookings.listing_id,
        listings.host_id,
        listings.city,
        listings.country,
        bookings.booking_date,
        bookings.nights_booked,
        bookings.booking_amount,
        bookings.cleaning_fee,
        bookings.service_fee,
        bookings.booking_amount + bookings.cleaning_fee + bookings.service_fee as total_amount,
        bookings.booking_status,
        bookings.created_at
    from bookings
    left join listings
        on bookings.listing_id = listings.listing_id
)

select * from joined
