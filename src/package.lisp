(defpackage :cl-tibble
  (:use :cl :cl-vctrs-lite)
  (:nicknames #:tibble)
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
           #:as-tibble-options
           #:as-tibble-row #:as-tibble-col #:tibble-row
           #:new-tibble #:validate-tibble #:is-tibble #:lst #:frame-matrix
           #:null-column #:constructor-options #:computed-column #:tibble* #:tbl-attribute
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
