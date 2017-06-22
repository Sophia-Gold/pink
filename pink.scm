(define last-index
  (lambda (e env)
    (define iter
      (lambda (r i env)
        (if (null? env)
            (if (= r -1) (error 'last-index (format "unbound variable ~a" e)) r)
            (let ((new-r (if (eq? e (car env)) i r)))
              (iter new-r (+ i 1) (cdr env))))))
    (iter -1 0 env)))

(define trans
  (lambda (e env)
    (cond
      ((number? e) e)
      ((symbol? e) `(var ,(last-index e env)))
      (((tagged? 'quote) e) (cadr e))
      (((tagged? 'lambda) e) `(lambda ,(trans (cadddr e) (append env (list (cadr e) (caddr e))))))
      (((tagged? 'let) e) `(let ,(trans (caddr e) env) ,(trans (cadddr e) (append env (list (cadr e))))))
      ((and (pair? e) (member (car e) '(cadr caddr cadddr)))
       (let ((a (trans (cadr e) env)))
         (cond
           ((eq? (car e) 'cadr)   `(car (cdr ,a)))
           ((eq? (car e) 'caddr)  `(car (cdr (cdr ,a))))
           ((eq? (car e) 'cadddr) `(car (cdr (cdr (cdr ,a))))))))
      ((and (pair? e) (member (car e) '(if + - * eq? number? symbol? pair? code? cons car cdr run lift)))
       (cons (car e) (map (lambda (x) (trans x env)) (cdr e))))
      (else (map (lambda (x) (trans x env)) e)))))

(define pink-poly-src
'(lambda tie eval (lambda _ l (lambda _ exp (lambda _ env
  (if (number?             exp)    ((car l) exp)
  (if (symbol?             exp)    (env exp)
  (if (symbol?        (car exp))   
    (if (eq?  '+      (car exp))   (+   (((eval l) (cadr exp)) env) (((eval l) (caddr exp)) env))
    (if (eq?  '-      (car exp))   (-   (((eval l) (cadr exp)) env) (((eval l) (caddr exp)) env))
    (if (eq?  '*      (car exp))   (*   (((eval l) (cadr exp)) env) (((eval l) (caddr exp)) env))
    (if (eq?  'eq?    (car exp))   (eq? (((eval l) (cadr exp)) env) (((eval l) (caddr exp)) env))
    (if (eq?  'if     (car exp))   (if  (((eval l) (cadr exp)) env) (((eval l) (caddr exp)) env) (((eval l) (cadddr exp)) env))
    (if (eq? 'lambda (car exp)) ((car l) (lambda f x (((eval l) (cadddr exp))
      (lambda _ y (if (eq? y (cadr exp)) f (if (eq? y (caddr exp)) x (env y)))))))
    (if (eq?  'let    (car exp))   (let x (((eval l) (caddr exp)) env) (((eval l) (cadddr exp))
      (lambda _ y (if (eq?  y (cadr exp)) x (env y)))))
    (if (eq?  'lift   (car exp))   (lift (((eval l) (cadr exp)) env))
    (if (eq?  'number? (car exp))  (number? (((eval l) (cadr exp)) env))
    (if (eq?  'symbol? (car exp))  (symbol? (((eval l) (cadr exp)) env))
    (if (eq?  'car    (car exp))   (car  (((eval l) (cadr exp)) env))
    (if (eq?  'cdr    (car exp))   (cdr  (((eval l) (cadr exp)) env))
    (if (eq?  'cons   (car exp))   ((car l) (cons (((eval l) (cadr exp)) env) (((eval l) (caddr exp)) env)))
    (if (eq?  'quote  (car exp))   ((car l) (cadr exp))
    (if (eq?  'run    (car exp))   (run (((eval l) (cadr exp)) env) (((eval l) (caddr exp)) env))
    ((env (car exp)) (((eval l) (cadr exp)) env)))))))))))))))))
  ((((eval l) (car exp)) env) (((eval l) (cadr exp)) env)))))))))
)

(define pink-fac '((lambda f n (if n (* n (f (- n 1))) 1)) 4))

(define pink-tie-src
  `(lambda eval l (lambda _ e (((,pink-poly-src eval) l) e))))

(define pink-eval-src
  `(,pink-tie-src (cons (lambda _ e e) 0)))

(define pink-evalc-src
  `(,pink-tie-src (cons (lambda _ e (lift e)) 0)))

(define pink-eval-exp1
  (trans pink-eval-src '(arg1)))

(define pink-evalc-exp1
  (trans pink-evalc-src '(arg1)))
