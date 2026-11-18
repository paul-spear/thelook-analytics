-- Change log for one simulated day: status changes that happened on @sim_date.
-- Delete-then-insert makes the day idempotent; ">=" also clears later days after a rewind.
delete from `${project}.${raw}.orders_changes` where _sim_date >= @sim_date;

insert into `${project}.${raw}.orders_changes`
select
  o.order_id, o.user_id, o.gender, o.num_of_item, o.created_at,
  e.status,
  e.event_ts          as updated_at,
  @sim_date           as _sim_date,
  current_timestamp() as _loaded_at
from `${project}.${source}.orders` as o,
unnest([
  struct('Processing' as status, o.created_at as event_ts),
  struct('Shipped',  o.shipped_at),
  struct('Complete', o.delivered_at),
  struct('Returned', o.returned_at)
]) as e
where date(e.event_ts) = @sim_date;
