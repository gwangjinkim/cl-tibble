(in-package :cl-tibble/test)

(in-suite :cl-tibble)

(test make-tbl-basic
  "Test creating a simple tibble."
  (let ((df (make-tbl '(("x" . #(1 2 3))
                        ("y" . #(4 5 6))))))
    (is (= 3 (tbl-nrows df)))
    (is (equalp #("x" "y") (tbl-names df)))
    (is (equalp #(1 2 3) (gethash "x" (tbl-columns df))))))

(test make-tbl-length-error
  "Test that mismatched column lengths signal an error."
  (handler-case 
      (make-tbl '(("x" . #(1 2 3))
                  ("y" . #(1 2))))
    (column-length-error () 
      (is t))
    (error (c) 
      (is nil "Expected COLUMN-LENGTH-ERROR but got ~S" (type-of c)))
    (:no-error (&rest args)
      (declare (ignore args))
      (is nil "Did not signal any error."))))

(test make-tbl-duplicate-error
  "Test that duplicate column names signal an error."
  (handler-case
      (make-tbl '(("x" . #(1))
                  ("x" . #(2))))
    (duplicate-column-error ()
      (is t))
    (error (c)
      (is nil "Expected DUPLICATE-COLUMN-ERROR but got ~S" (type-of c)))))

(test make-tbl-empty
  "Test creating an empty tibble."
  (let ((df (make-tbl '())))
    (is (= 0 (tbl-nrows df)))
    (is (= 0 (length (tbl-names df))))))
