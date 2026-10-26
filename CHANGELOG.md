# Changelog

All notable changes to this project are recorded here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions follow the build phases.

## [Unreleased]

### Added
- Repository scaffold: dbt project config, packages, profile example, CI (lint), pre-commit,
  GitHub templates, documentation standard, ADR template, runbook index, glossary.
- `package-lock.yml` so every environment installs the same package versions.
- ADR-001: run dbt Core rather than Fusion, so the per-query byte cap is enforced.

### Fixed
- `query-comment` in `dbt_project.yml` called a macro that does not exist; it now only
  sets `job-label: true`.
- README quickstart no longer overwrites an existing `~/.dbt/profiles.yml`.
