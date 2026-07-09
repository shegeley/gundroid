(define-module (gundroid manifest)
  #:use-module ((gnu packages) #:select (specifications->manifest))
  #:use-module ((gundroid packages studio)
                #:select (specifications versioning)
                #:prefix studio:))

(specifications->manifest
 (studio:specifications
  (assoc-ref studio:versioning "2022.1.1.19")))
