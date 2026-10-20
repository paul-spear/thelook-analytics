## What changed

<!-- One or two sentences. Link the phase issue: Closes #<n> -->

## Why

## Models affected

<!-- e.g. `dim_customers` (new), `fct_orders` (column added). Mark interface models. -->

## How it was tested

- [ ] `dbt build -s state:modified+` passes locally
- [ ] Incremental models: result after incremental runs matches a `--full-refresh`
- [ ] SCD2 models: no overlapping or gapped validity windows; one current row per key

## Documentation

- [ ] Every new or changed model has `owner`, `layer` and `grain` in `meta`
- [ ] Every column has a description that says more than its name
- [ ] Any standards exemption is declared in `meta.standards_exempt` with a reason
- [ ] ADR added for a significant design decision (`docs/adr/`)
- [ ] `CHANGELOG.md` updated under "Unreleased"
