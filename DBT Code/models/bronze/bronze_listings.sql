with source as (
    select * from {{ source('airbnb_staging', 'listings') }}
),

cleaned as (
    select
        listing_id,
        host_id,
        trim(property_type) as property_type,
        trim(room_type) as room_type,
        trim(city) as city,
        trim(country) as country,
        accommodates,
        bedrooms,
        bathrooms,
        price_per_night,
        created_at,
        {{ loaded_at_column('bronze') }}
    from source
    where listing_id is not null
      and host_id is not null
      and price_per_night >= 0
)

select * from cleaned
