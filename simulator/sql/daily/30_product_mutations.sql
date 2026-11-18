-- Mutate a small, deterministic sample of products on @sim_date:
--   price changes: ~20 in 10,000 products get a new retail_price, -10% to +15%
-- The same @sim_date always picks the same products and the same new prices.
delete from `${project}.${raw}._product_overrides` where effective_date >= @sim_date;


insert into `${project}.${raw}._product_overrides`
with current_products as (
  -- Each existing product's attributes as of the previous day: base data plus latest override.
  select
    p.id as product_id,
    coalesce(o.retail_price, p.retail_price) as retail_price
  from `${project}.${source}.products` as p
  left join (
    select * from `${project}.${raw}._product_overrides`
    qualify row_number() over (partition by product_id order by effective_date desc) = 1
  ) as o on o.product_id = p.id
),

flagged as (
  select
    product_id,
    retail_price,
    mod(abs(farm_fingerprint(format('%d|%t|price', product_id, @sim_date))), 10000) < 20
      as is_changed,
    mod(abs(farm_fingerprint(format('%d|%t|pct', product_id, @sim_date))), 2501) / 10000 - 0.10
      as pct_change
  from        current_products
)


select
  product_id,
  @sim_date as effective_date,
  round(retail_price * (1 + pct_change), 2) as retail_price,
  case when pct_change > 0 then 'price_up' else 'price_down' end as change_type
from flagged
where is_changed and pct_change != 0;
