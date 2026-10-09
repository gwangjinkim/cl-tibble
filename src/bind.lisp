(in-package :cl-tibble)

(defun bind-rows (&rest tibbles)
  "R: dplyr::bind_rows(). Bind columns using X2 prototypes, filling absent columns with typed NA."
  (let ((names (remove-duplicates (loop for tbl in tibbles append (coerce (tbl-names tbl) 'list))
                                  :test #'equal :from-end t)))
    (make-tbl
     (loop for name in names
           for present = (loop for tbl in tibbles for col = (gethash name (tbl-columns tbl))
                               when col collect col)
           for prototype = (reduce (lambda (a b) (cl-vctrs-lite:common-prototype a b :strict nil))
                                    (cdr present) :initial-value (cl-vctrs-lite:vec-prototype (first present)))
           collect (cons name
                         (apply #'cl-vctrs-lite:vec-c
                                (loop for tbl in tibbles
                                      collect (or (gethash name (tbl-columns tbl))
                                                  (cl-vctrs-lite:vec-init prototype (tbl-nrows tbl))))))))))

(defun bind-cols (&rest tibbles)
  "Combine TIBBLES horizontally.
   Rows must match. Duplicate columns signal error."
  (if (null tibbles)
      (make-tbl '())
      (let ((expected-rows (tbl-nrows (first tibbles)))
            (new-alist '()))
        ;; 1. Check row consistency
        (dolist (tbl tibbles)
          (unless (= (tbl-nrows tbl) expected-rows)
            (error "tibble: bind-cols row mismatch. Expected ~A, got ~A." expected-rows (tbl-nrows tbl))))
        
        ;; 2. Collect columns
        (dolist (tbl tibbles)
          (let ((names (tbl-names tbl))
                (cols (tbl-columns tbl)))
            (loop for name across names
                  do (push (cons name (gethash name cols)) new-alist))))
        
        (make-tbl (nreverse new-alist)))))
