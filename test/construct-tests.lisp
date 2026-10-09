(in-package :cl-tibble/test)

(in-suite :cl-tibble)

(test tibble-basic
  "Test tibble constructor."
  (let ((df (tibble "x" #(1 2) "y" #(3 4))))
    (is (= 2 (tbl-nrows df)))
    (is (equalp #(1 2) (gethash "x" (tbl-columns df))))))

(test tibble-recycling-scalar
  "Test recycling scalar to vector length."
  (let ((df (tibble "x" #(1 2 3) "y" 10)))
    (is (= 3 (tbl-nrows df)))
    (is (equalp #(10 10 10) (gethash "y" (tbl-columns df))))))

(test tibble-recycling-1-vec
  "Test recycling length-1 vector to N."
  (let ((df (tibble "x" #(1 2 3) "y" #(9))))
    (is (= 3 (tbl-nrows df)))
    (is (equalp #(9 9 9) (gethash "y" (tbl-columns df))))))

(test tibble-recycling-error
  "Test error on incompatible lengths."
  (handler-case
      (tibble "x" #(1 2 3) "y" #(1 2))
    (error (e)
      (declare (ignore e))
      (pass "Correctly signaled error"))
    (:no-error (&rest args)
      (declare (ignore args))
      (is-true nil "Should have signaled error"))))

(test tribble-basic
  "Test row-wise construction."
  (let ((df (tribble :x :y
                     1  2
                     3  4)))
    (is (= 2 (tbl-nrows df)))
    (is (equalp #(1 3) (gethash "x" (tbl-columns df))))
    (is (equalp #(2 4) (gethash "y" (tbl-columns df))))))

(test enframe-basic
  "Test enframe vector."
  (let ((df (enframe #(10 20 30))))
    (is (= 3 (tbl-nrows df)))
    (is (equalp #("name" "value") (tbl-names df)))
    (is (equalp #(1 2 3) (gethash "name" (tbl-columns df))))
    (is (equalp #(10 20 30) (gethash "value" (tbl-columns df))))))
