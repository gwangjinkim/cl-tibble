# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). See AGENTS.md
("Change Discipline") for how entries and commits are written.

## [Unreleased]

### Fixed
- `row-binding-na`: missing columns now contain the shared NA singleton
  instead of logical FALSE, restoring the existing C1 missing-value contract.

### Added
- `parity-X2`: print Date, datetime, time, Duration, factor and list-column
  abbreviations from the shared prototype, including empty/all-NA columns.

### Changed
- `parity-X2`: construction, slicing and row binding preserve prototypes
  and factor levels through the shared column protocol. Strings recycle as
  scalar character cells; existing Lisp lists remain scalar cells.
- AGENTS.md: "Parity work" section listing this repository's parity
  milestones (X3, TB1, TB2, TB3, TB4) and where the plan and backlog live
  (topic: parity plan).
- Stopped tracking `build/` (48 files, 1.0M): the ASDF/Roswell compile
  cache that `make test` writes via `XDG_CACHE_HOME=$(PWD)/build`. It held
  compiled fasls, including Quicklisp internals and absolute local paths.
  `build/` is now in `.gitignore`; local files are untouched. Old copies
  remain in history (topic: repo hygiene).

### Tests
- `row-binding-na`: fill assertions check NA instead of FALSE; isolated
  pre-X2 owner suite passes 69 checks, final X2 suite passes 81.
- `parity-X2`: 12 new prototype/printing/binding checks; 81 package checks
  pass, with additional factor/date/list regressions in cl-tidystat.
- Replaced bare `(is t)` / `(is x)` assertions with `(pass)` /
  `(is-true x)`. Current FiveAM rejects a non-list argument to `IS` at
  macroexpansion time, so 8 error-path tests (duplicate columns, length
  mismatch, unknown column, slicing) errored instead of checking anything.
  Suite: 69/69 pass (was 60/68 with 8 errors).
