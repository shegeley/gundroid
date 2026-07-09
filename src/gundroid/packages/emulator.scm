(define-module (gundroid packages emulator)
  #:use-module ((guix packages) #:select (package origin base32))
  #:use-module ((guix download) #:select (url-fetch))
  #:use-module ((gnu packages)
                #:select (specification->package specification->package+output))
  #:use-module ((nonguix build-system binary) #:select (binary-build-system))
  #:use-module ((gundroid utils)
                #:select (fix ref-in specification->package-name))

  #:export (emulator android-emulator))

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
    "gcc-toolchain"
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
      (modify-phases ,(fix (list 'qemu (string-append "qemu" "/linux-x86_64") "qemu"))
       (add-after 'install 'wrap-emulator
        (lambda* (#:key inputs outputs system #:allow-other-keys)
         (let* ((out (assoc-ref outputs "out"))
                (bin (string-append out "/bin"))
                ;; The root `emulator' launcher is what the SDK, avdmanager and
                ;; Android Studio invoke.  patchelf strips its $ORIGIN rpath, so
                ;; wrap it to put the bundled shared libraries back on the path
                ;; (the previous version only wrapped bin/emulator, which the
                ;; SDK layout never calls).
                (exe (string-append out "/emulator"))
                (lib64 (string-append out "/lib64"))
                (qtlib (string-append out "/lib64/qt/lib")))
          (wrap-program exe
           `("LD_LIBRARY_PATH" ":" prefix (,lib64 ,qtlib)))
          (mkdir-p bin)
          (symlink exe (string-append bin "/emulator"))))))))
   (supported-systems '("x86_64-linux"))
   (synopsis "Simulate Android devices on your computer")
   (description
    "The Android Emulator simulates Android devices on your computer so that you
can test your application on a variety of devices and Android API levels without
needing each physical device.  It offers:

@itemize
@item flexibility, running many device configurations and API levels;
@item high fidelity, emulating phone features such as GPS and sensors;
@item speed, through hardware acceleration.
@end itemize")
   (home-page "https://developer.android.com")
   (license emulator-license)))

;; A concrete, installable package so the channel exposes it to
;; `guix install' / `guix package -A'.
(define android-emulator (emulator))

android-emulator
