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
