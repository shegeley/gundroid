(define-module (gundroid packages cli-tools)
  #:use-module (gnu)

  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)

  #:use-module (gnu packages compression) ;; unzip

  #:use-module (nonguix build-system binary)

  #:use-module (gundroid utils)

  #:use-module (srfi srfi-1)

  #:use-module (ice-9 match)

  #:export (cli-tools))

(define repo-url
  "https://dl.google.com/android/repository/")

(define cli-tools-license
  ((@@ (guix licenses) license)
   "Android Cli-tools License"
   "https://developer.android.com/studio/command-line"
   ""))

(define cli-tools-versioning
  ;; https://developer.android.com/studio/releases/platform-tools#revisions
  `(("34.0.0" .
     ((release-date . "02.2023")
      (url ,(string-append repo-url "platform-tools_r34.0.0-linux.zip"))
      (hash . "1xpbxx8yxf159ynjk552m3il7k8gl0g09g58q5jcn1ga9n1w4dw1")))
    ("33.0.3" .
     ((release-date . "08.2022")
      (url ,(string-append repo-url "commandlinetools-linux-9123335_latest.zip"))
      (hash . "02ns06p63ikk218jbqkv43klkp0l5nbs12kz47s399ga769zbsqb")))))

(define* (cli-tools
          #:key
          (version "33.0.3")
          (versioning cli-tools-versioning))
  (package
    (name "android-commandline-tools")
    (version version)
    (source
     (origin
       (method url-fetch)
       (uri (ref-in versioning (list version 'url)))
       (sha256
        (base32 (ref-in versioning (list version 'hash))))))
    (build-system binary-build-system)
    (arguments
     `(#:validate-runpath? #f))
    (native-inputs
     ;; "unzip" has to be in native inputs or will fail
     (list
      (specification->package "unzip")))
    (supported-systems '("x86_64-linux"))
    (synopsis
     "The Android SDK is composed of multiple packages that are required for app development")
    (description
     "This package includes the most important command-line tools that are available, organized by the packages in which they're delivered")
    (home-page "https://developer.android.com")
    (license cli-tools-license)))
