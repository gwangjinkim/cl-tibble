# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). See AGENTS.md
("Change Discipline") for how entries and commits are written.

## [Unreleased]

### Fixed
- `parity-TB1`: Core slicing/printing/row iteration retain duplicate columns.
  Unique names still read the public hash after mutation; missing slice
  columns retain UNKNOWN-COLUMN-ERROR. Proper-list alist columns retain
  their legacy row count. Typed scalar NA, FALSE/explicit NULL and computed
  NULL omission have regression coverage. Nested matrix/frame owners are
  rejected clearly; default migrations and scientific formatting stay partial.
- `row-binding-na`: missing columns now contain the shared NA singleton
  instead of logical FALSE, restoring the existing C1 missing-value contract.

### Added
- `parity-TB1`: Add eight constructor/coercion/predicate APIs, sequential
  computed columns and lexical syntax, explicit constructor controls,
  four name-repair strategies, duplicate-name positional storage and
  unchecked row-count/attribute construction. Callable TIBBLE and the
  one-argument AS-TIBBLE extension generic remain available.
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
- `parity-TB1`: Package checks increase from 81 to 182, all passing;
  125 new active pinned-R cases bring tibble to 133. Eight genuine partial
  proofs are archived separately; adapter projections do not grant full
  function credit. Concrete compatibility regressions failed before repair.
- `row-binding-na`: fill assertions check NA instead of FALSE; isolated
  pre-X2 owner suite passes 69 checks, final X2 suite passes 81.
- `parity-X2`: 12 new prototype/printing/binding checks; 81 package checks
  pass, with additional factor/date/list regressions in cl-tidystat.
- Replaced bare `(is t)` / `(is x)` assertions with `(pass)` /
  `(is-true x)`. Current FiveAM rejects a non-list argument to `IS` at
  macroexpansion time, so 8 error-path tests (duplicate columns, length
  mismatch, unknown column, slicing) errored instead of checking anything.
  Suite: 69/69 pass (was 60/68 with 8 errors).
