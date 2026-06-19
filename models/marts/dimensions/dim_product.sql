with product_versions as (

    select 
        sku,
        style,
        asin,
        product_category,
        product_size,
        cast(dbt_valid_from as date) as version_valid_from,
        cast(dbt_valid_to as date) as version_valid_to,
        row_number() over (partition by sku order by dbt_valid_from) = 1 as is_first_version
    from {{ ref('snap__product') }}
)

    select 
        {{ dbt_utils.generate_surrogate_key(['sku', 'version_valid_from']) }} as product_key,
        {{ dbt_utils.generate_surrogate_key(['sku']) }} as product_natural_key,
        sku,
        style,
        asin,
        product_category,
        product_size,
        case when is_first_version then cast('1900-01-01' as date) else version_valid_from end as valid_from,
        coalesce(version_valid_to, cast('9999-12-31' as date)) as valid_to,
        version_valid_to is null as is_current
    from product_versions


