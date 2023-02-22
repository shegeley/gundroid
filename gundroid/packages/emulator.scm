(define-module (gundroid packages emulator)
  #:use-module (gnu)

  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix gexp)

  #:use-module ((guix licenses) #:prefix license:)

  #:use-module (gnu packages compression) ;; unzip

  #:use-module (nonguix build-system binary)

  #:use-module (gundroid utils)

  #:use-module (srfi srfi-1)

  #:use-module (ice-9 match)

  #:export (emulator))

(define (uri-template build-id)
  (string-append "https://redirector.gvt1.com/edgedl/android/repository/emulator-linux_x64-" build-id ".zip"))

(define emulator-license
  ((@@ (guix licenses) license)
   "Android Emulator License" "https://cs.android.com/android/platform/superproject/+/master:prebuilts/android-emulator/NOTICE"
   ""))

(define versioning
  ;; https://developer.android.com/studio/emulator_archive
  `(("32.1.7" .
     ((build-id . "9278971")
      (release-date . "16.11.2022")
      (hash . "1xqj8y71h1bxlxh6jq0kplsqvl48y0ivyy1fspgf3la6myfl3zf6")))
    ("32.1.6" .
     ((build-id . "9242524")
      (release-date . "09.11.2022")
      (hash . "0pwz1y7s181dl6irr31fyxwnj2jbazijjz4hx1rwwax52s7kxxw6")))
    ("32.1.5" .
     ((build-id . "9192776")
      (release-date . "24.10.2022")
      (hash . "1ki9in24mpm4mxfkhbh48p4ww786vzh3y90ss24fnfafk8p6062x")))
    ("31.3.13" .
     ((build-id . "9189900")
      (release-date . "27.10.2022")
      (hash . "1ki9in24mpm4mxfkhbh48p4ww786vzh3y90ss24fnfafk8p6062x")))))

(define specifications
  '("openlibm"
    "pth"
    "which"
    "mesa"
    "bash"
    "coreutils"
    "vulkan-loader"
    "vulkan-headers"
    "vulkan-tools"
    "glibc"
    "gcc:lib"
    "ell"
    "libgccjit"
    "gperftools"
    "fontconfig"
    "freetype"
    "libcxx"
    "qemu"))

(define inputs
  (map specification->package+output
       specifications))

(define* (emulator #:key
                   (version "32.1.7")
                   (versioning versioning))
  (package
   (name "android-emulator")
   (version version)
   (source
    (origin
     (method url-fetch)
     (uri (uri-template (ref-in versioning
                                (list version 'build-id))))
     (sha256
      (base32 (ref-in versioning
                      (list version 'hash))))))
   (inputs inputs)
   (native-inputs
    ;; "unzip" has to be in native inputs or will fail
    (list
     (specification->package "unzip")))
   (build-system binary-build-system)
   (arguments
    `(#:validate-runpath?
      #f
      #:patchelf-plan
      '(("emulator"
         ,(map
           specification->package-name
           specifications)))
      #:phases
      (modify-phases
       ,(fix (list
              'qemu
              (string-append "qemu" "/linux-x86_64")
              "qemu"))
       (add-after 'install 'install-wrapper
                  (lambda* (#:key inputs outputs system #:allow-other-keys)
                    (let* ((out (assoc-ref outputs "out"))
                           (bin (string-append out "/bin"))
                           (emulator (string-append out "/emulator")))
                      (mkdir-p bin)
                      (symlink emulator (string-append bin "/emulator")))))
       (add-after 'install-wrapper 'export-shared-libs
                  (lambda* (#:key inputs outputs system #:allow-other-keys)
                    (let* ((out (assoc-ref outputs "out"))
                           (exe (string-append out "/bin/emulator"))
                           (lib (string-append out "/lib64")))
                      (wrap-program exe
                                    `("LD_LIBRARY_PATH" ":" prefix
                                      (,lib)))))))))
   (supported-systems '("x86_64-linux"))
   (synopsis
    "The Android Emulator simulates Android devices on your computer")
   (description
    "The Android Emulator simulates Android devices on your computer so that you can test your application on a variety of devices and Android API levels without needing to have each physical device. It offers: Flexibility, High fidelity, Speed.")
   (home-page "https://developer.android.com")
   (license emulator-license)))
