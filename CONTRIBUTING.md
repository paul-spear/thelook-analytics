# Contributing

## Workflow

1. Open (or pick) an issue. Each build phase has one.
2. Branch from `main`: `phase-3/scd2-snapshots`, `fix/dedupe-order-items`.
3. Commit with [Conventional Commits](https://www.conventionalcommits.org/):
   `feat(marts): add dim_customers scd2`, `fix(staging): dedupe order items`,
   `docs(adr): record merge vs microbatch`.
4. Open a pull request using the template. Link the issue with `Closes #<n>`.
5. CI must pass. PRs are squash-merged.
6. At the end of each phase, tag a release (`v0.3.0`) and move "Unreleased" in
   `CHANGELOG.md` under that version.

## Adding a model

1. Put it in the right layer folder and name it by the conventions in
   [docs/standards.md](docs/standards.md).
2. Add YAML in the same folder with, at minimum:
   - a description whose first sentence states the grain ("One row per ...")
   - `meta`: `owner`, `layer`, `grain`
   - a description for every column
   - a uniqueness test on the unique key
3. Run `dbt build -s <model>+` locally.
4. If the model cannot meet a standard, declare an exemption (below).

## Requesting a standards exemption

Exemptions are allowed, but must be explicit and justified:

```yaml
config:
  meta:
    standards_exempt:
      - rule: incremental
        reason: "Under 10k rows; a full rebuild costs less than the merge."
```

An exemption without a `reason` fails CI.

## Architecture decisions

Any choice a future reader might question gets an ADR: copy
[docs/adr/000-template.md](docs/adr/000-template.md) to the next number.
