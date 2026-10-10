(in-package :cl-tibble)

(defclass %null-column () ())
(defvar *null-column* (make-instance '%null-column))
(defun null-column ()
  "R: base::NULL. Return the explicit NULL marker, distinct from scalar NIL (logical FALSE).
Use this marker when a constructor/coercion must receive R NULL rather than FALSE."
  *null-column*)

(defclass %constructor-options ()
  ((rows :initarg :rows :reader %options-rows)
   (rows-p :initarg :rows-p :reader %options-rows-p)
   (name-repair :initarg :name-repair :reader %options-name-repair)))
(defun constructor-options (&key (rows nil rows-p) (name-repair :check-unique))
  "R: tibble::tibble() options. Create explicit controls for a leading TIBBLE argument.
ROWS sets/checks row count; NAME-REPAIR selects R name repair. This preserves
legacy flat column keys named rows or name-repair."
  (make-instance '%constructor-options :rows rows :rows-p rows-p :name-repair name-repair))

(defclass %computed-column ()
  ((function :initarg :function :reader %computed-function)))

(defun computed-column (function)
  "R: tibble::tibble() sequential expressions. Delay FUNCTION until prior columns exist.
FUNCTION receives a partial tibble, whose columns retain C2 types and names.
This additive wrapper leaves TIBBLE callable via APPLY and FUNCALL."
  (unless (functionp function) (tibble-error "tibble: computed column requires a function."))
  (make-instance '%computed-column :function function))

(defun %tb-name (name)
  (cond ((stringp name) name) ((symbolp name) (string-downcase (symbol-name name)))
        ((na-p name) "") (t (format nil "~A" name))))

(defun %tb-size (x &optional list-column)
  (cond ((typep x 'tbl) (tbl-nrows x))
        ((and (arrayp x) (> (array-rank x) 1)) (array-dimension x 0))
        ((and (column-p x) (or list-column (not (listp x)))) (col-length x))
        (t 1)))

(defun %tb-column (x &optional list-column)
  (cond ((or (typep x 'tbl) (and (arrayp x) (> (array-rank x) 1)))
         (tibble-error "tibble: nested tibble and matrix columns require an owner-preserving C2 protocol."))
        ((and (consp x) list-column) (make-typed-column (coerce x 'vector) :list))
        ((%column-input-p x) x)
        (t (restore-column (vector x) (vec-prototype (vector x))))))

(defun %tb-recycle (column size)
  (recycle-to column size))

(defun %tb-row-count (columns rows rows-p)
  (when rows-p
    (unless (and (integerp rows) (>= rows 0))
      (tibble-error "tibble: row count must be a non-negative integer.")))
  (let ((size (if rows-p rows (if columns 1 0))))
    (unless rows-p
      (dolist (column columns)
        (let ((n (%tb-size column)))
          (unless (= n 1)
            (if (= size 1) (setf size n)
                (unless (= n size) (tibble-error "tibble: incompatible column sizes ~A and ~A." size n)))))))
    (dolist (column columns)
      (unless (or (= (%tb-size column) size) (= (%tb-size column) 1))
        (tibble-error "tibble: incompatible size ~A for ~A rows." (%tb-size column) size))) size))

(defun %tb-syntactic-name (name)
  ;; Native spelling of vctrs universal repair. Retain Unicode letters.
  (let* ((n (length name))
         (s (map 'string (lambda (c) (if (or (alphanumericp c) (find c "._")) c #\.)) name)))
    (cond ((zerop n) "")
          ((or (digit-char-p (char s 0)) (char= (char s 0) #\_)
               (and (> n 1) (char= (char s 0) #\.) (digit-char-p (char s 1))))
           (concatenate 'string (if (digit-char-p (char s 0)) ".." ".") s))
          ((member s '("if" "else" "repeat" "while" "function" "for" "in" "next" "break"
                        "TRUE" "FALSE" "NULL" "Inf" "NaN" "NA" "NA_integer_" "NA_real_"
                        "NA_complex_" "NA_character_") :test #'equal)
           (concatenate 'string "." s))
          (t s))))

(defun %tb-name-base (name)
  (let ((end (length name)))
    (loop while (and (> end 0) (digit-char-p (char name (1- end)))) do (decf end))
    (if (and (< end (length name)) (>= end 3) (string= name "..." :start1 (- end 3) :end1 end))
        (subseq name 0 (- end 3)) name)))

(defun %tb-bad-name-p (name)
  (or (zerop (length name)) (string= name "...")
      (and (> (length name) 2) (string= name ".." :end1 2)
           (every #'digit-char-p (subseq name 2)))))

(defun %tb-repair-names (names repair)
  (let* ((names (map 'vector (lambda (name) (if (na-p name) "" (%tb-name name))) names))
         (mode (if (stringp repair) (intern (string-upcase (substitute #\- #\_ repair)) :keyword) repair)))
    (when (functionp mode)
      (let ((result (funcall mode (copy-seq names))))
        (unless (and (typep result 'sequence) (= (length result) (length names)) (every #'stringp result))
          (tibble-error "tibble: custom name repair must return one string per column."))
        (return-from %tb-repair-names (coerce result 'vector))))
    (when (eq mode :legacy-unique)
      (let ((seen (make-hash-table :test 'equal)))
        (loop for name across names do
          (when (gethash name seen) (error 'duplicate-column-error :name name))
          (setf (gethash name seen) t)))
      (return-from %tb-repair-names names))
    (unless (member mode '(:check-unique :minimal :unique :universal :unique-quiet :universal-quiet))
      (tibble-error "tibble: unknown name repair ~S." repair))
    (when (eq mode :minimal) (return-from %tb-repair-names names))
    (when (eq mode :check-unique)
      (let ((seen (make-hash-table :test 'equal)))
        (loop for name across names do
          (when (or (%tb-bad-name-p name) (gethash name seen))
            (tibble-error "tibble: names must be nonempty and unique: ~S." name))
          (setf (gethash name seen) t)))
      (return-from %tb-repair-names names))
    (setf names (map 'vector (lambda (name)
                              (let ((base (%tb-name-base name)))
                                (when (%tb-bad-name-p base) (setf base ""))
                                (if (member mode '(:universal :universal-quiet)) (%tb-syntactic-name base) base))) names))
    (let ((counts (make-hash-table :test 'equal)))
      (loop for name across names do (incf (gethash name counts 0)))
      (map 'vector (lambda (name i)
                     (if (or (zerop (length name)) (> (gethash name counts) 1))
                         (format nil "~A...~D" name (1+ i)) name))
           names (coerce (loop for i below (length names) collect i) 'vector)))))

(defun %tb-options (arguments keys)
  (unless (evenp (length arguments)) (tibble-error "tibble: names and values must occur in pairs."))
  (let (pairs options)
    (loop for (key value) on arguments by #'cddr do
      (if (member key keys) (setf (getf options key) value)
          (push (cons (%tb-name key) value) pairs)))
    (values (nreverse pairs) options)))

(defun %tb-build (pairs &key rows rows-p (name-repair :check-unique) (row nil) list-column)
  (let ((names nil) (columns nil))
    (dolist (pair pairs)
      (let* ((raw (cdr pair))
             (input (if (typep raw '%computed-column)
                        (funcall (%computed-function raw)
                                 (%tb-build (loop for name in names for column in columns collect (cons name column))
                                            :name-repair :minimal)) raw)))
        (unless (typep input '%null-column)
          (let ((column (cond ((and row (not (or (column-p input) (typep input 'tbl) (arrayp input)
                                                 (numberp input) (stringp input) (na-p input) (eq input t))))
                              (make-typed-column (vector input) :list))
                             ((functionp input) (tibble-error "tibble: columns must be vectors."))
                             (t (%tb-column input list-column)))))
            (when (and row (/= (%tb-size column) 1))
              (tibble-error "tibble: row columns must have size one."))
            (setf names (append names (list (car pair))) columns (append columns (list column)))))))
    (let ((size (if row 1 (%tb-row-count columns rows rows-p))))
      (%allocate-tbl (%tb-repair-names names name-repair)
                     (map 'vector (lambda (column) (%tb-recycle column size)) columns) size))))

(defun tibble (&rest key-values)
  "R: tibble::tibble(). Build columns from flat name/value pairs, recycling size one.
A leading CONSTRUCTOR-OPTIONS object supplies R :ROWS and :NAME-REPAIR controls;
flat keys named rows/name-repair remain ordinary columns. Default name handling
retains legacy unique-name checks. Lists retain their legacy scalar-cell meaning;
explicit typed :LIST vectors provide R list columns. COMPUTED-COLUMN delays
an expression until preceding columns exist; TIBBLE* provides lexical syntax."
  (let ((controls (when (typep (first key-values) '%constructor-options) (pop key-values))))
    (%tb-build (nth-value 0 (%tb-options key-values nil))
               :rows (when controls (%options-rows controls))
               :rows-p (and controls (%options-rows-p controls))
               :name-repair (if controls (%options-name-repair controls) :legacy-unique))))

(defun tibble-row (&rest key-values)
  "R: tibble::tibble_row(). Construct exactly one row from flat name/value pairs.
Columns must have size one. Non-column objects become list cells. Sequential
COMPUTED-COLUMN callbacks and the TIBBLE name-repair strategies are supported."
  (multiple-value-bind (pairs options) (%tb-options key-values '(:name-repair))
    (%tb-build pairs :row t :list-column t :name-repair (getf options :name-repair :check-unique))))

(defvar *tb-attributes* (trivial-garbage:make-weak-hash-table :test 'eq :weakness :key))
(defun tbl-attribute (table name &optional default)
  "R: attr(x, name). Read an attribute stored by NEW-TIBBLE :ATTRIBUTES.
Attribute metadata is separate from columns; absent attributes return DEFAULT."
  (let ((entry (assoc (%tb-name name) (gethash table *tb-attributes*) :test #'equal)))
    (if entry (cdr entry) default)))

(defvar *tb-matrix-metadata* (trivial-garbage:make-weak-hash-table :test 'eq :weakness :key))

(defun %tb-matrix-columns (matrix names prototype)
  (loop for j below (array-dimension matrix 1) collect
    (cons (aref names j)
          (restore-column (coerce (loop for i below (array-dimension matrix 0) collect (aref matrix i j)) 'vector)
                          (vec-prototype prototype)))))

(defgeneric as-tibble (x)
  (:documentation "R: tibble::as_tibble(). Coerce X while preserving the original one-argument extension generic.
Use AS-TIBBLE-OPTIONS for additive name repair and explicit row-count options."))
(defmethod as-tibble ((x tbl)) x)
(defmethod as-tibble ((x list)) (as-tibble-options x))
(defmethod as-tibble ((x t)) (as-tibble-options x))

(defgeneric as-tibble-options (x &key rows name-repair rownames column-names)
  (:documentation "R: tibble::as_tibble(). Coerce columns, atomic vectors or rank-two matrices.
:ROWS checks or supplies rows; :NAME-REPAIR controls names. :COLUMN-NAMES is
an additive matrix adapter. Legacy alist/plist inputs remain accepted."))

(defmethod as-tibble-options ((x tbl) &key (rows nil rows-p) (name-repair :check-unique) rownames column-names)
  (declare (ignore rownames column-names))
  (if (and (not rows-p) (eq name-repair :check-unique)) x
      (%tb-build (loop for name across (tbl-names x) for i from 0 collect (cons name (%tbl-column-at x i)))
                 :rows rows :rows-p rows-p :name-repair name-repair)))

(defmethod as-tibble-options ((x list) &key (rows nil rows-p) (name-repair :check-unique) rownames column-names)
  (declare (ignore rownames column-names))
  (%tb-build (cond ((null x) nil)
                   ((consp (first x))
                    ;; Existing alist columns use vector semantics, unlike plist/TIBBLE list cells.
                    (mapcar (lambda (pair)
                              (cons (car pair) (if (listp (cdr pair)) (as-col (cdr pair)) (cdr pair)))) x))
                   (t (nth-value 0 (%tb-options x nil))))
             :rows rows :rows-p rows-p :name-repair name-repair))

(defmethod as-tibble-options ((x t) &key (rows nil rows-p) (name-repair nil repair-p) rownames column-names)
  (declare (ignore rownames))
  (cond ((and (arrayp x) (= (array-rank x) 2))
         (let* ((metadata (gethash x *tb-matrix-metadata*))
                (names (or column-names (first metadata)))
                (proto (or (second metadata)
                           (col-type (coerce (loop for i below (array-total-size x) collect (row-major-aref x i)) 'vector)))))
           (unless names
             (unless repair-p (warn 'cl-vctrs-lite:tidy-warning))
             (setf names (if repair-p (make-array (array-dimension x 1) :initial-element "")
                             (coerce (loop for i from 1 to (array-dimension x 1) collect (format nil "V~D" i)) 'vector))))
           (unless (= (length names) (array-dimension x 1)) (tibble-error "tibble: matrix names must match column count."))
           (%tb-build (%tb-matrix-columns x (coerce names 'vector) proto)
                      :rows (if rows-p rows (array-dimension x 0)) :rows-p t
                      :name-repair (or name-repair :check-unique))))
        ((and (%column-input-p x) (eq (col-type x) :list))
         (let ((names (col-names x)))
           (unless (or names (= (col-length x) 0)) (tibble-error "tibble: list columns require names."))
           (%tb-build (loop for i below (col-length x) collect (cons (aref names i) (col-ref x i)))
                      :rows rows :rows-p rows-p :name-repair (or name-repair :check-unique))))
        (t (%tb-build (list (cons "value" x)) :rows rows :rows-p rows-p
                      :name-repair (or name-repair :check-unique)))))

(defun %tb-vector-input (x &key force-list nil-is-false)
  (cond ((and x (named-list-p x))
         (let ((out (make-typed-column (map 'vector #'cdr x) :list)))
           (setf (col-names out) (map 'vector #'car x)) out))
        ((null x) (make-typed-column (if nil-is-false #(nil) #()) :bool))
        ((typep x '%null-column) (make-typed-column #() :bool))
        ((and (listp x) force-list) (make-typed-column (coerce x 'vector) :list))
        ((%column-input-p x) x)
        ((listp x) (coerce x 'vector))
        (t (%tb-column x))))

(defun as-tibble-col (x &key (column-name "value"))
  "R: tibble::as_tibble_col(). Convert X into a single column named COLUMN-NAME.
Plain nonempty lists become typed list columns; vector prototypes, owners and inner names survive.
Scalar NIL is FALSE; NULL-COLUMN explicitly represents R NULL."
  (unless (and (stringp column-name) (> (length column-name) 0))
    (tibble-error "tibble: column-name must be a nonempty string."))
  (when (typep x '%null-column) (return-from as-tibble-col (%allocate-tbl #() #() 0)))
  (let ((column (%tb-vector-input x :force-list t :nil-is-false t)))
    (%allocate-tbl (vector column-name) (vector column) (col-length column))))

(defun as-tibble-row (x &key (name-repair :check-unique))
  "R: tibble::as_tibble_row(). Split a named vector or list into one row.
Names become column names. Every list element must have size one; atomic
columns retain prototypes, including empty and all-missing input."
  (when (typep x '%null-column) (tibble-error "tibble: as-tibble-row requires a vector."))
  (let* ((vector (%tb-vector-input x :force-list t :nil-is-false t)) (names (col-names vector))
         (listp (eq (col-type vector) :list)))
    (when (and listp (some (lambda (x) (or (null x) (typep x '%null-column))) (col->list vector)))
      (tibble-error "tibble: as-tibble-row list elements must have size one."))
    (%tb-build
     (loop for i below (col-length vector) collect
       (cons (if names (aref names i) "")
             (if listp (col-ref vector i)
                 (let ((cell (col-subseq vector (vector i)))) (setf (col-names cell) nil) cell))))
     :row t :name-repair name-repair :list-column listp)))

(defun new-tibble (x &key (nrow nil nrow-p) (class 'tbl) subclass attributes)
  "R: tibble::new_tibble(). Allocate a named column list with minimal checks.
NROW is inferred from the first column, or supplied explicitly. Lengths are
checked only by VALIDATE-TIBBLE. CLASS is a defined CLOS subclass of TBL;
SUBCLASS is a deprecated alias. Duplicate names retain positional access."
  (when subclass (warn 'cl-vctrs-lite:tidy-warning) (setf class subclass))
  (let ((pairs (cond ((typep x 'tbl)
                     (loop for name across (tbl-names x) for i from 0 collect (cons name (%tbl-column-at x i))))
                    ((and (listp x) (or (null x) (named-list-p x))) x)
                    ((and (%column-input-p x) (eq (col-type x) :list) (col-names x))
                     (loop for i below (col-length x) collect (cons (aref (col-names x) i) (col-ref x i))))
                    (t (tibble-error "tibble: new-tibble requires a named list.")))))
    (unless (and (find-class class nil) (nth-value 0 (subtypep class 'tbl)))
      (tibble-error "tibble: class must be a defined subclass of tbl."))
    (let* ((columns (map 'vector (lambda (pair)
                                   (let ((input (cdr pair)))
                                     (if (or (null input) (functionp input) (typep input '%null-column)) input
                                         (%tb-column input t)))) pairs))
           (size (if nrow-p nrow (if pairs (if (or (null (aref columns 0)) (typep (aref columns 0) '%null-column)) 0 (%tb-size (aref columns 0))) 0))))
      (unless (and (integerp size) (>= size 0)) (tibble-error "tibble: nrow must be a nonnegative integer."))
      (let ((result (%allocate-tbl (map 'vector #'car pairs) columns size class)))
        (setf (gethash result *tb-attributes*) (copy-tree attributes)) result))))

(defun validate-tibble (x)
  "R: tibble::validate_tibble(). Check minimal names, vector columns and compatible sizes.
Every column must match the recorded row count. Return X unchanged."
  (unless (typep x 'tbl) (tibble-error "tibble: validation requires a tibble."))
  (unless (every #'stringp (tbl-names x)) (tibble-error "tibble: names must be minimal strings."))
  (let ((columns (loop for i below (length (tbl-names x)) collect (%tbl-column-at x i))))
    (dolist (column columns)
      (unless (and column (column-p column) (not (listp column)))
        (tibble-error "tibble: columns must be vectors.")))
    (dolist (column columns)
      (unless (= (%tb-size column) (tbl-nrows x))
        (tibble-error "tibble: column sizes must equal the row count.")))) x)

(defun is-tibble (x)
  "R: tibble::is_tibble(). True for TBL objects and their CLOS subclasses."
  (typep x 'tbl))

(defun %tb-row-layout (arguments)
  (let (names (data arguments))
    (if (and data (vectorp (first data)) (every #'stringp (first data)))
        (setf names (coerce (pop data) 'list))
        (progn (loop while (and data (or (keywordp (first data)) (stringp (first data))))
                     do (push (%tb-name (pop data)) names)) (setf names (nreverse names))))
    (unless names (tibble-error "tibble: row-wise construction requires column headers."))
    (unless (zerop (mod (length data) (length names)))
      (tibble-error "tibble: data length must be a multiple of the column count."))
    (values names data)))

(defun %tb-tribble-column (cells)
  (if (some (lambda (x) (or (listp x) (and (%column-input-p x)
                                         (or (/= (col-length x) 1) (eq (col-type x) :list)))))
            (remove nil cells))
      (make-typed-column (coerce cells 'vector) :list)
      (let* ((columns (mapcar #'%tb-column cells))
             (prototype (if columns
                            (reduce #'common-prototype (cdr columns) :initial-value (vec-prototype (first columns)))
                            (vec-prototype :bool))))
        (when (cl-vctrs-lite::%prototype-unspecified prototype) (setf prototype (vec-prototype :bool)))
        (restore-column (coerce (loop for column in columns append (col->list (vec-cast column prototype))) 'vector) prototype))))

(defun tribble (&rest args)
  "R: tibble::tribble(). Construct rows after keyword/string column headers.
An explicit vector of header strings avoids ambiguity with initial string cells.
Atomic cells use strict common types; nonscalar cells become list columns."
  (when (null args) (return-from tribble (tibble)))
  (multiple-value-bind (names data) (%tb-row-layout args)
    (%allocate-tbl (%tb-repair-names names :check-unique)
                   (coerce (loop for j below (length names) collect
                             (%tb-tribble-column (loop for i from j below (length data) by (length names) collect (nth i data)))) 'vector)
                   (/ (length data) (length names)))))

(defun %tb-character (x)
  (cond ((na-p x) *na*) ((stringp x) x) ((eq x t) "TRUE") ((null x) "FALSE")
        ((integerp x) (format nil "~D" x))
        ((floatp x) (let ((str (format nil "~,15F" x))) (string-right-trim "." (string-right-trim "0" str))))
        (t (tibble-error "tibble: cannot format value as a character cell."))))

(defun %tb-matrix-cell (input)
  "Normalize a scalar atomic owner, preserving typed missing values."
  (when (or (consp input) (typep input '%null-column))
    (tibble-error "tibble: frame-matrix cells must be atomic scalars."))
  (let ((column (%tb-column input)))
    (unless (and (= (col-length column) 1) (member (col-type column) '(:int :double :bool :string :any)))
      (tibble-error "tibble: frame-matrix cells must be atomic scalars."))
    column))

(defun frame-matrix (&rest args)
  "R: tibble::frame_matrix(). Build a rank-two array from header names and row cells.
Use an explicit header vector for leading string cells. Return the matrix,
column-name vector and type keyword as three values. Scalar atomic C2 columns
retain typed NA prototypes. Base logical/integer/double/character promotion is
supported; character coercion of arbitrary floating-point values remains partial."
  (when (null args)
    (let ((matrix (make-array '(0 0))))
      (setf (gethash matrix *tb-matrix-metadata*) (list nil :bool))
      (return-from frame-matrix (values matrix nil :bool))))
  (multiple-value-bind (names data) (%tb-row-layout args)
    (let* ((columns (mapcar #'%tb-matrix-cell data))
           (type (reduce (lambda (a b)
                           (cond ((or (eq a :string) (eq b :string)) :string)
                                 ((eq a :any) b) ((eq b :any) a)
                                 (t (common-type a b))))
                         (mapcar #'col-type columns) :initial-value :any))
           (type (if (eq type :any) :bool type))
           (matrix (make-array (list (/ (length data) (length names)) (length names))))
           (column-names (coerce names 'vector)))
      (loop for column in columns for i from 0 do
        (setf (row-major-aref matrix i)
              (if (eq type :string) (%tb-character (col-ref column 0))
                  (col-ref (vec-cast column type) 0))))
      (setf (gethash matrix *tb-matrix-metadata*) (list column-names type))
      (values matrix (copy-seq column-names) type))))

(defun enframe (x &key (name "name") (value "value") list-column)
  "R: tibble::enframe(). Convert a vector or named list to name/value columns.
Inner names become the name column; unnamed entries use positions 1 through N.
LIST-COLUMN opts plain proper lists into R list semantics; their legacy atomic
interpretation otherwise remains. NAME NIL omits the name column."
  (unless (and (stringp value) (> (length value) 0)) (tibble-error "tibble: value must be a column name."))
  (let* ((column (%tb-vector-input x :force-list list-column))
         (len (col-length column))
         (names (col-names column))
         (values (col-subseq column (coerce (loop for i below len collect i) 'vector))))
    (setf (col-names values) nil)
    (if name
        (%tb-build (list (cons (%tb-name name) (if names (make-typed-column names :string)
                                                  (make-typed-column (coerce (loop for i from 1 to len collect i) 'vector) :int)))
                         (cons value values)))
        (%tb-build (list (cons value values))))))

(defun %tb-pack-list (values names)
  (cond ((null names) values)
        ((and (> (length names) 0) (every #'stringp names)) (map 'list #'cons names values))
        (t (let ((result (make-typed-column (coerce values 'vector) :list)))
             (setf (col-names result) names) result))))

(defun deframe (x &key named-vector)
  "R: tibble::deframe(). Extract one column, or key/value pairs from two columns.
The legacy default returns atomic vectors for one column and alists for two.
:NAMED-VECTOR T opts into R atomic names/prototypes and D12 list representations."
  (unless (typep x 'tbl) (tibble-error "tibble: deframe requires a tibble."))
  (let ((ncols (length (tbl-names x))))
    (when (> ncols 2) (warn 'cl-vctrs-lite:tidy-warning) (setf ncols 2))
    (unless (member ncols '(1 2)) (tibble-error "tibble: deframe requires one or two columns."))
    (let* ((column (%tbl-column-at x (1- ncols)))
           (names (when (= ncols 2) (map 'vector #'%tb-character (col->list (%tbl-column-at x 0))))))
      (if named-vector
          (if (eq (col-type column) :list) (%tb-pack-list (col->list column) names)
              (let ((result (col-subseq column (coerce (loop for i below (col-length column) collect i) 'vector))))
                (setf (col-names result) names) result))
          (if (= ncols 1) column
              (loop for i below (tbl-nrows x) collect (cons (col-ref (%tbl-column-at x 0) i) (col-ref column i))))))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun %tb-expression-name (form)
    (if (symbolp form) (string-downcase (symbol-name form))
        (let ((*print-case* :downcase) (*print-pretty* nil)) (prin1-to-string form))))
  (defun %tb-binding-symbol (name forms)
    (labels ((walk (form)
               (cond ((and (symbolp form) (not (keywordp form))
                           (string-equal (symbol-name form) name)) form)
                     ((consp form) (or (walk (car form)) (walk (cdr form)))))))
      (or (walk forms) (intern (string-upcase name) *package*))))
  (defun %tb-entry (form)
    (if (and (consp form) (or (keywordp (first form)) (stringp (first form))) (= (length form) 2))
        (values (%tb-name (first form)) (second form) (eq (first form) :splice))
        (values (%tb-expression-name form) form nil))))

(defmacro lst (&rest forms)
  "R: tibble::lst(). Build a named list with sequential lexical entries.
(:NAME expression) binds NAME for later entries. Unnamed expressions use their
readable Lisp form as the name. (:SPLICE expression) inserts a named list.
D12 returns alists, with a typed :LIST vector for the explicitly named empty."
  (let ((result (gensym "ENTRIES")))
    (labels ((expand (remaining)
               (if (null remaining)
                   `(%tb-pack-list (mapcar #'cdr ,result) (map 'vector #'car ,result))
                   (multiple-value-bind (name expression splice) (%tb-entry (first remaining))
                     (if splice
                         `(let ((entries ,expression))
                            (unless (named-list-p entries) (tibble-error "tibble: splice requires a named list."))
                            (setf ,result (append ,result entries)) ,(expand (rest remaining)))
                         (let ((binding (if (or (symbolp (first remaining))
                                               (and (consp (first remaining)) (keywordp (caar remaining))))
                                            (%tb-binding-symbol name forms) (gensym "VALUE"))))
                           `(let ((,binding ,expression))
                              (setf ,result (append ,result (list (cons ,name ,binding))))
                              ,(expand (rest remaining)))))))))
      `(let ((,result nil)) ,(expand forms)))))

(defmacro tibble* (&rest forms)
  "R: tibble::tibble() lexical syntax. Expand paired entries into callable TIBBLE.
(:NAME expression) can refer to preceding names as C2 column vectors. Unnamed
expressions receive readable Lisp labels. No runtime EVAL is performed."
  (let ((controls (when (and (consp (first forms)) (eq (caar forms) 'constructor-options)) (pop forms)))
        arguments previous)
    (dolist (form forms)
      (multiple-value-bind (name expression splice) (%tb-entry form)
        (when splice (error "tibble: use AS-TIBBLE for spliced column lists."))
        (let ((table (gensym "TABLE")))
          (setf arguments
                (append arguments (list name `(computed-column
                                              (lambda (,table)
                                                (declare (ignorable ,table))
                                                (with-tibble (,table ,@previous) ,expression)))))))
        (when (and (consp form) (keywordp (first form)))
          (push (%tb-binding-symbol name forms) previous))))
    `(tibble ,@(when controls (list controls)) ,@arguments)))
