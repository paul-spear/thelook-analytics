# Architecture Decision Records

One file per significant decision, numbered in order. Copy `000-template.md`.

| ADR | Decision | Status |
| --- | --- | --- |
| [001](001-dbt-core-over-fusion.md) | Run dbt Core, not Fusion, so the per-query byte cap is enforced (Phase 0) | accepted |
| 002 | Snapshots vs hand-built SCD2, per table (Phase 3) | to write |
| 003 | merge vs insert_overwrite vs microbatch, per fact (Phase 4) | to write |
| 004 | Where the simulator and daily pipeline run (Phase 9) | to write |
| 005 | Contested metric definitions (Phase 7) | to write |
