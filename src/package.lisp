(defpackage :cl-tibble
  (:use :cl :cl-vctrs-lite)
  (:export #:tbl
           #:make-tbl
           #:tbl-columns
           #:tbl-names
           #:tbl-nrows
           #:tibble-error
           #:column-length-error
           #:duplicate-column-error
           #:tibble
           #:as-tibble
           #:tribble
           #:enframe
           #:deframe
           #:tbl-col
           #:tbl-ref
           #:slice
           #:glimpse
           #:slice
           #:glimpse
           #:bind-rows
           #:bind-cols
           #:with-tibble
           #:chain
           #:do-rows
           #:prt
           #:unknown-column-error))
