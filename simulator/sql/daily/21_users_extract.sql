-- Full extract: every user created up to the end of @sim_date, with mutations applied.
-- Replaced on every run, the way a nightly export from a source system would be.
create or replace table `${project}.${raw}.users` as
select
  u.id,
  u.first_name,
  u.last_name,
  coalesce(o.email, u.email)                   as email,
  u.age,
  u.gender,
  coalesce(o.state, u.state)                   as state,
  coalesce(o.street_address, u.street_address) as street_address,
  coalesce(o.postal_code, u.postal_code)       as postal_code,
  coalesce(o.city, u.city)                     as city,
  coalesce(o.country, u.country)               as country,
  u.latitude,                                  -- not updated on a move: a known source quirk
  u.longitude,
  u.traffic_source,
  u.created_at,
  @sim_date                                    as _sim_date,
  current_timestamp()                          as _loaded_at
from `${project}.${source}.users` as u
left join (
  select * from `${project}.${raw}._user_overrides`
  where effective_date <= @sim_date
  qualify row_number() over (partition by user_id order by effective_date desc) = 1
) as o on o.user_id = u.id
where date(u.created_at) <= @sim_date;
