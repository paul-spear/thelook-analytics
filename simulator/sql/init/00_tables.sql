-- Landing tables and simulator bookkeeping. Safe to rerun: nothing is dropped.
-- ${project}, ${source} and ${raw} are filled in by replay.py.

-- One row: the last simulated day that finished loading.
create table if not exists `${project}.${raw}._sim_state` (
  sim_date date not null,
  updated_at timestamp not null
);

-- Append-only change log: one row per order status change, on the day it happened.
create table if not exists `${project}.${raw}.orders_changes` (
  order_id int64,
  user_id int64,
  gender string,
  num_of_item int64,
  created_at timestamp,
  status string,
  updated_at timestamp,      -- when this status took effect (business time)
  _sim_date date,            -- simulated day this row was loaded on
  _loaded_at timestamp       -- wall-clock time of the load
)
partition by _sim_date
cluster by order_id;

-- Simulated dates are months in the past, so any partition expiry inherited from the
-- dataset (the BigQuery sandbox sets 60 days) would delete rows the moment they land.
alter table `${project}.${raw}.orders_changes` set options (partition_expiration_days = null);

-- Append-only change log: one row per order item status change, on the day it happened.
create table if not exists `${project}.${raw}.order_items_changes` (
  id int64,
  order_id int64,
  user_id int64,
  product_id int64,
  inventory_item_id int64,
  sale_price float64,
  created_at timestamp,
  status string,
  updated_at timestamp,
  _sim_date date,
  _loaded_at timestamp
)
partition by _sim_date
cluster by order_id;

-- Simulated dates are months in the past, so any partition expiry inherited from the
-- dataset (the BigQuery sandbox sets 60 days) would delete rows the moment they land.
alter table `${project}.${raw}.order_items_changes` set options (partition_expiration_days = null);

-- Accumulated user mutations. Each row holds the full set of mutable attributes
-- as of effective_date, so the latest row per user is that user's current state.
create table if not exists `${project}.${raw}._user_overrides` (
  user_id int64,
  effective_date date,
  email string,
  street_address string,
  city string,
  state string,
  postal_code string,
  country string,
  change_type string         -- 'move', 'email' or 'move+email'
);

-- Accumulated product mutations.
-- The latest row per product is its current price
create table if not exists `${project}.${raw}._product_overrides` (
  product_id int64,
  effective_date date,
  retail_price float64,
  change_type string         -- 'price_up' or 'price_down'
);
