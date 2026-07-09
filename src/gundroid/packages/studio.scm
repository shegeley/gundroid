(define-module (gundroid packages studio)
  #:use-module ((guix packages) #:select (package origin base32))
  #:use-module ((guix download) #:select (url-fetch))
  #:use-module ((gnu packages) #:select (specification->package+output))
  #:use-module ((nonguix build-system binary) #:select (binary-build-system))
  #:use-module ((gundroid utils) #:select (ref-in))

  #:export (studio specifications versioning studio:specs
            get-verinfo android-studio:electric-eel))

(define android-studio-license
  ((@@ (guix licenses) license)
   "Android Studio License"
   "https://developer.android.com/studio"
   ""))

;; Older releases derive their download URL from the version; newer ones (from
;; Ladybug on) use codename-based filenames, so those carry an explicit `url'.
(define (uri-template version)
  (string-append
   "https://redirector.gvt1.com/edgedl/android/studio/ide-zips/"
   version "/android-studio-" version "-linux.tar.gz"))

(define versioning
  ;; https://developer.android.com/studio/archive — hashes from Google's
  ;; official release list (jb.gg/android-studio-releases-list.json).
  `(("2026.1.1.8" . ;; quail (latest stable)
     ((jdk-dir . "jbr")
      (jdk-version . "21")
      (url . "https://edgedl.me.gvt1.com/android/studio/ide-zips/2026.1.1.8/android-studio-quail1-linux.tar.gz")
      (hash . "1lw3gn0hqadhlnnkv0vhb36q4apal9ghmq4hibj0gggs7jxa87qc")))
    ("2025.3.4.6" . ;; panda
     ((jdk-dir . "jbr")
      (jdk-version . "21")
      (url . "https://edgedl.me.gvt1.com/android/studio/ide-zips/2025.3.4.6/android-studio-panda4-linux.tar.gz")
      (hash . "1lwza35zm01k0z01c7qdpal24c11gvp2p268c66v8f5amh4zz9rj")))
    ("2025.2.1.7" . ;; otter
     ((jdk-dir . "jbr")
      (jdk-version . "21")
      (url . "https://edgedl.me.gvt1.com/edgedl/android/studio/ide-zips/2025.2.1.7/android-studio-2025.2.1.7-linux.tar.gz")
      (hash . "1cccwxjivf5833xarzlffs1c39dvb4wgyll85lc4qvkl5nh1zbqn")))
    ("2024.1.2.13" . ;; koala
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
         (uri (or (assoc-ref verinfo 'url) (uri-template version)))
         (sha256 (base32 (assoc-ref verinfo 'hash)))))
      (build-system binary-build-system)
      (supported-systems '("x86_64-linux"))
      (arguments (list #:validate-runpath? #f))
      (inputs (studio:specs verinfo))
      (synopsis
       "Official integrated development environment for Android app development")
      (description
       "Android Studio is the official IDE for Android app development, built on
the code editor and developer tools of IntelliJ IDEA.  It offers:

@itemize
@item a flexible Gradle-based build system;
@item a fast and feature-rich emulator;
@item a unified environment where you can develop for all Android devices;
@item Apply Changes to push code and resource changes to a running app without
restarting it;
@item code templates and GitHub integration to help build common app features
and import sample code;
@item extensive testing tools and frameworks;
@item lint tools to catch performance, usability, version compatibility and
other problems;
@item C++ and NDK support;
@item built-in support for Google Cloud Platform.
@end itemize")
      (home-page "https://developer.android.com")
      (license android-studio-license))))

(define-public android-studio:electric-eel (studio))
(define-public android-studio:koala (studio #:version "2024.1.2.13"))
(define-public android-studio:otter (studio #:version "2025.2.1.7"))
(define-public android-studio:panda (studio #:version "2025.3.4.6"))
(define-public android-studio:quail (studio #:version "2026.1.1.8"))
