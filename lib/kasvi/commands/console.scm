

;; -*- coding: utf-8 -*-

(define-module kasvi.commands.console
  (export console)
  (use kasvi)
  (use file.util)
  (use util.list)
  (use text.tree)
  (use util.match)
  (use gauche.parseopt)
  (use gauche.process))
(select-module kasvi.commands.console)



(define (console)
  (if (find-file-in-paths "rlwrap")
  (run-process `(rlwrap gosh -Ilib) :wait #t)
  (run-process `(gosh -Ilib) :wait #t)
  )  
  )

