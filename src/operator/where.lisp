(in-package :cl-user)
(defpackage cl-reex.operator.where
  (:use :cl)
  (:import-from :cl-reex.observer
 		:observer
		:on-next
		:on-error
		:on-completed)
  (:import-from :cl-reex.observable
		:subscribe)
  (:import-from :cl-reex.macro.operator-table
		:get-operator-expander
		:set-operator-expander)
  (:import-from :cl-reex.macro.symbols
		:where )
  (:import-from :cl-reex.operator
		:operator
		:observable
		:predicate)
  (:export :operator-where
	   :make-operator-where))

(in-package :cl-reex.operator.where)


(defclass operator-where (operator)
  ((observable :initarg :observable
	       :accessor observable)
   (predicate :initarg :predicate
	      :accessor predicate)
   (observer :initarg :observer
	     :accessor observer) )
  (:documentation "Where operator"))

(defun make-operator-where (observable predicate)
  (let ((op (make-instance 'operator-where
		 :observable observable
		 :predicate predicate )))
    (setf (on-next op)
	  #'(lambda (x)
	      (when (funcall (predicate op) x)
	  	(funcall (on-next (observer op)) x) )))
    (setf (on-error op)
	  #'(lambda (x)
	      (funcall (on-error (observer op))) ))
    (setf (on-completed op)
	  #'(lambda ()
	      (funcall (on-completed (observer op))) ))
    op ))


(defmethod subscribe ((op operator-where) observer)
  (setf (observer op) observer)
  (subscribe (observable op) op) )

;;
;; in Let*-expr
;;    make definition like below
;;
;; (let* (...
;;        !! from HERE !!
;;        (var-name (rx:make-operator-where
;;                       temp-observable
;;                       #'(lambda (x) (evenp x)) ))
;;        !! to HERE   !!
;;        ...)
;;    ...)
;;
(set-operator-expander 'where
    #'(lambda (x var-name temp-observable)
	`(,var-name
	  (make-operator-where
	   ,temp-observable
	   #'(lambda ,(cadr x) ,(caddr x) )))))
