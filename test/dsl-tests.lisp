(in-package :cl-tibble/test)

(in-suite :cl-tibble)

(test chain-basic
  "Test threading macro."
  (let ((res (chain (tibble :x #(1 2))
                (bind-cols (tibble :y #(3 4)))
                (tbl-col :y))))
    (is (equalp #(3 4) res))))

(test with-tibble-basic
  "Test dynamic binding of columns."
  (let ((df (tibble :x #(10 20) :y #(30 40))))
    (with-tibble (df x y)
      (is (equalp #(10 20) x))
      (is (equalp #(30 40) y)))))

(test do-rows-basic
  "Test row iteration."
  (let ((df (tibble :x #(1 2) :y #(3 4)))
        (sum 0))
    (do-rows (r df)
      (incf sum (getf r :x))
      (incf sum (getf r :y)))
    (is (= 10 sum))))
