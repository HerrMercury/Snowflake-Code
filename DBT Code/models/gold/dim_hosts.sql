select
    host_id,
    host_name,
    host_since,
    is_superhost,
    response_rate,
    host_tenure_days
from {{ ref('silver_hosts') }}
