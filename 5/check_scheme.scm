#lang scheme
; check_scheme.scm
; Glenn G. Chappell
; 2020-03-24
;
; For CS F331 / CSCE A331 Spring 2020
; A Scheme Program to Run
; Used in Assignment 5, Exercise A


; Useful Functions

(define (a x y)
  (if (null? x)
      y
      (cons (car x) (a (cdr x) y)))
  )

(define (aa . xs)
  (if (null? xs)
      '()
      (a (car xs) (apply aa (cdr xs)))
      )
  )

(define (m d ns)
  (if (null? ns)
      '()
      (let ([n (+ d (car ns))])
        (cons (integer->char n) (m n (cdr ns))))
      )
  )

(define (mm ns) (list->string (m 0 ns)))


; Data

(define cds1 '(84 20 -3 -69 78 -13 17 5))
(define cds2 '(-15 -7 11 -76 66 -1 2 12))
(define cds3 '(-1 5 -83 65 19 -84 77 -4))
(define cds4 '(-5 10 -5 -2 1 12 -70))


; Output

(display "Secret message #4:\n\n")
(display (mm (aa cds1 cds2 cds3 cds4)))
(display "\n")

