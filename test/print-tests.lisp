(in-package :cl-tibble/test)

(in-suite :cl-tibble)

(test print-tbl-simple
  "Test simple printing."
  (let ((df (tibble "x" #(1 2) "y" #("a" "b")))
        (out (make-string-output-stream)))
    (print-object df out)
    (let ((s (get-output-stream-string out)))
      (is (search "#<A TIBBLE: 2 x 2>" s))
      (is (search "x" s))
      (is (search "y" s))
      (is (search "<int>" s))
      (is (search "<chr>" s))
      (is (search "1" s))
      (is (search "\"a\"" s)))))

(test print-tbl-truncate
  "Test truncation."
  (let* ((vec (make-array 15 :initial-element 1))
         (df (tibble "x" vec))
         (out (make-string-output-stream)))
    (print-object df out)
    (let ((s (get-output-stream-string out)))
      (is (search "with 5 more rows" s)))))

(test glimpse-simple
  "Test glimpse output."
  (let ((df (tibble :x #(1) :y #(2)))
        (out (make-string-output-stream)))
    (cl-tibble:glimpse df out)
    (let ((s (get-output-stream-string out)))
      (is (search "Rows: 1" s))
      (is (search "Columns: 2" s))
      (is (search "$ x <int> 1," s)))))
