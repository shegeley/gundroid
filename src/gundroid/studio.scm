(define-module (gundroid studio)
 #:use-module ((guix packages) #:select (package package-version package-license))
 #:use-module ((guix gexp) #:select (gexp plain-file))
 #:use-module ((guix build-system trivial) #:select (trivial-build-system))
 #:use-module ((gnu packages) #:select (specification->package))
 #:use-module ((gundroid packages studio)
               #:select (studio:specs get-verinfo versioning
                         android-studio:quail))
 #:use-module ((nonguix multiarch-container)
               #:select (fhs-union fhs-min-libs
                         nonguix-container nonguix-container->package))
 #:export (android-studio))

;; Android Studio, packaged as a nonguix multiarch (FHS) container — the same
;; technique nonguix uses for Steam.  The IDE, its bundled JBR runtime, the SDK
;; it downloads on first launch, and the emulator it starts all run inside an
;; FHS sandbox, so the prebuilt Google binaries find the loader and shared
;; libraries they expect.  NOTE: the real $HOME is NOT visible inside the
;; sandbox; Studio keeps its config and the SDK it downloads under
;; ~/.local/share/guix-sandbox-home.

(define android-studio:shared
  ;; Host paths bind-mounted read-write into the sandbox.
  '("/tmp/.X11-unix"
    "/dev/shm"
    "/dev/kvm"        ;; hardware acceleration for the emulator (needs rw)
    "/dev/dri"))      ;; GPU render nodes for the emulator / IDE

(define android-studio:exposed
  ;; Host paths bind-mounted read-only into the sandbox.
  '("/etc/machine-id"))

(define android-studio:preserved-env
  ;; Regexps of host environment variables to carry into the sandbox so the
  ;; GUI (X11 / Wayland), audio and GPU acceleration work.
  '("^DISPLAY$" "^XAUTHORITY$" "^WAYLAND_DISPLAY$"
    "^XDG_RUNTIME_DIR$" "^PULSE_SERVER$"
    ;; GPU vendor/driver selection for the emulator's hardware rendering:
    ;; mesa (Intel/AMD) and the NVIDIA PRIME/GLVND knobs.
    "^DRI_PRIME$" "^MESA_" "^LIBVA_DRIVER_NAME$"
    "^RADV_" "^AMD_" "^ANV_" "^INTEL_"
    "^VK_ICD_FILENAMES$" "^VK_DRIVER_FILES$" "^VK_LOADER_"
    "^__GLX_VENDOR_LIBRARY_NAME$" "^__GL_" "^__NV_PRIME_RENDER_OFFLOAD$"
    "^__VK_LAYER_NV_" "^NVD_BACKEND$"))

(define studio* android-studio:quail)

;; Extra shared libraries the *downloaded* Android emulator dynamically links
;; against (merged from (gundroid packages emulator)).  Studio's own specs
;; already cover mesa/vulkan/fontconfig/etc.; these are the ones that are only
;; needed once the emulator itself is launched from within the IDE.
(define emulator-extra-lib-specs
  '("openlibm" "pth" "libcxx" "ell" "libgccjit" "gperftools"
    ;; GPU / EGL dispatch so the IDE and the emulator get accelerated
    ;; rendering (populates share/glvnd/egl_vendor.d in the FHS union).
    "libglvnd" "egl-wayland"
    ;; Needed by the emulator's bundled qemu (Qt6 WebEngine pulls these in):
    "libxkbfile" "libbsd" "nspr"
    ;; The emulator's Qt xcb platform plugin needs these X11 session-management
    ;; libs, otherwise the UI aborts with "no Qt platform plugin could be
    ;; initialized" (exit 134).  (Qt 6.5 misleadingly blames xcb-cursor0, but
    ;; that lib is bundled in the emulator's qt/lib; libICE/libSM are not.)
    "libice" "libsm"))

(define (spec->input s)
  (list s (specification->package s)))

;; nss ships its libraries under lib/nss/, which the container's ld.so.cache
;; (generated from top-level lib/ only) does not scan.  The emulator's bundled
;; qemu links against libnss3/libnssutil3/libsmime3, so flatten them into a
;; top-level lib/.
(define nss-flat
  (let ((nss (specification->package "nss")))
    (package
      (name "nss-flat")
      (version (package-version nss))
      (source #f)
      (build-system trivial-build-system)
      (arguments
       (list
        #:modules '((guix build utils) (ice-9 ftw))
        #:builder
        #~(begin
            (use-modules (guix build utils) (ice-9 ftw))
            (let* ((out #$output)
                   (lib (string-append out "/lib"))
                   (src (string-append #$nss "/lib/nss")))
              (mkdir-p lib)
              (for-each
               (lambda (f)
                 (unless (member f '("." ".."))
                   (symlink (string-append src "/" f)
                            (string-append lib "/" f))))
               (scandir src))))))
      (synopsis "nss libraries flattened into lib/")
      (description "The nss shared libraries, symlinked from @file{lib/nss} into
a top-level @file{lib/} so a generated ld.so.cache in an FHS container finds
them.")
      (home-page "https://developer.android.com")
      (license #f))))

(define android-studio:packages
  (append
   fhs-min-libs
   (studio:specs (get-verinfo (package-version studio*) versioning))
   (map spec->input emulator-extra-lib-specs)
   (list (list "nss-flat" nss-flat))))

;; Reuse a single 64-bit union for both slots: Android Studio and the emulator
;; are x86_64-only, so building the 32-bit (i686) union that the `packages:'
;; field would create by default is both unnecessary and would try to build a
;; large, largely-unsupported i686 world.
(define android-studio:union
  (fhs-union android-studio:packages #:name "android-studio-fhs"))

(define android-studio-container
 (nonguix-container
  (name "android-studio")
  (wrap-package studio*)
  (run "/bin/studio.sh")
  (union64 android-studio:union)
  (union32 android-studio:union)
  (exposed android-studio:exposed)
  (shared android-studio:shared)
  (preserved-env android-studio:preserved-env)
  (synopsis "Android Studio IDE running in a Guix FHS container")
  (description
   "Android Studio packaged as a nonguix multiarch (FHS) container, mirroring
the way Steam is packaged in nonguix.  Launch it with the @command{android-studio}
command.  The IDE downloads its own SDK and emulator into
@file{~/.local/share/guix-sandbox-home} and runs them inside the sandbox.")))

(define android-studio-wrapper
 (nonguix-container->package android-studio-container))

(define android-studio-desktop
  (plain-file "android-studio.desktop"
   "[Desktop Entry]
Type=Application
Name=Android Studio
GenericName=Android IDE
Comment=Official IDE for Android application development
Exec=android-studio %f
Icon=android-studio
Terminal=false
StartupNotify=true
StartupWMClass=jetbrains-studio
Categories=Development;IDE;
"))

;; Wrap the container package with a desktop entry + icon so Android Studio
;; shows up in the application menu.  Exec calls the `android-studio' wrapper on
;; PATH (present once this package is installed into a profile), which launches
;; the FHS container.  The icon is taken from Studio's own studio.svg/png.
(define-public android-studio
  (package
    (name "android-studio")
    (version (package-version studio*))
    (source #f)
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let ((out     #$output)
                (wrapper #$android-studio-wrapper)
                (studio  #$studio*))
            (mkdir-p (string-append out "/bin"))
            (symlink (string-append wrapper "/bin/android-studio")
                     (string-append out "/bin/android-studio"))
            (mkdir-p (string-append out "/share/applications"))
            (copy-file #$android-studio-desktop
                       (string-append out "/share/applications/android-studio.desktop"))
            (mkdir-p (string-append out "/share/icons/hicolor/scalable/apps"))
            (symlink (string-append studio "/bin/studio.svg")
                     (string-append out "/share/icons/hicolor/scalable/apps/android-studio.svg"))
            (mkdir-p (string-append out "/share/pixmaps"))
            (symlink (string-append studio "/bin/studio.png")
                     (string-append out "/share/pixmaps/android-studio.png"))))))
    (synopsis "Android Studio IDE (FHS container) with a desktop entry")
    (description
     "Android Studio packaged as a nonguix multiarch (FHS) container, with a
desktop entry and icon so it appears in the application menu.  It launches via
the @command{android-studio} wrapper, which runs the IDE, the SDK it downloads
and its emulator inside the sandbox.")
    (home-page "https://developer.android.com")
    (license (package-license studio*))))

android-studio
