(asdf:defsystem "cl-tibble"
  :description "A strict, modern data frame implementation for Common Lisp, modeled on R's tibble."
  :author "Antigravity"
  :license "MIT"
  :version "0.1.0"
  :depends-on (:cl-vctrs-lite)
  :components ((:module "src"
                :components
                ((:file "package")
                 (:file "conditions" :depends-on ("package"))
                 (:file "tbl" :depends-on ("package"))
                 (:file "construct" :depends-on ("tbl"))
                 (:file "access" :depends-on ("construct")))))
  :in-order-to ((asdf:test-op (asdf:test-op "cl-tibble/test"))))

(asdf:defsystem "cl-tibble/test"
  :description "Test suite for cl-tibble."
  :author "Antigravity"
  :license "MIT"
  :depends-on (:cl-tibble :fiveam)
  :components ((:module "test"
                :components
                ((:file "package")
                 (:file "suite" :depends-on ("package"))
                 (:file "tbl-tests" :depends-on ("suite"))
                 (:file "construct-tests" :depends-on ("suite"))
                 (:file "access-tests" :depends-on ("suite")))))
  :perform (asdf:test-op (o c) (symbol-call :fiveam :run! :cl-tibble)))
