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
