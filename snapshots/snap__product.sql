{% snapshot snap__product %}

{{
    config(
        target_schema='snapshots',
        unique_key='sku',
        strategy='check',
        check_cols=['asin', 'style', 'product_category', 'product_size'],
        invalidate_hard_deletes=True
    )
}}

select distinct on (sku)
        sku,
        style,
        asin,
        product_category,
        product_size
from {{ ref('stg__sales_report') }}
order by sku, source_id desc

{% endsnapshot %}