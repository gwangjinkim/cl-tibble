(in-package :cl-tibble/test)

(in-suite :cl-tibble)

(test bind-rows-basic
  "Test simple vertical binding."
  (let* ((d1 (tibble :x #(1) :y #(2)))
         (d2 (tibble :x #(3) :y #(4)))
         (res (bind-rows d1 d2)))
    (is (= 2 (tbl-nrows res)))
    (is (equalp #(1 3) (tbl-col res :x)))
    (is (equalp #(2 4) (tbl-col res :y)))))

(test bind-rows-fill
  "Test filling missing columns with NIL."
  (let* ((d1 (tibble :x #(1)))
         (d2 (tibble :y #(2)))
         (res (bind-rows d1 d2)))
    (is (= 2 (tbl-nrows res)))
    (is (equalp #("x" "y") (tbl-names res)))
    (is (equalp #(1 nil) (tbl-col res :x)))
    (is (equalp #(nil 2) (tbl-col res :y)))))

(test bind-cols-basic
  "Test simple horizontal binding."
  (let* ((d1 (tibble :x #(1 2)))
         (d2 (tibble :y #(3 4)))
         (res (bind-cols d1 d2)))
    (is (= 2 (tbl-nrows res)))
    (is (equalp #("x" "y") (tbl-names res)))
    (is (equalp #(1 2) (tbl-col res :x)))
    (is (equalp #(3 4) (tbl-col res :y)))))

(test bind-cols-mismatch
  "Test row mismatch error."
  (let ((d1 (tibble :x #(1)))
        (d2 (tibble :y #(1 2))))
    (handler-case
        (bind-cols d1 d2)
      (error () (pass))
      (:no-error (&rest args) 
        (declare (ignore args))
        (is-true nil "Should error on mismatch")))))

(test bind-cols-duplicate
  "Test duplicate column error."
  (let ((d1 (tibble :x #(1)))
        (d2 (tibble :x #(2))))
    (handler-case
        (bind-cols d1 d2)
      (duplicate-column-error () (pass))
      (error () (is-true nil "Wrong error type")))))
