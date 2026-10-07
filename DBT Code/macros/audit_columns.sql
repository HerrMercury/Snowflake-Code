{% macro loaded_at_column(layer) -%}
    current_timestamp() as {{ layer }}_loaded_at
{%- endmacro %}
