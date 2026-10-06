with source as (
    select * from {{ source('airbnb_staging', 'hosts') }}
),

cleaned as (
    select
        host_id,
        trim(host_name) as host_name,
        host_since,
        is_superhost,
        response_rate,
        created_at
    from source
    where host_id is not null
)

select * from cleaned
