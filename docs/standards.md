# Data standards

These standards keep the project understandable to someone who has never seen it.
They are enforced in CI wherever possible: a PR that breaks one fails, like a failing test.
The approach follows what Monzo has published about running 12,000+ dbt models across
100+ teams ([A meshy approach to data](https://monzo.com/blog/a-meshy-approach-to-data)).

## Layers

| Layer (`meta.layer`) | Folders | Purpose | Can be an interface? |
| --- | --- | --- | --- |
| `landing` | `models/staging/` | One model per source table. Rename, cast, dedupe. No joins. | No |
| `normalised` | `snapshots/`, SCD2 models | One entity's history or lifecycle. | Yes |
| `logical` | `models/intermediate/`, `models/marts/` | Business logic; dims and facts. | Yes |
| `presentation` | `rpt_*`, exports | Shaped for one consumer. Leaf nodes. | No |

**Interface models** are the contract others build on: `meta.interface: true`,
`access: public`, `contract: {enforced: true}`, fully documented and tested.
Only build downstream work on interfaces.

## Naming

| Prefix | Meaning | Example |
| --- | --- | --- |
| `stg_<source>__<entity>` | Staging | `stg_thelook__users` |
| `snap_<entity>` | Snapshot | `snap_users` |
| `int_<entity>_<verb>` | Intermediate | `int_order_status_history` |
| `dim_<entity>` | Dimension | `dim_customers` |
| `fct_<event>` | Fact | `fct_order_items` |
| `rpt_<topic>` | Presentation | `rpt_revenue_by_state` |

Columns: `_id` natural keys, `_sk` surrogate keys, `_at` timestamps (UTC), `_date` dates,
`is_` / `has_` booleans, money in `NUMERIC` with the currency in the description.

## Rules enforced in CI

| Rule | Why |
| --- | --- |
| Every model has `meta.owner`, `meta.layer`, `meta.grain` | Someone is accountable, and readers know what one row means. |
| Every model and column has a description | Undocumented data gets misused, by people and by AI agents. |
| Every model has a uniqueness test on its unique key | Duplicate rows are the most common silent bug. |
| Every source has freshness configured | Stale data should alert, not be discovered in a meeting. |
| Facts and large models are incremental | Full rebuilds of large tables waste money and time. |
| Tables above 1 GB declare `partition_by` | Partition pruning is the main BigQuery cost control. |
| Exemptions declare a `reason` | Exceptions are fine; silent exceptions are not. |

## Writing descriptions

- First sentence states the grain: "One row per customer version (SCD2)."
- Explain how to use it correctly and what goes wrong otherwise.
- Units and currency on every measure. Time zone on every timestamp.
- Shared columns (`_loaded_at`, `valid_from`, `valid_to`, `is_current`) use the doc
  blocks in `models/docs/_shared.md`.
- A description that only repeats the column name fails review.

## Model YAML template

```yaml
models:
  - name: dim_customers
    description: >
      One row per customer version (SCD2). A new version is created when email or
      address changes. Use `is_current` for today's view; join on
      `valid_from <= event_at < valid_to` for the view at event time.
    config:
      access: public
      contract: {enforced: true}
      meta:
        owner: analytics-engineering
        layer: logical
        interface: true
        grain: "user_id x valid_from"
        unique_key: customer_sk
        pii: [email, street_address]
        standards_exempt: []
    columns:
      - name: customer_sk
        description: Surrogate key for this version. Equal to `dbt_scd_id` from `snap_users`.
        data_tests: [unique, not_null]
      - name: valid_from
        description: '{{ doc("scd2_valid_from") }}'
```
