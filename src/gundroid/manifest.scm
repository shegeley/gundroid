(define-module (gundroid manifest)
  #:use-module (gundroid utils)
  #:use-module (gnu packages)
  #:use-module ((gundroid packages studio) #:prefix studio:))

(specifications->manifest
 (studio:specifications
  (assoc-ref studio:versioning "2022.1.1.19")))
