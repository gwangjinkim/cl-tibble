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
  "Retrieve a column by name or zero-based position. Names select the first occurrence.
Unchecked NEW-TIBBLE objects may contain NIL columns until validation."
  (let* ((name (resolve-col-name tbl col-spec))
         (present (nth-value 1 (gethash name (tbl-columns tbl)))))
    (unless present (error 'unknown-column-error :name name))
    (if (integerp col-spec) (%tbl-column-at tbl col-spec)
        (gethash name (tbl-columns tbl)))))

(defun tbl-ref (tbl row col-spec)
  "Retrieve the value at ROW and COL-SPEC."
  (let ((vec (tbl-col tbl col-spec)))
    (unless (and (>= row 0) (< row (cl-vctrs-lite:col-length vec)))
      (error "tibble: Row index ~D out of bounds." row))
    (cl-vctrs-lite:col-ref vec row)))

(defun slice (tbl &key rows cols)
  "Return a tibble subset, preserving positional minimally named columns.
ROWS and COLS use zero-based positions; NIL retains all, as in the legacy API."
  (let* ((indices (if cols (mapcar (lambda (spec)
                                    (if (integerp spec)
                                        (progn (resolve-col-name tbl spec) spec)
                                        (let* ((name (resolve-col-name tbl spec))
                                               (index (position name (tbl-names tbl) :test #'equal)))
                                          (unless index (error 'unknown-column-error :name name))
                                          index))) cols)
                      (loop for i below (length (tbl-names tbl)) collect i)))
         (row-indices (or rows (loop for i below (tbl-nrows tbl) collect i))))
    (%allocate-tbl (map 'vector (lambda (i) (aref (tbl-names tbl) i)) indices)
                   (map 'vector (lambda (i) (col-subseq (%tbl-column-at tbl i) row-indices)) indices)
                   (length row-indices))))
