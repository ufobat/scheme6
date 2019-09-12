(define number 20)
(define (count-to-one n)
  (
   (display (s6:depth))
   (if (<= n 1)
       1
       (count-to-one (- n 1))
       )
   ))
(count-to-one number)

