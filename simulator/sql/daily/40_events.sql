-- Append-only: every event that happened on @sim_date.
-- Delete-then-insert makes the day idempotent; ">=" also clears later days after a rewind.
delete from `${project}.${raw}.events`
where _sim_date >= @sim_date;

insert into `${project}.${raw}.events`
select
  ev.id,
  ev.user_id,
  ev.sequence_number,
  ev.session_id,
  ev.created_at,
  ev.ip_address,
  ev.city,
  ev.state,
  ev.postal_code,
  ev.browser,
  ev.traffic_source,
  ev.uri,
  ev.event_type,
  @sim_date as _sim_date,
  current_timestamp() as _loaded_at
from `${project}.${source}.events` as ev
where date(ev.created_at) = @sim_date;
