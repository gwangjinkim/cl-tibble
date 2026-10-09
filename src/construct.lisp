(in-package :cl-tibble)

(defun %column-input-p (x)
  ;; Existing Lisp lists are scalar tibble cells; explicit list columns use vectors.
  (and (cl-vctrs-lite:column-p x) (not (listp x))))

(defun recycle-value (val n)
  "Recycle a scalar or column to N rows, preserving X2 prototypes."
  (if (%column-input-p val)
      (cl-vctrs-lite:recycle-to val n)
      (cl-vctrs-lite:restore-column (make-array n :initial-element val)
                                    (cl-vctrs-lite:vec-prototype (vector val)))))

(defun tibble (&rest key-values)
  "Create a tibble from KEY-VALUE pairs.
   Keys can be strings or keywords (downcased).
   Values are recycled to the length of the longest vector input."
  (let ((kv-pairs '()))
    ;; 1. Parse args into (name . value) pairs
    (loop for (k v) on key-values by #'cddr
          do (let ((name (typecase k
                           (string k)
                           (symbol (string-downcase (symbol-name k)))
                           (t (format nil "~A" k)))))
               (push (cons name v) kv-pairs)))
    (setf kv-pairs (nreverse kv-pairs))

    ;; 2. Determine target N
    ;; Find max length of any VECTOR input. Scalars (length 1 vectors or non-vectors) don't dictate length unless all are scalars (then N=1).
    (let ((max-len 1))
      (dolist (pair kv-pairs)
        (let ((val (cdr pair)))
          (when (and (%column-input-p val) (> (cl-vctrs-lite:col-length val) 1))
            (setf max-len (max max-len (cl-vctrs-lite:col-length val))))))
      
      ;; If NO vectors > 1 found, check if any vectors of length 0 exist?
      ;; R tibble rules:
      ;; - If any vector is length 0, result is length 0 (unless we recycle 1 to 0? usually 0 dominates).
      ;; Let's iterate again to check for explicit 0s which force output to 0.
      (dolist (pair kv-pairs)
         (let ((val (cdr pair)))
           (when (and (%column-input-p val) (= (cl-vctrs-lite:col-length val) 0))
             (setf max-len 0))))
      
      ;; 3. Recycle and build
      (let ((final-alist '()))
        (dolist (pair kv-pairs)
          (let ((name (car pair))
                (val (cdr pair)))
            (push (cons name (recycle-value val max-len)) final-alist)))
        (make-tbl (nreverse final-alist))))))

(defgeneric as-tibble (x)
  (:documentation "Coerce X to a tibble."))

(defmethod as-tibble ((x tbl))
  x)

(defmethod as-tibble ((x list))
  ;; Assume alist or plist? 
  ;; cl-tibble decision: List of lists is usually data. Alist is (key . val).
  ;; Let's support ALIST of (string . vector) strictly for now, or PLIST.
  ;; Heuristic: if first element is cons, treat as alist. If keyword, plist.
  (if (null x)
      (make-tbl '())
      (if (consp (car x))
          ;; Alist
          (make-tbl x)
          ;; Plist
          (apply #'tibble x))))

(defun tribble (&rest args)
  "Row-wise tibble construction.
   (tribble :col1 :col2
            1     2
            3     4)
   First N arguments starting with KEYWORDS (or strings) are column names.
   Data follows."
  (let ((col-names '())
        (data args))
    ;; Collect column names
    (loop while (and data (or (keywordp (car data)) (stringp (car data))))
          do (push (pop data) col-names))
    (setf col-names (nreverse col-names))
    
    (let ((n-cols (length col-names)))
      (when (= n-cols 0)
        (return-from tribble (make-tbl '())))
      
      (let ((total-cells (length data)))
        (unless (= (mod total-cells n-cols) 0)
          (error "tibble: Data length ~A is not a multiple of column count ~A." total-cells n-cols))
        
        (let ((n-rows (/ total-cells n-cols))
              (col-vectors (make-array n-cols)))
          ;; Initialize vectors
          (dotimes (i n-cols)
            (setf (aref col-vectors i) (make-array n-rows)))
          
          ;; Fill vectors row by row
          (dotimes (r n-rows)
            (dotimes (c n-cols)
              (let ((val (pop data)))
                (setf (aref (aref col-vectors c) r) val))))
          
          ;; Construct alist
          (let ((alist '()))
            (loop for name in col-names
                  for idx from 0
                  do (let ((key (if (keywordp name) (string-downcase (symbol-name name)) name))
                           (vec (aref col-vectors idx)))
                       (push (cons key vec) alist)))
            (make-tbl (nreverse alist))))))))

(defun enframe (x &key (name "name") (value "value"))
  "Convert a vector or list X to a tibble with columns NAME and VALUE."
  (let ((vec (if (vectorp x) x (coerce x 'vector))))
    (let ((len (length vec))
          (name-col (make-array (length vec) :fill-pointer 0 :adjustable t)))
      ;; Generate indices 1..N
      (dotimes (i len)
        (vector-push (1+ i) name-col))
      
      (if name
          (tibble name name-col value vec)
          (tibble value vec)))))

(defun deframe (x)
  "Convert a 1 or 2 column tibble to a vector or alist."
  (let ((n-cols (length (tbl-names x))))
    (cond
      ((= n-cols 1)
       ;; Return just the vector
       (gethash (aref (tbl-names x) 0) (tbl-columns x)))
      ((= n-cols 2)
       ;; Return alist (name . value)
       ;; Actually R deframe returns a named vector. CL doesn't have named vectors.
       ;; Let's return a PLIST or ALIST? 
       ;; R deframe on 2 cols: 1st col is names, 2nd is values.
       (let* ((n-col (aref (tbl-names x) 0))
              (v-col (aref (tbl-names x) 1))
              (names (gethash n-col (tbl-columns x)))
              (vals (gethash v-col (tbl-columns x)))
              (len (tbl-nrows x)))
         (loop for i from 0 below len
               collect (cons (aref names i) (aref vals i)))))
      (t
       (error "tibble: deframe requires 1 or 2 columns.")))))
