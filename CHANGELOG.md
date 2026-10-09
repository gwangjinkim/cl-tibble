# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). See AGENTS.md
("Change Discipline") for how entries and commits are written.

## [Unreleased]

### Tests
- Replaced bare `(is t)` / `(is x)` assertions with `(pass)` /
  `(is-true x)`. Current FiveAM rejects a non-list argument to `IS` at
  macroexpansion time, so 8 error-path tests (duplicate columns, length
  mismatch, unknown column, slicing) errored instead of checking anything.
  Suite: 69/69 pass (was 60/68 with 8 errors).
