# cl-tibble Specification

**Goal**: Build a Common Lisp implementation of R's `tibble` (modern data frames), built on top of `cl-vctrs-lite`.

## Core Philosophy (from R tibble)

*   **Lazy**: Do less than `data.frame`s. Don't coerce types, don't partial match names, don't drop dimensions.
*   **Surly**: Complain more. Strict constraints on column lengths.
*   **Pretty**: Enhanced printing method that handles large data gracefully.

## Architecture

### Dependencies
*   `cl-vctrs-lite` (vectors, types, NA, recycling)
*   `cl-ppcre` (optional, for printing regex if needed)
*   `cl-ansi-text` (optional, for printing colors)

### The tbl Structure
A tibble is a struct (or class) with:
*   `columns`: A hash-table or alist of `{name: vector}`.
*   `names`: A vector of column names (strings), preserving order.
*   `nrows`: Cached number of rows (integer).

**Invariants**:
1.  All columns must be vector-like (checked by `cl-vctrs-lite`).
2.  All columns must have length equal to `nrows`.
3.  Column names must be unique (or handled by `repair_names` logic).

## API Surface

### Constructors
*   `tibble (&rest key-values)`:
    *   Example: `(tibble "x" #(1 2) "y" #(3 4))`
    *   Supports recycling of length-1 inputs.
*   `tribble`: Row-wise construction.
*   `as-tibble (x)`: Coercion from list of lists / vectors / alists / plists.
*   `enframe (x)`: Convert vector to tibble (name, value).
*   `deframe (x)`: Convert tibble to vector (2 columns).

### Accessors
*   `tbl-ref (tbl row col)`: Ref a single cell.
*   `tbl-col (tbl col-name/idx)`: Extract a column as a vector.
*   `$` (wrapper macro): `($ tbl "col")` access.
*   `tbl-dims (tbl)`: Returns `(values rows cols)`.

### Binding
*   `bind-rows (&rest tbls)`: Combine tables vertically.
    *   Uses `cl-vctrs-lite:vec-c` on matching columns.
    *   Handles missing columns in one table by filling with NA.
*   `bind-cols (&rest tbls)`: Combine tables horizontally.
    *   Checks row compatibility.

### Display
*   `print-object`:
    *   Shows dims: `#<A TIBBLE: 10 x 3>`
    *   Shows header with types: `x <int>  y <dbl>`
    *   Truncates rows: Shows first 10 rows, then "... with N more rows".
    *   Truncates columns: Fits to screen width.
*   `glimpse (tbl)`: Transposed view for quick inspection of many columns.

## Lispy Syntactic Sugar DSL
To ensure `cl-tibble` feels native to Common Lisp while maintaining Tidyverse semantics, we introduce the following "Lispy" sugars.

### 1. `with-tibble` Context
Similar to `with-slots`, this macro binds column names to variables within a scope.
```lisp
(with-tibble (df)
  (print x)  ; x is the vector column "x"
  (print y))
```

### 2. The `@` Accessor Reader (Optional Proposal)
A shorthand for column access, similar to R's `$`.
*   `@df` -> The tibble itself?
*   `@df.col` -> Column access?
*   *Decision*: For now, stick to `($ df "col")` or `(col df "col")` to avoid reader macro hell, but provide a `chain` macro.

### 3. `chain` (or `->`)
A threading macro specifically designed for tibble operations, passing the result as the first argument (like `cl-arrows`).
```lisp
(chain df
  (filter :x (> _ 5))
  (select :x :z))
```
(Note: `filter` and `select` belong to `cl-dplyr`, but `cl-tibble` should be designed to support this).

### 4. Keyword Constructor Sugar
Allow keywords as column names in `tibble` for convenience, auto-converting to strings.
```lisp
(tibble :x #(1 2) :y #(3 4)) 
;; Creates columns named "x" and "y"
```

### 5. `row-map` and `col-map`
Functional interactors.
```lisp
(col-map tbl #'mean) ; Returns raw list/vector of means
```

## Testing Strategy
*   Mirrors `cl-vctrs-lite`: Tests first, detailed error messages.
*   Verify "surly" behavior (errors on len mismatch).
*   Verify "lazy" behavior (no unexpected coercions).
