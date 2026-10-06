{% macro generate_schema_name(custom_schema_name, node) -%}
    {#-
        BRONZE / SILVER / GOLD already exist as fixed schemas in AIRBNB.
        Route a model straight to its custom schema (uppercased) instead of
        dbt's default behavior of appending it to the target schema
        (e.g. dbt_schema_bronze). Models with no custom schema config
        (e.g. one-off analyses) fall back to the target/profile schema.
    -#}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim | upper }}
    {%- endif -%}
{%- endmacro %}
