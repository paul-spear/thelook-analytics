-- One-off history load: every order item status change before the simulation start.
-- Rows are stamped as loaded on the day before @start_date.
delete from `${project}.${raw}.order_items_changes` where _sim_date < @start_date;

insert into `${project}.${raw}.order_items_changes`
select
  oi.id,
  oi.order_id,
  oi.user_id,
  oi.product_id,
  oi.inventory_item_id,
  oi.sale_price,
  oi.created_at,
  e.status,
  e.event_ts                         as updated_at,
  date_sub(@start_date, interval 1 day) as _sim_date,
  current_timestamp()                as _loaded_at
from `${project}.${source}.order_items` as oi,
unnest([
  struct('Processing' as status, oi.created_at as event_ts),
  struct('Shipped',  oi.shipped_at),
  struct('Complete', oi.delivered_at),
  struct('Returned', oi.returned_at)
]) as e
where date(e.event_ts) < @start_date;
