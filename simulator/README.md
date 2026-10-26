# Change simulator

Replays theLook into `raw_thelook` one simulated day per run, mutating rows so SCD2 and
incremental logic downstream are exercised. Built in Phase 1 of the guide.

## Usage

```bash
export GCP_PROJECT=thelook-analytics-512220
.venv/bin/python simulator/replay.py init --start 2026-06-01   # once: tables + history
.venv/bin/python simulator/replay.py run --days 3              # land the next 3 days
.venv/bin/python simulator/replay.py status                    # show the simulated clock
```

## How it works

| Piece | What it does |
| --- | --- |
| `thelook_source` dataset | Frozen copy of `bigquery-public-data.thelook_ecommerce`, taken 2026-10-26. The public dataset is regenerated daily (rows appear and disappear), so the simulator only ever reads this copy. |
| `_sim_state` | One row: the last simulated day that finished. Advanced only after every daily file succeeds. |
| `sql/init/*.sql` | Run once by `init`, in file order: create tables, load history before `--start` (stamped `_sim_date` = the day before). |
| `sql/daily/*.sql` | Run for each simulated day, in file order, with `@sim_date`. |
| Horizon | Replay stops at the day before the frozen copy was taken (2026-10-25). |

Every daily file is **idempotent**: it deletes rows for `@sim_date` and later, then inserts.
Rerunning a day, or rewinding `_sim_state` and replaying, gives identical results
(verified: same row count and fingerprint for 2026-06-03 after a rewind and replay).

Two time columns on every landed row:

- `_sim_date`: the simulated day the row was loaded on. Use it for business-time logic.
- `_loaded_at`: wall-clock load time. Use it for incremental filters and freshness only.

## Raw tables

| Table | Pattern | Status |
| --- | --- | --- |
| `orders_changes` | Append-only change log, one row per status change, partitioned by `_sim_date` | Built |
| `users` | Full extract, replaced each run; moves and email changes applied from `_user_overrides` | Built |
| `products` | Full extract with price changes and an `updated_at` column | To build |
| `order_items_changes` | Change log with late and duplicate rows | To build |
| `events` | Append-only, partitioned by day | To build |

## Mutations

Chosen with `farm_fingerprint(id | sim_date | purpose)`, so the same day always picks the
same rows. Current rates per day, out of users existing before that day:

| Mutation | Rate | New value |
| --- | --- | --- |
| Move | 5 in 10,000 | Address of another user, shuffled deterministically |
| Email change | 2 in 10,000 | `local+YYMMDD@domain` |

Known quirks, deliberately left in: a move keeps the old `latitude`/`longitude`, and a
donor address can be in another country.

## Gotcha: inherited partition expiry

The project started in the BigQuery sandbox, which sets a 60-day default **partition**
expiry on datasets. Simulated dates are months old, so partitions inherited that expiry and
were deleted on write, silently. `raw_thelook` no longer has the default, and
`sql/init/00_tables.sql` clears it explicitly on each partitioned table. Do the same for any
new partitioned raw table.
