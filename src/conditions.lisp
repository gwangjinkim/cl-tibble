(in-package :cl-tibble)

(define-condition tibble-error (error)
  ()
  (:documentation "Base condition for all cl-tibble errors."))

(define-condition column-length-error (tibble-error)
  ((column :initarg :column :reader error-column)
   (length :initarg :length :reader error-length)
   (expected-length :initarg :expected-length :reader error-expected-length))
  (:report (lambda (condition stream)
             (format stream "tibble: Column ~S has length ~A but expected ~A."
                     (error-column condition)
                     (error-length condition)
                     (error-expected-length condition))))
  (:documentation "Signaled when a column does not match the expected row count."))

(define-condition duplicate-column-error (tibble-error)
  ((name :initarg :name :reader error-name))
  (:report (lambda (condition stream)
             (format stream "tibble: Duplicate column name: ~S."
                     (error-name condition))))
  (:documentation "Signaled when column names are not unique."))

(define-condition unknown-column-error (tibble-error)
  ((name :initarg :name :reader error-name))
  (:report (lambda (condition stream)
             (format stream "tibble: Column not found: ~S."
                     (error-name condition))))
  (:documentation "Signaled when a requested column does not exist."))

(define-condition simple-tibble-error (tibble-error simple-error)
  ()
  (:documentation "Simple error wrapper for format strings."))

(defun tibble-error (format-control &rest format-arguments)
  (error 'simple-tibble-error
         :format-control format-control
         :format-arguments format-arguments))
