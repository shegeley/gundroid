(define-module (gundroid utils)

  #:use-module (guix gexp)

  #:use-module (srfi srfi-1)

  #:use-module (ice-9 match)

  #:export (specification->package-name
            fix ref-in interpose))

(define (alist? lst)
  (every pair? lst))

(define (ref-in x path)
  (match path
    ('() x)
    (else
     (ref-in (assoc-ref x (first path))
             (cdr path)))))

(define (specification->package-name x)
  (first (string-split x (char-set #\:))))

(define (fix . args)
  "Supposed to be called in the arguments field of a package with binary-build-system
   Symlinks the «old» directory inside package dir with «new» that's an input entry (string) of the current package
   args =: (what old new)"
  (with-imported-modules
      '((guix build utils)
        (ice-9 match))
    #~(begin
        (use-modules
         (guix build utils))

        (modify-phases
            %standard-phases
          #$@(map
              (match-lambda
                ((what old new)
                 (let* ((phase (symbol-append 'fix- what))
                        (prev-phase 'unpack))
                   #~(add-after
                         (quote #$prev-phase)
                         (quote #$phase)
                       (lambda* (#:key inputs
                                 #:allow-other-keys)

                         (delete-file-recursively #$old)
                         (symlink (assoc-ref inputs #$new) #$old)))))) args)))))
