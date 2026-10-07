# DBT Code

dbt project implementing the Bronze/Silver/Gold medallion architecture for the `AIRBNB`
database in Snowflake. See [`docs/architecture.md`](../docs/architecture.md) for the design
discussion and decisions log.

## Layout

```
models/
  bronze/   tables, light-cleaned 1:1 copies of the AIRBNB.STAGING source tables
  silver/   tables, joined/conformed business entities (host attached to listing, etc.)
  gold/     tables, dimensional model (dim_hosts, dim_listings, fct_bookings)
macros/
  generate_schema_name.sql   routes models to BRONZE/SILVER/GOLD exactly (no schema prefix)
  audit_columns.sql          loaded_at_column(layer) macro, used by every model
```

Every model is `materialized='table'` (full rebuild each run) except the bookings pipeline
(`bronze_bookings` → `silver_bookings` → `fct_bookings`), which is `materialized='incremental'`
keyed on `booking_id` — re-runs only pick up rows with a newer `created_at` than what's already
in the table. Run `dbt run --full-refresh` to force those three back to a full rebuild.

## Setup

Dependencies are managed with `uv` (see `pyproject.toml`). Connection profile lives at
`~/.dbt/profiles.yml` under the `Snowflake_Code` profile, target `dev`.

```bash
uv sync
```

> If you're on OneDrive/another sync-locked folder and `uv` fails with a hardlink error,
> set `UV_LINK_MODE=copy` (e.g. `export UV_LINK_MODE=copy` or prefix the command).

## Running

```bash
uv run dbt debug   # verify connection
uv run dbt build   # run all models + tests
uv run dbt run     # models only
uv run dbt test    # tests only
uv run dbt docs generate && uv run dbt docs serve   # browsable docs/lineage graph
```

## Notes

- `dbt-core`/`dbt-snowflake` are pinned to `1.11.x`. The `1.12.5` release has a broken
  `metricflow` dependency that throws `ModuleNotFoundError` on `dbt run`/`build` — unrelated
  to this project, just avoid upgrading past `1.11.x` until that's fixed upstream.
- `relationships` and `accepted_values` tests are set to `severity: warn` rather than `error`,
  since the sample data's referential integrity isn't a hard guarantee going forward.
