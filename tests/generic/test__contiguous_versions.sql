{% test fashionable__contiguous_versions(model, key, valid_from='valid_from', valid_to='valid_to') %}

{%- set key_cols = [key] if key is string else key -%}
{%- set partition_by = key_cols | join(', ') -%}

with contiguous as (

    select
        {{ partition_by }},
        {{ valid_from }} as valid_from,
        {{ valid_to }} as valid_to,
        lead({{ valid_from }}) over (partition by {{ partition_by }} order by {{ valid_from }}) as next_valid_from

    from {{ model }}

)
select *
from contiguous
where next_valid_from is not null
and next_valid_from != valid_to

{% endtest %}