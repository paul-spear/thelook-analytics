-- Full extract: every product, with price changes applied up to @sim_date.
create or replace table `${project}.${raw}.products` as
select
  p.id,
  p.cost,
  p.category,
  p.name,
  p.brand,
  coalesce(o.retail_price, p.retail_price) as retail_price,
  p.department,
  p.sku,
  p.distribution_center_id,
  coalesce(timestamp(o.effective_date), timestamp '2019-01-01') as updated_at,
  @sim_date           as _sim_date,
  current_timestamp() as _loaded_at
from `${project}.${source}.products` as p
left join (
  select * from `${project}.${raw}._product_overrides`
  where effective_date <= @sim_date
  qualify row_number() over (partition by product_id order by effective_date desc) = 1
) as o on o.product_id = p.id;
