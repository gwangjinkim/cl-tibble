(in-package :cl-tibble)

(defun bind-rows (&rest tibbles)
  "Combine TIBBLES vertically.
   Columns are matched by name. Missing columns are filled with the shared NA singleton."
  (if (null tibbles)
      (make-tbl '())
      (let* ((all-names (make-array 0 :element-type 'string :fill-pointer 0 :adjustable t))
             (seen-names (make-hash-table :test 'equal)))
        ;; 1. Collect all column names in order
        (dolist (tbl tibbles)
          (loop for name across (tbl-names tbl)
                do (unless (gethash name seen-names)
                     (setf (gethash name seen-names) t)
                     (vector-push-extend name all-names))))
        
        ;; 2. Build new columns
        (let ((new-alist '()))
          (loop for name across all-names
                do (let ((combined-vec (make-array 0 :fill-pointer 0 :adjustable t)))
                     (dolist (tbl tibbles)
                       (let ((nrows (tbl-nrows tbl))
                             (col (gethash name (tbl-columns tbl))))
                         (if col
                             ;; Append existing column
                             (loop for x across col
                                   do (vector-push-extend x combined-vec))
                             ;; Column missing in this tbl, append NAs
                             (loop repeat nrows
                                   do (vector-push-extend cl-vctrs-lite:*na* combined-vec)))))
                     (push (cons name combined-vec) new-alist)))
          (make-tbl (nreverse new-alist))))))

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
