-- One-off history load: every event before the simulation start.
-- Rows are stamped as loaded on the day before @start_date.
delete from `${project}.${raw}.events` where _sim_date < @start_date;

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
  date_sub(@start_date, interval 1 day) as _sim_date,
  current_timestamp()                as _loaded_at
from `${project}.${source}.events` as ev
where date(ev.created_at) < @start_date;
