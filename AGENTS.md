# AGENTS.md — cl-tibble

**Purpose**: A strict, modern data frame implementation for Common Lisp, modeled on R's `tibble`.

**Agents**: treat this file as the source of truth. Implement milestone by milestone with tests-first.

## 0) Non-negotiable workflow match
- [ ] Maintain strict alignment with `cl-vctrs-lite`.
- [ ] Use `FiveAM` for testing.
- [ ] `make test` must always pass.

## 1) Repo Structure
- `cl-tibble/`
    - `cl-tibble.asd`
    - `README.md`
    - `SPEC.md` (The design doc)
    - `src/`
        - `package.lisp`
        - `conditions.lisp`
        - `tbl.lisp`         ; The core struct
        - `construct.lisp`   ; tibble(), as-tibble(), tribble
        - `access.lisp`      ; ref/set variants
        - `print.lisp`       ; Pretty printing
        - `bind.lisp`        ; bind-rows/cols
        - `dsl.lisp`         ; Lispy sugar (macros)
    - `test/`
        - `package.lisp`
        - `suite.lisp`
        - `tbl-tests.lisp`
        - `construct-tests.lisp`
        - `access-tests.lisp`
        - `print-tests.lisp`
        - `bind-tests.lisp`
        - `dsl-tests.lisp`

### Dependencies
- `:cl-tibble` depends on `:cl-vctrs-lite`.
- `:cl-tibble/test` depends on `:cl-tibble` and `:fiveam`.

## 2) Milestones

### M0 — Scaffold
**Deliverables**
- [ ] ASDF system definition.
- [ ] `src/package.lisp` (export `tbl` etc.).
- [ ] `test/` setup with `make test`.
- [ ] Tests: Trivial (`is t`) pass.

### M1 — The Core Struct (tbl)
**Implement**
- [ ] `src/tbl.lisp`: Define the struct/class. storage for columns (order + data).
- [ ] Validations:
    - [ ] All cols same length.
    - [ ] Names unique.
**Tests**
- [ ] Create manual low-level `tbl`.
- [ ] Error on mismatch lengths.

### M2 — Constructors
**Implement**
- [ ] `tibble(&rest kv)`: High-level constructor.
    - [ ] Handles recycling (scalar -> n).
    - [ ] Handles `vec-c` logic if needed (though tibble constructs columns, not concatenates them usually).
    - [ ] Support keyword args as column names.
- [ ] `as-tibble`: From alist/plist/vectors.
- [ ] `enframe(x)` / `deframe(x)`: Interop with vectors/lists.
- [ ] `tribble`: Row-wise construction.
**Tests**
- [ ] `(tibble "x" 1 "y" 2)` -> 1x2 tibble.
- [ ] `(tibble "x" #(1 2) "y" 1)` -> 2x2 tibble (recycling).

### M3 — Accessors
**Implement**
- [ ] `tbl-col`: Get column by name.
- [ ] `tbl-ref`: Get cell.
- [ ] `[:`: Subset/slice.
- [ ] Out of bounds / missing column checks.
**Tests**
- [ ] Get column by name.
- [ ] Subset preserves class.

### M4 — Printing (The "Pretty" Part)
**Implement**
- [ ] `print-object`: Header, type tags (from `cl-vctrs-lite`), truncation.
- [ ] `glimpse`: Dense summary view.
**Tests**
- [ ] Gold file testing for printed output.

### M5 — Bind
**Implement**
- [ ] `bind-rows`: Vertical concat.
- [ ] `bind-cols`: Horizontal concat.
**Tests**
- [ ] Combine two tibbles.
- [ ] Bind with missing columns (fill NA).

### M6 — Lispy DSL
**Implement**
- [ ] `with-tibble`: Context macro exposing columns as variables.
- [ ] `chain` (or `->`): Threading macro.
- [ ] `row-map`, `col-map`: Functional interactors.
**Tests**
- [ ] `(with-tibble (df) ...)` works as expected.

## 3) Coding style
- Use `cl-vctrs-lite` prefixes/idioms.
- Error messages: "tibble: ..."

## Change Discipline (git + documentation)

Every change to this repository must be reconstructible later: what changed,
why, and what it means for users. Agents and humans follow these rules.

1. **Branch, never commit straight to `main`.** Use a topic branch such as
   `fix/<topic>` or `feat/<topic>` (cross-package work in the tidystat effort
   uses `fix/tidystat-phase0`, `feat/tidystat-phase1`, ...).
2. **One logical change per commit.** Test-suite repairs, bug fixes, new
   features and documentation go in separate commits, so each can be
   reviewed, bisected or reverted on its own.
3. **Commit messages explain the why.** Format:
   ```
   <area>: <imperative summary, <= 72 chars>

   Problem:  what was wrong / missing, with the observable symptom.
   Cause:    the root cause (file:function), if it is a fix.
   Change:   what this commit does.
   Impact:   behaviour change for users; mark BREAKING if any.
   Tests:    which tests were added/changed, and the suite result.
   ```
4. **Every commit updates `CHANGELOG.md`** under `## [Unreleased]`, in the
   sections *Fixed*, *Added*, *Changed*, *Breaking*, *Tests*. Each entry
   says what users will notice and names the commit topic.
5. **Run the full test suite before committing** (`make test`, or from the
   umbrella repo `../cl-tidystat/scripts/run-tests.sh <this-package>`) and put
   the result in the commit message. Never commit with a red suite unless
   the commit message says so and why.
6. **Cross-package changes** (e.g. an API in `cl-vctrs-lite` used by
   `cl-dplyr`) are recorded in both repos' changelogs and in
   `../cl-tidystat/docs/CHANGES-phase*.md`, which links the commits.
7. **Push only after review**; do not rewrite history that has been pushed.

## Parity work (R tidyverse equivalence)

This repository is part of the plan to reach full parity with the current
R tidyverse. Milestones owned by this repository: **X3, TB1, TB2, TB3, TB4**.

- Plan, conventions (R -> Lisp names, arguments, types, 0-based indices)
  and the step-by-step workflow: `docs/PARITY-PLAN.md` in
  `../cl-tidystat` (GitHub: gwangjinkim/cl-tidystat, private; ask the
  maintainer for access).
- Function lists with status and target names:
  `../cl-tidystat/parity/backlog/<ID>.md`; overview in `INDEX.md`.
- Work on a branch `feat/parity-<ID>`, write conformance cases first,
  and regenerate the parity status in cl-tidystat after each step.
