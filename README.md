# cl-tibble

A Common Lisp implementation of R's **tibble** data frames. 

`cl-tibble` provides a "surly" and "lazy" data structure for tabular data. It enforces strict invariants (unlike standard alists/plists) while providing a modern, ergonomic API for data manipulation.

## Features

*   **Surly**: Complains if columns are different lengths. Rejects invalid column names.
*   **Lazy**: Does not coerce types. Does not partial match names.
*   **Rich Display**: Pretty-printing with type abbreviations (`<int>`, `<dbl>`) and automatic truncation.
*   **Ergonomic**: "Lispy" DSL (`with-tibble`, `chain`) for easy data manipulation.

## Installation

Clone into your local-projects directory:

```bash
cd ~/common-lisp/  # or wherever your local-projects are
git clone https://github.com/yourusername/cl-tibble.git
```

Load with Quicklisp:

```lisp
(ql:quickload :cl-tibble)
```

## Usage

### 1. Creation

**`tibble`**: The standard constructor. Supports **recycling** of scalars.

```lisp
(cl-tibble:tibble 
  :x #(1 2 3) 
  :y "val"       ;; Recycled to #("val" "val" "val")
  :z #(10 20 30))
;; #<A TIBBLE: 3 x 3>
;; x       y       z       
;; <int>   <chr>   <int>   
;; 1       "val"   10      
;; 2       "val"   20      
;; 3       "val"   30      
```

**`tribble`**: Row-wise construction for inline data.

```lisp
(cl-tibble:tribble 
  :name  :age
  "Alice" 25
  "Bob"   30)
```

**`as-tibble`**: Coerce alists or plists.

```lisp
(cl-tibble:as-tibble '((:x . #(1)) (:y . #(2))))
```

### 2. Display

Tibbles print lazily, showing only the first 10 rows. For a structure overview, use **`glimpse`**:

```lisp
(cl-tibble:glimpse df)
;; Rows: 3
;; Columns: 3
;; $ x <int> 1, 2, 3...
;; $ y <chr> "val", "val", "val"...
```

### 3. Access

**`tbl-col`**: Retrieve a column vector by name (string/keyword) or index.

```lisp
(cl-tibble:tbl-col df :x) ;; => #(1 2 3)
```

**`tbl-ref`**: Access a specific cell `(row, col)`.

```lisp
(cl-tibble:tbl-ref df 0 :y) ;; => "val"
```

**`slice`**: Subset rows and columns (functional, returns new tibble).

```lisp
(cl-tibble:slice df :rows '(0 2) :cols '(:x :z))
```

### 4. Binding

Combine tibbles vertically or horizontally.

```lisp
(cl-tibble:bind-rows df1 df2) ;; Fills missing columns with NIL
(cl-tibble:bind-cols df1 df2) ;; Requires matching row counts
```

### 5. Lispy DSL

**`with-tibble`**: Lexically bind columns to variables.

```lisp
(cl-tibble:with-tibble (df x y)
  (print (aref x 0)))
```

**`chain`**: Thread-first macro for pipelines.

```lisp
(cl-tibble:chain (cl-tibble:tibble :x #(1 2))
  (cl-tibble:bind-cols (cl-tibble:tibble :y #(3 4)))
  (cl-tibble:slice :rows '(0)))
```

**`do-rows`**: Iterate over rows.

```lisp
(cl-tibble:do-rows (r df)
  (print (getf r :x)))
```

## Testing

Run the test suite with:

```bash
make test
```

Or in Lisp:

```lisp
(asdf:test-system :cl-tibble)
```

## Typed columns (parity X2)

Construction, slicing and row binding use the shared cl-vctrs-lite column
protocol. Typed empty and all-NA columns retain their prototype. Printing
and `glimpse` show `<date>`, `<dttm>`, `<time>`, `<Duration>`, `<fct>`/`<ord>`
and `<list>`, alongside the existing atomic abbreviations. Full pillar
layout/formatting remains milestone X3.

```lisp
(tibble :date (cl-vctrs-lite:vec-init :date 2)
        :nested (cl-vctrs-lite:make-typed-column (vector '(1 2) nil) :list))
```

With cl-forcats loaded, factor objects can be columns and remain factors
through slicing and binding; their levels are retained/unioned. Absent
columns in row binding use typed NA, not logical FALSE. Scalar strings
recycle as character cells. Existing Lisp list inputs remain scalar cells;
construct explicit list columns with `make-typed-column` and a vector.
These changes do not implement factor support in every dplyr verb.

## Constructors and coercion (TB1)

| R | Common Lisp |
|---|---|
| `tibble`, `tibble_row` | `tibble`, `tibble-row` |
| `as_tibble`, `as_tibble_col`, `as_tibble_row` | `as-tibble`, `as-tibble-col`, `as-tibble-row` |
| `enframe`, `deframe` | `enframe`, `deframe` |
| `tribble`, `frame_matrix` | `tribble`, `frame-matrix` |
| `new_tibble`, `validate_tibble` | `new-tibble`, `validate-tibble` |
| `is_tibble`, `lst` | `is-tibble`, `lst` |

`computed-column` receives a partial tibble for sequential construction;
`tibble*` offers lexical syntax while `tibble` remains callable by APPLY.
Explicit typed :LIST columns represent R lists. Plain lists supplied to
`tibble` keep their existing scalar-cell meaning; `enframe` retains its
existing atomic interpretation unless `:list-column t` is supplied.
`null-column` represents an omitted R NULL column separately from scalar
NIL (logical FALSE).

`tibble` accepts a leading `constructor-options` object for row counts and
name repair; flat `:rows` and `:name-repair` keys remain ordinary columns.
`as-tibble` retains its one-argument generic extension signature. Use the
additive `as-tibble-options` helper for row counts and name repair. Repair
strategies are `:check-unique`, `:unique`, `:universal` and `:minimal`;
quiet variants and a callback are also supported. Minimal duplicate names
retain positional columns: `(tbl-col df 1)` reads the second column, while
name lookup and `tbl-columns` expose the first occurrence. Repair to unique
names before using sibling verbs; their duplicate-name behavior is not
certified. `make-tbl` continues to reject duplicates.

`frame-matrix` accepts an explicit vector of header strings followed by
row-major cells. It returns a rank-two array, names and a type keyword as
three values. Private weak metadata lets `as-tibble` consume that matrix
with its labels and empty prototype. Nested tibble/matrix columns are
rejected until a shared C2 owner protocol can preserve their shape.
`new-tibble` stores an explicit row count without validating column lengths;
`validate-tibble` performs that check. Its optional attributes can be read
with `tbl-attribute`; general metadata restoration belongs to later work.

TB1 remains partial. Direct `as-tibble` keyword options, packed/matrix
column owners, full R expression-label generation and dynamic splice
lexical scope are not certified. Existing `deframe` defaults keep alists
for two columns; additive `:named-vector t` opts into owner-preserving
atomic names or D12 list results. The default return migration awaits the
maintainer's decision in the umbrella compatibility proposal. Printing
parity remains X3. No native function invokes R.

Scalar NIL is logical FALSE in the new column/row coercions; use
`null-column` for R NULL. A computed callback returning `null-column`
omits that column. Existing `as-tibble` alist columns supplied as proper
lists retain their multiple-row atomic interpretation; plist and `tibble`
proper-list cells keep their scalar-cell interpretation.

Validation: 182 package checks and 133 active pinned R 4.6.1 / tibble 3.3.1
cases pass (125 constructor cases plus eight baseline cases). Eight genuine
unsupported or pending-default mismatches remain archived outside active
parity credit. Row/list constructors and validators remain partial for
nested matrix/frame owners even when their ordinary inputs pass.
