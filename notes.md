##EDA Notes
1. Grain Analysis - a single row represents an order line (i.e. order id + stock keeping unit (sku) ) placed
by a customer. Every measure can rollup at this grain. Rolling up the grain to Order Id would result in loss of info
The intention is to answer *what* sells, *where*, *when* and *through which chanel*


Why:
- index is likely an operational system PK and has no business meaning. It is 1:1 with # of rows
- Order ID has 120k rows out of 124k rows. A single order can have multiple lines (multiple ordered units - sku)
- Order ID + SKU is unique except for 7 pairs of records e.g. 407-4853873-4978725 + J0230-SKD-M most likely dups since everything else except key are the same

Fact table grain will be on order line - will add *test for this*

2. Measures:
- Qty = int
- Amount - amount is decimal except for cancelled orders where its NULL

3. Dimensions
- Product Dimension (dim_product) - sku, style, category, size, asin
- Address Dimension (dim_address) - ship-city, ship-state, ship-postal-code, ship-country
- Calendar (dim_calendar)
- Order ID - # degenerate on fact
- Fulfilment Dimension (dim_fulfilment) - status, courier status, fulfilment, ship-service-level, fulfilled-by

4. Surrogate Keys
Every dimension has a hashed SK instead of relying on natural keys to:
- decouple from volatile source keys
- derive composite keys - which are join friendly e.g customer_key
- conformance - the same sk is derived in the intermediate layer guaranteeing referential integrity

5. DQ Approach
Shift left - most tests are done at closest to the source so that issues are identified early
Test groups used are:
 - Keys: not_null + unique
 - Referential: relationships to fact_sales
 - Domain: accepted_values: status, category, channel
 - Conformity: postal code, number of rows (to ensure no row loss or fan outs)