# ADR-001: Run dbt Core, not dbt Fusion, for this project

- **Status:** accepted
- **Date:** 2026-10-26
- **Phase:** 0

## Context

The project relies on `maximum_bytes_billed` in the dbt profile as the per-query cost
guardrail. The GCP project is on the free trial, which cannot edit BigQuery quotas or
set enforced spend caps, so the profile setting is the only hard per-query limit.

Phase 0 tested the guardrail by running a query larger than the cap:

| Engine | Cap | Query scanned | Result |
| --- | --- | --- | --- |
| dbt Fusion 2.0.8 (`dbt show`) | 5 GB | 13.7 GB | Ran and billed 13.74 GB |
| dbt Fusion 2.0.8 (`dbt show`) | 10 MB | 0.39 GB | Ran |
| `bq` CLI | 10 MB | 0.39 GB | Refused: `bytesBilledLimitExceeded` |
| dbt Core 1.12.6 + dbt-bigquery 1.12.1 | 10 MB | 0.39 GB | Refused: `bytesBilledLimitExceeded`, 0 bytes billed |

## Options considered

| Option | Pros | Cons |
| --- | --- | --- |
| dbt Fusion | Faster parsing, static SQL analysis, default for new installs | Ignored `maximum_bytes_billed` in testing; CI and laptop would need separate setup |
| dbt Core in `.venv` | Cap enforced; matches `requirements.txt` and CI; mature BigQuery adapter | Slower parse; Fusion-only features unavailable |

## Decision

Use dbt Core from the project virtualenv (`.venv`), pinned in `requirements.txt`, both
locally and in CI. Fusion stays installed system-wide but is not used for this project.

## Consequences

- Always activate the virtualenv (`source .venv/bin/activate`) or call `.venv/bin/dbt`;
  a bare `dbt` on this machine resolves to Fusion.
- Cost protection is now: per-query cap (dbt Core) + a monthly budget alert at £20
  (alerts only; the trial cannot enforce caps) + the free trial's own credit limit.
- Revisit when a Fusion release honours `maximum_bytes_billed` (re-run the 10 MB test),
  or when the project moves to a paid account where BigQuery quotas can be set.
