(define-module (gundroid emulator)
  #:use-module ((guix packages) #:select (package))
  ;; #$ (ungexp) is a syntactic literal recognised inside `gexp', not a
  ;; standalone binding, so only `gexp' is selected.
  #:use-module ((guix gexp) #:select (gexp))
  #:use-module ((guix build-system trivial) #:select (trivial-build-system))

  #:use-module ((gundroid packages emulator) #:select (emulator))
  #:use-module ((gundroid packages cli-tools)
                #:select (cmdline-tools platform-tools build-tools
                          build-tools-version))

  #:export (android-sdk))

;; Assemble the prebuilt SDK components into the directory layout the Android
;; tooling expects under $ANDROID_HOME (see
;; https://developer.android.com/studio/command-line):
;;
;;   cmdline-tools/latest/bin/   sdkmanager, avdmanager, ...
;;   platform-tools/             adb, fastboot, ...
;;   build-tools/<version>/      aapt2, apksigner, zipalign
;;   emulator/                   emulator, mksdcard
;;
;; This is a *read-only* SDK in the store.  Point ANDROID_HOME at it and run
;; the tools inside a Guix FHS container (see the README for the full, verified
;; invocation), e.g.:
;;
;;   SDK=$(guix build -L src -e '(@ (gundroid emulator) android-sdk)')
;;   guix shell -L src --container --emulate-fhs --network --expose=/dev/kvm \
;;     coreutils bash grep sed which findutils procps \
;;     openjdk gcc-toolchain zlib glibc mesa vulkan-loader pulseaudio alsa-lib \
;;     -e '(@ (gundroid emulator) android-sdk)' \
;;     -- env ANDROID_HOME="$SDK" ANDROID_SDK_ROOT="$SDK" \
;;        sh -c '$ANDROID_HOME/emulator/emulator -accel-check'
;;
;; sdkmanager cannot install *into* this read-only store directory; for a
;; mutable SDK use Android Studio (see (gundroid studio)) which downloads its
;; own SDK into ~/.local/share/guix-sandbox-home, or copy this tree to a
;; writable location.

(define android-sdk-license
  ((@@ (guix licenses) license)
   "Android SDK License"
   "https://developer.android.com/studio/terms"
   ""))

(define-public android-sdk
  (package
    (name "android-sdk")
    (version "34")
    (source #f)
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let ((out #$output))
            (mkdir-p (string-append out "/cmdline-tools"))
            (symlink #$cmdline-tools
                     (string-append out "/cmdline-tools/latest"))
            (symlink #$platform-tools
                     (string-append out "/platform-tools"))
            (mkdir-p (string-append out "/build-tools"))
            (symlink #$build-tools
                     (string-append out "/build-tools/" #$build-tools-version))
            (symlink #$(emulator)
                     (string-append out "/emulator"))))))
    (supported-systems '("x86_64-linux"))
    (synopsis "Prebuilt Android SDK laid out as an ANDROID_HOME directory")
    (description
     "A read-only ANDROID_HOME assembled from the prebuilt command-line tools,
platform tools, build tools and emulator.  Run the tools inside a Guix FHS
environment (@command{guix shell --emulate-fhs}).")
    (home-page "https://developer.android.com")
    (license android-sdk-license)))

android-sdk
