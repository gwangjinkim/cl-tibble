(in-package :cl-tibble)

(defun vec-type-abbrev (vec)
  "Return a short string representing the type of elements in VEC."
  (if (= 0 (length vec))
      "<empty>"
      (let ((el (aref vec 0)))
        (typecase el
          (integer "<int>")
          (float   "<dbl>")
          (string  "<chr>")
          (keyword "<key>")
          (t       "<obj>")))))

(defun format-cell (val)
  "Return string representation of VAL for printing."
  (typecase val
    (string (format nil "~S" val)) ; Quote strings
    (t (format nil "~A" val))))

(defmethod print-object ((tbl tbl) stream)
  (if *print-readably*
      (call-next-method)
      (let ((nrows (tbl-nrows tbl))
            (names (tbl-names tbl)))
        (format stream "#<A TIBBLE: ~D x ~D>~%" nrows (length names))
        
        (when (> (length names) 0)
          ;; Calculate column widths
          (let* ((col-data (loop for name across names
                                 collect (gethash name (tbl-columns tbl))))
                 (type-subheaders (mapcar #'vec-type-abbrev col-data))
                 (display-rows (min 10 nrows))
                 (col-widths (loop for name across names
                                   for type-str in type-subheaders
                                   for col in col-data
                                   collect 
                                   (let ((w (max (length name) (length type-str))))
                                     (dotimes (i display-rows)
                                       (setf w (max w (length (format-cell (aref col i))))))
                                     w))))
            
            ;; Print Header
            (loop for name across names
                  for w in col-widths
                  do (format stream "~VA  " w name))
            (format stream "~%")
            
            ;; Print Types
            (loop for type-str in type-subheaders
                  for w in col-widths
                  do (format stream "~VA  " w type-str))
            (format stream "~%")
            
            ;; Print Data
            (dotimes (i display-rows)
              (loop for col in col-data
                    for w in col-widths
                    do (format stream "~VA  " w (format-cell (aref col i))))
              (format stream "~%"))
            
            (when (> nrows display-rows)
              (format stream "... with ~D more rows~%" (- nrows display-rows))))))))

(defun glimpse (tbl &optional (stream *standard-output*))
  "Print a transposed summary of the tibble."
  (let ((nrows (tbl-nrows tbl))
        (names (tbl-names tbl)))
    (format stream "Rows: ~D~%" nrows)
    (format stream "Columns: ~D~%" (length names))
    (loop for name across names
          do (let* ((col (gethash name (tbl-columns tbl)))
                    (type (vec-type-abbrev col))
                    (preview (with-output-to-string (s)
                               (format s "")
                               (dotimes (i (min 5 (length col)))
                                 (format s "~A, " (format-cell (aref col i)))))))
               (format stream "$ ~A ~A ~A...~%" name type preview)))))
