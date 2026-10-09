(in-package :cl-tibble)

(defclass tbl ()
  ((columns :initarg :columns
            :type hash-table
            :reader tbl-columns
            :documentation "Hash table mapping column names (strings) to vectors.")
   (names :initarg :names
          :type vector
          :reader tbl-names
          :documentation "Vector of column names (strings) in order.")
   (nrows :initarg :nrows
          :type integer
          :reader tbl-nrows
          :documentation "Number of rows in the tibble."))
  (:documentation "A strict data frame structure."))

(defun make-tbl (alist)
  "Create a new tbl from an ALIST of (name . vector).
   Enforces:
   1. All names must be unique.
   2. All values must be vectors (or vector-like).
   3. All vectors must have the same length."
  (let ((names (make-array (length alist) :element-type 'string :adjustable t :fill-pointer 0 :initial-element ""))
        (columns (make-hash-table :test 'equal))
        (nrows nil)
        (seen-names (make-hash-table :test 'equal)))

    (dolist (pair alist)
      (let* ((name (string (car pair))) ; ensure string
             (col (cdr pair)) ;; In future, we might coerce to vector here using cl-vctrs-lite
             (len (cl-vctrs-lite:col-length col)))
        
        ;; 1. Check uniqueness
        (when (gethash name seen-names)
          (error 'duplicate-column-error :name name))
        (setf (gethash name seen-names) t)
        
        ;; 2. Check length consistency
        (if (null nrows)
            (setf nrows len)
            (unless (= len nrows)
              (error 'column-length-error 
                     :column name :length len :expected-length nrows)))
        
        ;; Add to structure
        (vector-push name names)
        (setf (gethash name columns) col)))

    (make-instance 'tbl
                   :columns columns
                   :names names
                   :nrows (or nrows 0))))


