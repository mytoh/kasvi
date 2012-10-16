
;; -*- coding: utf-8 -*-

(define-module kasvi.commands.generate
  (export generate-lehti)
  (use file.util)
  (use util.list)
  (use text.tree)
  (use util.match)
  (use gauche.parseopt)
  (use gauche.process))
(select-module kasvi.commands.generate)


(define (dir-spec name cmds :optional bin)
  (if bin
  `(,name
     ((readme.rst ,(gen-file 'readme-rst))
      ,(path-swap-extension name "leh")
      (bin ((,name ,(gen-file 'bin))))
      (lib
        ((,(path-swap-extension name "scm") ,(gen-file 'lib))
         (,name ((core.scm ,(gen-file 'lib-core))
                 (cli.scm ,(gen-file 'lib-cli))
                 (commands ,(if (null? cmds)
                              (command-list '("help") make-lib-commands-list)
                              (command-list cmds make-lib-commands-list)))
                 (commands.scm ,(gen-file 'lib-commands))))))))
  `(,name
     ((readme.rst ,(gen-file 'readme-rst))
      ,(path-swap-extension name "leh")
      (lib
        ((,(path-swap-extension name "scm") ,(gen-file 'lib))
         (,name ((core.scm ,(gen-file 'lib-core))
                 )))))))
  )

(define (gen-file command)
  (match command
    ('readme-rst gen-readme-rst)
    ('bin gen-bin)
    ('lib gen-lib)
    ('lib-commands gen-lib-commands)
    ('lib-core gen-lib-core)
    ('lib-cli gen-lib-cli)))


(define (make-lib-commands-list path)
  (let* ((cmd (sys-basename (path-sans-extension path)))
         (name (sys-basename (sys-dirname (sys-dirname path))))
         (module (string-append name ".commands." cmd)))
    (display
      (tree->string
        (intersperse
          "\n"
          `(,(string-append "(define-module " module)
             "  (use gauche.parseopt)"
             "  (use gauche.process)"
             "  (use util.match)"
             "  (use file.util)"
             "  )"
             ,(string-append "(select-module " module ")")))))))

(define (command-list lst proc)
  (map
    (lambda (e) (list (path-swap-extension e "scm") proc))
    lst))

(define (gen-lib path)
  (let* ((module (path-sans-extension (sys-basename path)))
         )
    (display
      (tree->string
        (intersperse
          "\n"
          `(,(string-append "(define-module " module)
             ,(string-append "(extend " module ".core)")
             "  )"
             ))))))

(define (gen-readme-rst path)
  (let* ((module (sys-basename (sys-dirname path))))
    (display
      (tree->string
        (string-join
          `(,module
             "======="
             )
          "\n"
          'suffix)))
    )
  )


(define (gen-lib-core path)
  (let* ((name (sys-basename (sys-dirname path)))
         (module (string-append name ".core")))
    (display
      (tree->string
        (intersperse
          "\n"
          `(,(string-append "(define-module " module)
             "  )"
             ,(string-append "(select-module " module ")")))))))

(define (gen-lib-cli path)
  (let* ((name (sys-basename (sys-dirname path)))
         (module (string-append name ".cli")))
    (display
      (tree->string
        (intersperse
          "\n"
          `(,(string-append "(define-module " module)
             "  (export runner)"
             "  (use gauche.parseopt)"
             "  (use util.match)"
             "  (use file.util)"
             ,(string-append "  (use " name ".core)")
             ,(string-append "  (use " name ".commands)")
             "  )"
             ,(string-append "(select-module " module ")")
             ""
             "(define runner"
             "  (lambda (args)"
             "    (let-args (cdr args)"
             "      ((#f \"h|help\" (exit 0))"
             "       . rest)"
             "      (when (null-list? rest)"
             "        (exit 0))"
             "      (match (car  rest)"
             "        ;; actions"
             "        (\"help\""
             "         (help))"
             "        (_ (exit 0))))))"
             ""))))))

(define (gen-lib-commands path)
  (let* ((name (sys-basename (sys-dirname path)))
         (module (string-append name ".commands")))
    (display
      (tree->string
        (intersperse
          "\n"
          `(,(string-append "(define-module " module)
             "  )"
             ,(string-append "(select-module " module ")")))))))

(define (gen-bin path)
  (let ((name (sys-basename path)))
    (display
      (tree->string
        (intersperse
          "\n"
          `(" \":\"; exec gosh -- $0 \"$@\""
            ""
            "(add-load-path \"../lib\" :relative)"
            ,(string-append "(use " name ".cli :prefix cli:)")
            ""
            "(define (main args)"
            "  (cli:runner args))"
            ""
            ";; vim:filetype=scheme"))))))

(define (message name)
  (print
    (string-append "created new app in: " name)))

(define (file->executable name)
  (let ((path (build-path (current-directory)
                          name "bin" name)))
    (if (file-exists? path)
      (run-process `(chmod +x ,path) :wait #t))
    ))

(define (git-init dir)
  (current-directory dir)
  (run-process '(git init) :wait #t))


(define (generate-lehti args)
  (let ((name (cadr args)))
    (let-args (cddr args)
      ((bin "b|bin")
       . cmds)
      (cond
        ((file-exists? name)
         (exit 1 "directory ~a exists!" name))
        (else
          (message name)
          (create-directory-tree
            (current-directory)
            (dir-spec name cmds bin))
          (file->executable name)
          (git-init name)))
      )))

(define (help status)
  (exit status "lehti generate: ~a <command> <package-name>\n" "lehti"))



