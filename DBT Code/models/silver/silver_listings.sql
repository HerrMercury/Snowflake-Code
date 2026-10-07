with listings as (
    select * from {{ ref('bronze_listings') }}
),

hosts as (
    select * from {{ ref('silver_hosts') }}
),

joined as (
    select
        listings.listing_id,
        listings.host_id,
        hosts.host_name,
        hosts.is_superhost as host_is_superhost,
        listings.property_type,
        listings.room_type,
        listings.city,
        listings.country,
        listings.accommodates,
        listings.bedrooms,
        listings.bathrooms,
        listings.price_per_night,
        listings.created_at,
        {{ loaded_at_column('silver') }}
    from listings
    left join hosts
        on listings.host_id = hosts.host_id
)

select * from joined
