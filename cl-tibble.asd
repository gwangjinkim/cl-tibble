(asdf:defsystem "cl-tibble"
  :description "A strict, modern data frame implementation for Common Lisp, modeled on R's tibble."
  :author "Gwang-Jin Kim <gwang.jin.kim.phd@gmail.com>"
  :license "MIT"
  :version "0.1.0"
  :depends-on (:cl-vctrs-lite)
  :components ((:module "src"
                :components
                ((:file "package")
                 (:file "conditions" :depends-on ("package"))
                 (:file "tbl" :depends-on ("package"))
                 (:file "construct" :depends-on ("tbl"))
                 (:file "constructors" :depends-on ("construct"))
                 (:file "access" :depends-on ("constructors"))
                 (:file "print" :depends-on ("access"))
                 (:file "bind" :depends-on ("construct"))
                 (:file "dsl" :depends-on ("bind" "print")))))
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
                 (:file "parity-constructors" :depends-on ("suite"))
                 (:file "access-tests" :depends-on ("suite"))
                 (:file "print-tests" :depends-on ("suite"))
                 (:file "bind-tests" :depends-on ("suite"))
                 (:file "dsl-tests" :depends-on ("suite")))))
  :perform (asdf:test-op (o c) (symbol-call :fiveam :run! :cl-tibble)))
