;; (define x 1);

;; (if
;;  (> x 0)
;;  (display "P")
;;  (if
;;   (= x 0)
;;   (display "N")
;;   (display "Z")))

;; (display "this works as expected")
;; (display "but you cant write it as a function...")


;; (define (three-state x pos-body eq-body neg-body)
;;   (if > x 0)
;;   (pos-body)
;;   (if
;;    (= x 0)
;;    (eq-body)
;;    (neg-body)))


; !!!!!!!!!!!!! you can comment this in
; (three-state 1 (display "P") (display "N") (display "Z"))
; First of all you will notice that P N and Z are printed
; the result of the invocation will be passed into your fuction
;;; not sure if this is schemeish that (display "N") returns a bool
; if we need to pass in the body itself / not its result
; we need a macro

(define x  2)
(define y  -1)
;; (define e  1)
(define-syntax three-state-macro
  (syntax-rules (ignore e)
    (
     (_ x ignore e pos-body eq-body neg-body)
     (if (> x 0) pos-body (if (= x 0) eq-body neg-body ))
    )
  )
)
(three-state-macro y ignore e (display "P") (display "N") (display "Z"))

