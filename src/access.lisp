(in-package :cl-tibble)

(defun resolve-col-name (tbl col-spec)
  "Resolve COL-SPEC (string/keyword/integer) to a column name string.
   Signals ERROR if index out of bounds."
  (typecase col-spec
    (integer 
     (let ((len (length (tbl-names tbl))))
       (unless (and (>= col-spec 0) (< col-spec len))
         (error "tibble: Column index ~D out of bounds (0-~D)." col-spec (1- len)))
       (aref (tbl-names tbl) col-spec)))
    (keyword (string-downcase (symbol-name col-spec)))
    (string col-spec)
    (t (error "tibble: Invalid column specifier: ~S" col-spec))))

(defun tbl-col (tbl col-spec)
  "Retrieve the vector for column COL-SPEC (name or index)."
  (let* ((name (resolve-col-name tbl col-spec))
         (col (gethash name (tbl-columns tbl))))
    (unless col
      (error 'unknown-column-error :name name))
    col))

(defun tbl-ref (tbl row col-spec)
  "Retrieve the value at ROW and COL-SPEC."
  (let ((vec (tbl-col tbl col-spec)))
    (unless (and (>= row 0) (< row (cl-vctrs-lite:col-length vec)))
      (error "tibble: Row index ~D out of bounds." row))
    (cl-vctrs-lite:col-ref vec row)))

(defun slice (tbl &key rows cols)
  "Return a new tibble with a subset of rows and/or columns.
   ROWS: List of integer indices. If NIL, keep all.
   COLS: List of column names/indices. If NIL, keep all."
  ;; 1. Determine columns to keep
  (let ((keep-names (if cols
                        (mapcar (lambda (c) (resolve-col-name tbl c)) cols)
                        (coerce (tbl-names tbl) 'list))))
    
    ;; 2. Build new columns
    (let ((new-alist '()))
      (dolist (name keep-names)
        (let ((orig-vec (tbl-col tbl name))
              (new-vec nil))
          (setf new-vec (cl-vctrs-lite:col-subseq
                           orig-vec (or rows (loop for i below (cl-vctrs-lite:col-length orig-vec) collect i))))
          (push (cons name new-vec) new-alist)))
      (make-tbl (nreverse new-alist)))))
