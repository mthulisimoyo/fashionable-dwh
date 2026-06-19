{% macro is_valid_sale(status_col, amount_col)%}
    {{ status_col }} like 'Shipped%' AND {{ amount_col }} is not null
{% endmacro %}  