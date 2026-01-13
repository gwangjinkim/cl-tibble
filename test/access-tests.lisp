(in-package :cl-tibble/test)

(in-suite :cl-tibble)

(test tbl-col-access
  "Test retrieving columns by name and index."
  (let ((df (tibble "x" #(1 2) "y" #(3 4))))
    (is (equalp #(1 2) (tbl-col df "x")))
    (is (equalp #(1 2) (tbl-col df :x)))
    (is (equalp #(1 2) (tbl-col df 0)))
    (is (equalp #(3 4) (tbl-col df "y")))
    (is (equalp #(3 4) (tbl-col df 1)))))

(test tbl-col-error
  "Test error on missing column."
  (let ((df (tibble "x" #(1))))
    (handler-case
        (tbl-col df "z")
      (unknown-column-error () (is t))
      (error (c) 
        (declare (ignore c))
        (is nil "Wrong error type")))
    (handler-case
        (tbl-col df 10)
      (error () (is t)) ;; Checks bounds error
      (:no-error (&rest args) 
        (declare (ignore args))
        (is nil "Should error out of bounds")))))

(test tbl-ref-cell
  "Test cell access."
  (let ((df (tibble "x" #(10 20))))
    (is (= 10 (tbl-ref df 0 :x)))
    (is (= 20 (tbl-ref df 1 "x")))))

(test slice-rows
  "Test slicing rows."
  (let* ((df (tibble :x #(1 2 3) :y #(4 5 6)))
         (sub (slice df :rows '(0 2))))
    (is (= 2 (tbl-nrows sub)))
    (is (= 2 (length (tbl-names sub))))
    (is (equalp #(1 3) (tbl-col sub :x)))
    (is (equalp #(4 6) (tbl-col sub :y)))))

(test slice-cols
  "Test slicing columns."
  (let* ((df (tibble :a 1 :b 2 :c 3))
         (sub (slice df :cols '(:a :c))))
    (is (= 1 (tbl-nrows sub)))
    (is (equalp #("a" "c") (tbl-names sub)))
    (handler-case
        (tbl-col sub :b)
      (unknown-column-error () (is t))
      (error (c) (is nil "Expected UNKNOWN-COLUMN-ERROR but got ~S" (type-of c))))))

(test slice-combined
  "Test slicing rows and columns."
  (let* ((df (tibble :x #(1 2 3) :y #(4 5 6)))
         (sub (slice df :rows '(0 1) :cols '("y"))))
    (is (= 2 (tbl-nrows sub)))
    (is (equalp #("y") (tbl-names sub)))
    (is (equalp #(4 5) (tbl-col sub :y)))))
