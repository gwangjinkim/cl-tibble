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
