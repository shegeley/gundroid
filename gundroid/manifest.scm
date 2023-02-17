(use-modules
 (gundroid utils)
 (gundroid packages studio))

(specifications->manifest
 (studio-specifications
  (assoc-ref studio-versioning "2022.1.1.19")))
