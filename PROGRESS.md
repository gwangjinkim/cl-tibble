# Project Progress

This document tracks the development milestones of `cl-tibble`.

## M0: Project Scaffolding [DONE]
**Goal**: Initialize project structure and test infrastructure.
*   Created `cl-tibble.asd` with `fiveam` and `cl-vctrs-lite` dependencies.
*   Set up `scripts/test.ros` and `Makefile`.
*   Created basic package definitions.

## M1: The Core Struct [DONE]
**Goal**: Implement the fundamental data structure.
*   Implemented `tbl` class in `src/tbl.lisp`.
*   Implemented `make-tbl` with strict validations:
    *   **Invariants**: All columns must be equal length. Names must be unique.
*   Defined condition hierarchy in `src/conditions.lisp`.
*   Verified with `test/tbl-tests.lisp`.

## M2: Constructors [DONE]
**Goal**: User-friendly creation of tibbles.
*   Implemented `tibble` in `src/construct.lisp`.
    *   Added **recycling**: Scalars are automatically extended to match vector length.
*   Implemented `tribble` for row-wise construction.
*   Implemented `as-tibble` coercions.
*   Implemented `enframe`/`deframe`.
*   Verified with `test/construct-tests.lisp`.

## M3: Accessors [DONE]
**Goal**: Safe data retrieval.
*   Implemented `tbl-col` for column access by name/index.
*   Implemented `tbl-ref` for cell access.
*   Implemented `slice` for functional subsetting of rows/cols.
*   Verified with `test/access-tests.lisp`.

## M4: Display [DONE]
**Goal**: Pretty-printing.
*   Implemented `print-object` in `src/print.lisp`.
    *   Format: `#<A TIBBLE: R x C>`
    *   Shows column type headers (`<int>`, `<chr>`).
    *   Aligns columns.
    *   Truncates output (first 10 rows).
*   Implemented `glimpse` for transposed view.
*   Verified with `test/print-tests.lisp`.

## M5: Bind [DONE]
**Goal**: Combining datasets.
*   Implemented `bind-rows` in `src/bind.lisp`.
    *   Unions column names.
    *   Fills missing data with `NIL`.
*   Implemented `bind-cols` in `src/bind.lisp`.
    *   Enforces row count compatibility.
*   Verified with `test/bind-tests.lisp`.

## M6: Lispy DSL [DONE]
**Goal**: Ergonomic Macros.
*   Implemented `with-tibble` for lexical column binding in `src/dsl.lisp`.
*   Implemented `chain` (threading macro).
*   Implemented `do-rows` iterator.
*   Verified with `test/dsl-tests.lisp`.

---
**Status**: All milestones complete (v0.1 feature complete).
