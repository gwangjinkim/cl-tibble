# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). See AGENTS.md
("Change Discipline") for how entries and commits are written.

## [Unreleased]

### Changed
- Stopped tracking `build/` (48 files, 1.0M): the ASDF/Roswell compile
  cache that `make test` writes via `XDG_CACHE_HOME=$(PWD)/build`. It held
  compiled fasls, including Quicklisp internals and absolute local paths.
  `build/` is now in `.gitignore`; local files are untouched. Old copies
  remain in history (topic: repo hygiene).

### Tests
- Replaced bare `(is t)` / `(is x)` assertions with `(pass)` /
  `(is-true x)`. Current FiveAM rejects a non-list argument to `IS` at
  macroexpansion time, so 8 error-path tests (duplicate columns, length
  mismatch, unknown column, slicing) errored instead of checking anything.
  Suite: 69/69 pass (was 60/68 with 8 errors).
