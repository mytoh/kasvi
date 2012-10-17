
;; -*- coding: utf-8 -*-

(define-module kasvi.commands.generate.util
  (export create-directory-tree-with-colour)
  (use maali)
  (use file.util)
  (use util.list)
  (use text.tree)
  (use util.match)
  (use gauche.parseopt)
  (use gauche.process))
(select-module kasvi.commands.generate.util)

;; function from file.util

(define (create-directory-tree-with-colour start tree)
  (ensure start tree)
  )

(define (collect-options args)
  (let loop ([args args] [r '()])
    (match args
      [() (values (reverse r) #f)]
      [([? keyword? k] val . rest) (loop rest (list* val k r))]
      [(arg) (values (reverse r) arg)]
      [_ (error "invalid option list:" args)])))

(define (walk dir node do-file do-dir)
  (match node
    [[? name?] (do-file (mkpath dir node) #f)]
    [([? name? n] . args)
     (receive (opts content) (collect-options args)
       (if (list? content)
         (apply do-dir (mkpath dir n) content opts)
         (apply do-file (mkpath dir n) content opts)))]
    [_ (error "invalid tree node:" node)]))

(define (mkpath dir name) (build-path dir (x->string name)))
(define chown (cond-expand
                [gauche.sys.lchown sys-lchown]
                [else sys-chown]))
(define (name? x) (or (string? x) (symbol? x)))
(define (ensure dir node) (walk dir node ensure-file ensure-dir))
(define (ensure-file path content
                     :key (mode #f) (owner -1) (group -1) (symlink #f))
  (if symlink
    (sys-symlink symlink path)
    (touch-file/message path content))
  ;; NB: BSD systems has lchmod, so we may support :mode with :symlink
  ;; in future.
  (when (and mode (not symlink)) (sys-chmod path mode))
  (when (or (>= owner 0) (>= group 0)) (chown path owner group)))

(define (ensure-dir path children :key (mode #o755) (owner -1) (group -1))
  (make-directory* path mode)
  (for-each (cut ensure path <>) children)
  (when (or (>= owner 0) (>= group 0)) (sys-chown path owner group)))


(define (touch-file/message path content)
  (cond
    [(not content) (touch-file path)]
    [(string? content) (with-output-to-file path (cut display content))]
    [else (with-output-to-file path (cut content path))])
  (format #t "      ~a ~a\n"
          (paint "create" 192)
          (string-scan path (string-append (current-directory) "/") 'after)))
