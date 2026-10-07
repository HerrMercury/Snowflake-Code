with hosts as (
    select * from {{ ref('bronze_hosts') }}
),

conformed as (
    select
        host_id,
        host_name,
        host_since,
        is_superhost,
        response_rate,
        datediff('day', host_since, current_date()) as host_tenure_days,
        created_at,
        {{ loaded_at_column('silver') }}
    from hosts
)

select * from conformed
