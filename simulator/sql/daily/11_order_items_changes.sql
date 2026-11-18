-- Change log for one simulated day: order items status changes that happened on @sim_date.
-- Delete-then-insert makes the day idempotent; ">=" also clears later days after a rewind.
delete from `${project}.${raw}.order_items_changes`
where _sim_date >= @sim_date;

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
  e.event_ts as updated_at,
  @sim_date as _sim_date,
  current_timestamp() as _loaded_at
from `${project}.${source}.order_items` as oi,
  unnest([
    struct('Processing' as status, oi.created_at as event_ts),
    struct('Shipped', oi.shipped_at),
    struct('Complete', oi.delivered_at),
    struct('Returned', oi.returned_at)
  ]) as e
where date(e.event_ts) = @sim_date;
