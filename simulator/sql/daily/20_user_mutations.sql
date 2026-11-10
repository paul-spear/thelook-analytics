-- Mutate a small, deterministic sample of users on @sim_date:
--   moves:         ~5 in 10,000 users get a new address, borrowed from another user
--   email changes: ~2 in 10,000 users get a new email
-- The same @sim_date always picks the same users and the same new values.
delete from `${project}.${raw}._user_overrides` where effective_date >= @sim_date;

insert into `${project}.${raw}._user_overrides`
with current_users as (
  -- Each existing user's attributes as of the previous day: base data plus latest override.
  select
    u.id as user_id,
    coalesce(o.email, u.email)                   as email,
    coalesce(o.street_address, u.street_address) as street_address,
    coalesce(o.city, u.city)                     as city,
    coalesce(o.state, u.state)                   as state,
    coalesce(o.postal_code, u.postal_code)       as postal_code,
    coalesce(o.country, u.country)               as country
  from `${project}.${source}.users` as u
  left join (
    select * from `${project}.${raw}._user_overrides`
    qualify row_number() over (partition by user_id order by effective_date desc) = 1
  ) as o on o.user_id = u.id
  where date(u.created_at) < @sim_date
),

flagged as (
  select
    *,
    mod(abs(farm_fingerprint(format('%d|%t|move',  user_id, @sim_date))), 10000) < 5 as is_move,
    mod(abs(farm_fingerprint(format('%d|%t|email', user_id, @sim_date))), 10000) < 2 as is_email
  from current_users
),

movers as (
  select
    user_id,
    row_number() over (order by farm_fingerprint(format('%d|%t|mover', user_id, @sim_date))) as rn
  from flagged
  where is_move
),

donor_addresses as (
  -- Real address combinations from other users, shuffled deterministically.
  select
    street_address, city, state, postal_code, country,
    row_number() over (order by farm_fingerprint(format('%d|%t|donor', id, @sim_date))) as rn
  from `${project}.${source}.users`
)

select
  f.user_id,
  @sim_date as effective_date,
  if(f.is_email,
     format('%s+%s@%s',
            split(f.email, '@')[safe_offset(0)],
            format_date('%y%m%d', @sim_date),
            split(f.email, '@')[safe_offset(1)]),
     f.email)                                         as email,
  if(f.is_move, d.street_address, f.street_address)  as street_address,
  if(f.is_move, d.city,           f.city)            as city,
  if(f.is_move, d.state,          f.state)           as state,
  if(f.is_move, d.postal_code,    f.postal_code)     as postal_code,
  if(f.is_move, d.country,        f.country)         as country,
  case when f.is_move and f.is_email then 'move+email'
       when f.is_move then 'move'
       else 'email' end                               as change_type
from flagged as f
left join movers as m on m.user_id = f.user_id
left join donor_addresses as d on d.rn = m.rn
where f.is_move or f.is_email;
