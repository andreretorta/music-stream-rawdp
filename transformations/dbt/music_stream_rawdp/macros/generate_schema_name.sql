-- Overwrites the default dbt schema-naming behaviour so that the custom schema
-- name is used as-is (instead of being concatenated with the target schema).

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- else -%}

        {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
