(define-module (gundroid packages build-tools)
  #:use-module (gnu)

  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)

  #:use-module (gnu packages compression) ;; unzip

  #:use-module (nonguix build-system binary)

  #:use-module (gundroid utils)

  #:use-module (srfi srfi-1)

  #:use-module (ice-9 match))

;; "https://dl.google.com/android/repository/build-tools_r34-rc1-linux.zip"

(define (uri-template version)
  (string-append "https://dl.google.com/android/repository/build-tools_r"
                 version "-linux.zip"))

(define build-tools-license
  ((@@ (guix licenses) license)
   "Android build-tools License"
   "https://developer.android.com/studio/releases/build-tools"
   ""))

(define versioning
  `(("33" .
     ((release-date . "08.2022")
      (hash . "0vpnj995yp0v6ywlacrxrvkc4a52lyilw8v34b9z5c37bg0nhpg0")))
    ("32" .
     ((release-date . "05.2022")
      (hash . "01zw70yvhdckd85a19jqibp7jbc27zkz1839av26rcs5fvy79p3i")))))

(define* (build-tools
          #:key (version "33"))
  ;; contains importand "aapt2", "zipalign" and "apksigner"
  ;; "aapt2" and "zipalign" needs to be patchelfed properly
  (package
   (name "android-build-tools")
   (version version)
   (source
    (origin
     (method url-fetch)
     (uri (uri-template version))
     (sha256
      (base32 (ref-in versioning
                      (list version 'hash))))))
   (native-inputs
    ;; "unzip" has to be in native inputs or will fail
    (list
     (specification->package "unzip")))
   (build-system binary-build-system)
   (arguments
    `(#:validate-runpath? #f))
   (supported-systems '("x86_64-linux"))
   (synopsis
    "Android SDK Build-Tools is a component of the Android SDK required for building Android apps.")
   (description
    "Android SDK Build-Tools is a component of the Android SDK required for building Android apps.")
   (home-page "https://developer.android.com")
   (license build-tools-license)))
