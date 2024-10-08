(define-module (gundroid packages studio)
  #:use-module (gnu)

  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)

  #:use-module (gnu packages compression) ;; unzip

  #:use-module (nonguix build-system binary)

  #:use-module (gundroid utils)

  #:use-module (srfi srfi-1)

  #:use-module (ice-9 match)

  #:export (studio specifications versioning studio:specs
            get-verinfo android-studio:electric-eel))

(define android-studio-license
  ((@@ (guix licenses) license)
   "Android Studio License"
   "https://developer.android.com/studio"
   ""))

(define (uri-template version)
  (string-append
   "https://redirector.gvt1.com/edgedl/android/studio/ide-zips/"
   version "/android-studio-" version "-linux.tar.gz"))

(define versioning
  `(("2024.1.2.13" . ;; koala
     ((jdk-dir . "jbr")
      (jdk-version . "17")
      (hash . "16qvrdhgkj0m5xzxkm0bygvnnw66dv12qf5f29x8ca8g4df6b338")))
    ("2022.1.1.19" . ;; electric-eel
     ((jdk-dir . "jbr")
      ;; NOTE: jbr = runtime environment based on OpenJDK for running IntelliJ Platform-based products on Windows, macOS, and Linux
      ;; https://github.com/JetBrains/JetBrainsRuntime
      (jdk-version . "11")
      (hash . "0h4dlq30j9vl6mf58jvqgl9z5m73an3bicy7vd0s5ww2mpll9v4n")))
    ("2021.3.1.17" .
     ((jdk-dir . "jre")
      (jdk-version . "11")
      (hash . "1jjnfzvljnm9p5n6l7hp7k254p8z5cadpzkv9s4vfips1z7b1bc9")))))

(define (specifications verinfo)
  (list
   ;; NOTE: need to determine openjdk version from version info. recent ~android studio~ uses jdk 17, previous ones (before 2022.1, including oneself) using jdk 11
   (string-append
    "openjdk@"
    (ref-in verinfo (list 'jdk-version))
    ":jdk")
   "vulkan-loader"
   "vulkan-headers"
   "vulkan-tools"
   "fontconfig"
   "freetype"
   "python"
   "bash"
   "coreutils"
   "git"
   "which"
   "dbus"
   "sed"
   "grep"
   "findutils"
   "kdialog"
   "xmessage"
   "libnotify"
   "gcc-toolchain"
   "zenity"
   "adb"
   "e2fsprogs"
   "qemu-minimal"
   "alsa-lib"
   "expat"
   "libxcomposite"
   "libxcursor"
   "libxi"
   "libxtst"
   "mesa"
   "nss"
   "pulseaudio"
   "util-linux:lib"
   "libx11"
   "glib" ;; for gsettings
   "zlib"))

(define (studio:specs verinfo)
  (map
   (lambda (s)
     (list
      (if (string-prefix-ci? "openjdk" s) "openjdk" s)
      (specification->package+output s)))
   (specifications verinfo)))

(define* (get-verinfo version #:optional (versioning versioning))
  (assoc-ref versioning version))

(define* (studio #:key
                 (version "2022.1.1.19")
                 (versioning versioning))
  (let ((verinfo (get-verinfo version versioning)))
    (package
      (name "android-studio")
      (version version)
      (source
       (origin
         (method url-fetch)
         (uri (uri-template version))
         (sha256 (base32 (assoc-ref verinfo 'hash)))))
      (build-system binary-build-system)
      (supported-systems '("x86_64-linux"))
      (arguments (list #:validate-runpath? #f))
      (inputs (studio:specs verinfo))
      (synopsis
       "Official Integrated Development Environment (IDE) for Android app development")
      (description
       "Based on the powerful code editor and developer tools from IntelliJ IDEA, Android Studio offers even more features that enhance your productivity when building Android apps:
    - A flexible Gradle-based build system
    - A fast and feature-rich emulator
    - A unified environment where you can develop for all Android devices
    - Apply Changes to push code and resource changes to your running app without restarting your app
    - Code templates and GitHub integration to help you build common app features and import sample code
    - Extensive testing tools and frameworks
    - Lint tools to catch performance, usability, version compatibility, and other problems
    - C++ and NDK support
    - Built-in support for Google Cloud Platform, making it easy to integrate Google Cloud Messaging and App Engine")
      (home-page "https://developer.android.com")
      (license android-studio-license))))

(define-public android-studio:electric-eel (studio))
(define-public android-studio:koala (studio #:version "2024.1.2.13"))
