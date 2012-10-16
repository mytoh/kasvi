
(define-module kasvi.cli
  (export runner)
  (use gauche.parseopt)
  (use util.match)
  (use file.util)
  (use kasvi.commands)
  )
(select-module kasvi.cli)

(define runner
  (lambda (args)
    (let-args (cdr args)
      ((bin "b|bin")
       (#f "h|help" (exit 0))
       . rest)
      (match (car  rest)
        ;; actions
        ("leh"
         (generate-lehti rest))
        ((or "exec" "execute" "e")
         (execute rest))
        ((or "console" "c")
         (console ))
        (_ (exit 0))))))
