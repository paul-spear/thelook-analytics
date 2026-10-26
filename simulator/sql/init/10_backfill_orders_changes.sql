-- One-off history load: every order status change before the simulation start.
-- Rows are stamped as loaded on the day before @start_date.
delete from `${project}.${raw}.orders_changes` where _sim_date < @start_date;

insert into `${project}.${raw}.orders_changes`
select
  o.order_id, o.user_id, o.gender, o.num_of_item, o.created_at,
  e.status,
  e.event_ts                         as updated_at,
  date_sub(@start_date, interval 1 day) as _sim_date,
  current_timestamp()                as _loaded_at
from `${project}.${source}.orders` as o,
unnest([
  struct('Processing' as status, o.created_at as event_ts),
  struct('Shipped',  o.shipped_at),
  struct('Complete', o.delivered_at),
  struct('Returned', o.returned_at)
]) as e
where date(e.event_ts) < @start_date;
-- Challenge (Phase 1): Cancelled orders have no timestamps, so they never appear here.
-- Invent a deterministic cancellation time and add a 'Cancelled' struct.
