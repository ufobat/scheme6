(define fact (lambda (n) (if (<= n 1) 1 (* n (fact (- n 1))))))
(display (fact 10))
(display (fact 100))
