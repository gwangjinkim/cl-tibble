(in-package :cl-tibble)

;; 1. with-tibble
(defmacro with-tibble ((tbl &rest col-names) &body body)
  "Evaluate BODY with COL-NAMES lexically bound to their vector values in TBL.
   Example: (with-tibble (df x y) (print x))
   Symbols are downcased to find strings."
  (let ((g-tbl (gensym "TBL")))
    `(let ((,g-tbl ,tbl))
       (symbol-macrolet (,@(loop for name in col-names
                                 collect `(,name (tbl-col ,g-tbl ,(string-downcase (symbol-name name))))))
         ,@body))))

;; 2. chain (->)
(defmacro chain (x &body forms)
  "Thread X through FORMS as the first argument."
  (let ((res x))
    (dolist (form forms)
      (if (listp form)
          (setf res `(,(car form) ,res ,@(cdr form)))
          (setf res `(,form ,res))))
    res))

;; 3. do-rows
(defmacro do-rows ((row-var tbl &optional result) &body body)
  "Iterate over TBL rows.
   ROW-VAR is bound to a DATUM representing the row (optimally).
   For now, let's make ROW-VAR a PLIST of (key val ...).
   This is inefficient but convenient."
  (let ((g-tbl (gensym "TBL"))
        (g-i (gensym "I"))
        (g-idx (gensym "IDX"))
        (g-len (gensym "LEN"))
        (g-names (gensym "NAMES"))
        (g-cols (gensym "COLS")))
    `(let* ((,g-tbl ,tbl)
            (,g-names (tbl-names ,g-tbl))
            (,g-cols (coerce (loop for i below (length ,g-names) collect (%tbl-column-at ,g-tbl i)) 'vector))
            (,g-len (tbl-nrows ,g-tbl)))
       (dotimes (,g-i ,g-len ,result)
         (let ((,row-var (loop for ,g-idx from 0
                               for name across ,g-names
                               for col across ,g-cols
                               collect (intern (string-upcase name) :keyword)
                               collect (aref col ,g-i))))
           ,@body)))))

;; 4. prt
(defun prt (x)
  (print-object x *standard-output*)
  x)
