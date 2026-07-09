(define-module (gundroid packages cli-tools)
  #:use-module ((guix packages) #:select (package origin base32))
  #:use-module ((guix download) #:select (url-fetch))
  #:use-module ((gnu packages) #:select (specification->package))
  #:use-module ((nonguix build-system binary) #:select (binary-build-system))

  #:export (cmdline-tools platform-tools build-tools
            cmdline-tools-version platform-tools-version build-tools-version))

;; Prebuilt Android SDK components fetched straight from Google's repository and
;; simply unzipped.  They are dynamically-linked ELF binaries expecting a normal
;; FHS system, so they run inside a Guix FHS environment (see
;; (gundroid emulator) for the assembled ANDROID_HOME and the recommended
;; `guix shell --emulate-fhs' invocation), or inside the Android Studio
;; container in (gundroid studio).

(define repo-url
  "https://dl.google.com/android/repository/")

(define android-sdk-license
  ((@@ (guix licenses) license)
   "Android SDK License"
   "https://developer.android.com/studio/terms"
   ""))

(define* (sdk-component #:key name version file hash synopsis description)
  (package
    (name name)
    (version version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append repo-url file))
       (sha256 (base32 hash))))
    (build-system binary-build-system)
    (arguments
     `(#:validate-runpath? #f))
    (native-inputs
     ;; "unzip" has to be in native inputs or the unpack phase will fail.
     (list (specification->package "unzip")))
    (supported-systems '("x86_64-linux"))
    (synopsis synopsis)
    (description description)
    (home-page "https://developer.android.com")
    (license android-sdk-license)))

;; commandlinetools 9123335 == cmdline-tools 9.0.
(define cmdline-tools-version "9.0")
(define-public cmdline-tools
  (sdk-component
   #:name "android-cmdline-tools"
   #:version cmdline-tools-version
   #:file "commandlinetools-linux-9123335_latest.zip"
   #:hash "02ns06p63ikk218jbqkv43klkp0l5nbs12kz47s399ga769zbsqb"
   #:synopsis "Android SDK command-line tools"
   #:description
   "The Android SDK command-line tools: @command{sdkmanager},
@command{avdmanager}, @command{apkanalyzer}, @command{lint} and
@command{retrace}."))

(define platform-tools-version "34.0.0")
(define-public platform-tools
  (sdk-component
   #:name "android-platform-tools"
   #:version platform-tools-version
   #:file "platform-tools_r34.0.0-linux.zip"
   #:hash "1xpbxx8yxf159ynjk552m3il7k8gl0g09g58q5jcn1ga9n1w4dw1"
   #:synopsis "Android SDK platform tools"
   #:description
   "The Android SDK platform tools: @command{adb}, @command{fastboot},
@command{etc1tool} and @command{logcat}."))

(define build-tools-version "34.0.0")
(define-public build-tools
  (sdk-component
   #:name "android-build-tools"
   #:version build-tools-version
   #:file "build-tools_r34-linux.zip"
   #:hash "03sipljpyd7dba1a804v53hl65iv862d69dja4847l3902vc8n78"
   #:synopsis "Android SDK build tools"
   #:description
   "The Android SDK build tools: @command{aapt2}, @command{apksigner} and
@command{zipalign}."))
