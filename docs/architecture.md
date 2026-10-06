# Medallion Architecture — Design Discussion (AirBnB on Snowflake + dbt)

This is a living doc, not a finished design. Use it to think through the Medallion
(Bronze/Silver/Gold) architecture before writing dbt models — the models themselves
you'll build yourself in `DBT Code/`.

## What already exists in Snowflake

From `Snowflake Objects/AirBnB Project/`:

- Database `AIRBNB` with schemas `STAGING`, `BRONZE`, `SILVER`, `GOLD` already created.
- `STAGING` has raw tables `HOSTS`, `LISTINGS`, `BOOKINGS` (see `Table DDL.sql`), loaded via
  `COPY INTO` from the `INT_SRC_FILES` stage (`Stage.sql`, `Ingestion into Staging.sql`).
- Nothing exists yet in `BRONZE`, `SILVER`, or `GOLD` — that's the part you're about to build.

## The general idea of each layer

| Layer | Typical purpose | Typical materialization |
|---|---|---|
| **Raw / Staging** | Exact copy of the source system. No logic. | Already-loaded tables |
| **Bronze** | Light cleaning: trim strings, cast types, drop obviously-broken rows. Still 1 row per source row. | Usually views |
| **Silver** | Joins and business-level entities (e.g. a listing with its host attached). Conformed, deduplicated, still grain = one real-world thing. | Views or tables |
| **Gold** | Dimensional model and/or pre-aggregated marts for reporting/BI. | Tables |

This is a starting framework, not a rulebook — worth challenging as we go (e.g. does a
given transformation really belong in Bronze or Silver? Does Gold need both a dimensional
model *and* an aggregate mart, or just one?).

## Open questions to work through together

- Which bronze model(s) do you want to build first — hosts, listings, or bookings?
- For listings/bookings: what's the right grain at each layer, and where does the
  host ↔ listing join belong (Silver)?
- What should Gold actually expose — raw dimensional tables (`dim_hosts`, `fct_bookings`),
  a pre-aggregated reporting mart (e.g. host performance), or both?
- Do we need `models/staging/sources.yml` to declare `AIRBNB.STAGING` as a dbt source
  before anything else can `ref()`/`source()` it?
- Schema routing: by default dbt appends the custom schema to the target schema
  (e.g. `dev_bronze`). Since `BRONZE`/`SILVER`/`GOLD` already exist as standalone
  schemas, do we want a `generate_schema_name` macro override, or a different approach?
- Testing strategy per layer — what gets a `unique`/`not_null`/`relationships` test,
  and at which layer?

## Decisions log

- **Schema routing**: overrode `generate_schema_name` (`macros/generate_schema_name.sql`) so a model's
  `+schema` config is used verbatim (uppercased), ignoring the profile's default schema. Models land in
  `AIRBNB.BRONZE` / `.SILVER` / `.GOLD` exactly, not `dbt_schema_bronze` etc.
- **Gold scope**: dimensional model only (`dim_hosts`, `dim_listings`, `fct_bookings`). No pre-aggregated
  mart yet — add one later if a reporting need shows up.
- **Materialization**: bronze = view, silver = view, gold = table (set per-folder in `dbt_project.yml`).
  Bronze/silver stay views since the data volume is small and they're cheap to recompute; gold is
  materialized as a table for downstream BI performance.
- **Grain / joins**: host↔listing join happens in Silver (`silver_listings`), listing↔booking join also in
  Silver (`silver_bookings`, which also derives `total_amount`). Gold tables are a thin select from Silver
  with only the columns needed for the dimensional model — descriptive attributes live on the dimensions,
  not duplicated onto the fact table.
- **`models/staging/sources.yml`**: yes, needed — added as `models/bronze/_airbnb__sources.yml` (declares
  `AIRBNB.STAGING.hosts/listings/bookings` as dbt sources) since bronze is the first layer to reference them.
- **Testing**: `not_null`/`unique` on every primary key at every layer; `relationships` (host_id, listing_id
  FKs) at silver and gold, set to `severity: warn` rather than `error` since the sample data's referential
  integrity isn't guaranteed to hold forever; `accepted_values` on `fct_bookings.booking_status`
  (`confirmed`/`cancelled`, the only two values present in the sample data).
- **Toolchain**: pinned `dbt-core`/`dbt-snowflake` to `1.11.x` in `DBT Code/pyproject.toml`. The `1.12.5`
  release pulled in a broken `metricflow` package (`ModuleNotFoundError` on
  `metricflow_semantic_interfaces...`) that breaks `dbt run`/`build` entirely — a known issue with that
  release, not anything in this project's models.

## Models built so far

| Layer | Model name | Grain | Status |
|---|---|---|---|
| Bronze | `bronze_hosts` | 1 row per host | Built |
| Bronze | `bronze_listings` | 1 row per listing | Built |
| Bronze | `bronze_bookings` | 1 row per booking | Built |
| Silver | `silver_hosts` | 1 row per host | Built |
| Silver | `silver_listings` | 1 row per listing, host attached | Built |
| Silver | `silver_bookings` | 1 row per booking, listing/host attached, `total_amount` computed | Built |
| Gold | `dim_hosts` | 1 row per host | Built |
| Gold | `dim_listings` | 1 row per listing | Built |
| Gold | `fct_bookings` | 1 row per booking | Built |

All 9 models + 32 data tests pass against the live `AIRBNB` database (`dbt build`), confirming the sample
data's host_id/listing_id referential integrity is intact (200 hosts, 500 listings, 5,000 bookings).
