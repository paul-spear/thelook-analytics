# theLook Analytics

A production-style dbt project on Google BigQuery, built on the public
[theLook eCommerce](https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce)
dataset. It demonstrates SCD2 history, incremental MERGE models, a MetricFlow
semantic layer, and AI agents that query governed metrics.

> **Status:** under construction, built phase by phase. See [CHANGELOG.md](CHANGELOG.md)
> for what exists today.

## What it does

```
BigQuery public data
   -> change simulator (Python)        replays one day per run, mutates rows
   -> raw_thelook                      full extracts + append-only change logs
   -> staging (views)                  rename, cast, dedupe
   -> snapshots | incremental SCD2     history for users, products, order status
   -> marts (star schema)              dims + incremental facts
   -> semantic layer (MetricFlow)      metrics defined once
   -> AI agent (dbt MCP) / BI          ask for metrics by name, not SQL
```

| Layer | Folder | Materialisation | Layer meta |
| --- | --- | --- | --- |
| Staging | `models/staging/` | view | `landing` |
| Snapshots | `snapshots/` | snapshot (SCD2) | `normalised` |
| Intermediate | `models/intermediate/` | ephemeral / incremental | `logical` |
| Marts | `models/marts/` | table / incremental | `logical` |
| Semantic layer | `models/semantic/` | YAML only | n/a |

## Quickstart (about 10 minutes)

Prerequisites: Python 3.11+, a GCP project with billing and the BigQuery API enabled,
and the `gcloud` CLI.

```bash
git clone https://github.com/paul-spear/thelook-analytics.git
cd thelook-analytics
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pre-commit install

gcloud auth application-default login
mkdir -p ~/.dbt && cp profiles.yml.example ~/.dbt/profiles.yml   # then edit the placeholders
bq mk --location=US --dataset YOUR_GCP_PROJECT:raw_thelook

dbt deps
dbt debug
```

Daily run order (it matters):

```bash
python simulator/replay.py --days 1   # land one simulated day
dbt source freshness
dbt snapshot
dbt build
```

## Documentation

| Document | Read it when |
| --- | --- |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Before your first pull request |
| [docs/standards.md](docs/standards.md) | Adding or changing any model |
| [docs/adr/](docs/adr/) | You want to know why something is built the way it is |
| [docs/runbooks/](docs/runbooks/) | Something is broken or needs a backfill |
| [docs/glossary.md](docs/glossary.md) | A business term is unclear |

Model and column documentation lives in the dbt YAML files and is published with
`dbt docs generate`.

## Cost safety

Every target sets `maximum_bytes_billed` (5 GB per query in dev). Large facts are
partitioned and use `require_partition_filter`. Do not remove these.
