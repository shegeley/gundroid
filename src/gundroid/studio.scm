(define-module (gundroid studio)
 #:use-module (guix packages)
 #:use-module (gnu packages)                 ;; specification->package
 #:use-module (gundroid packages studio)
 #:use-module (nonguix multiarch-container)
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
  ;; GUI (X11 / Wayland) and audio work.
  '("^DISPLAY$" "^XAUTHORITY$" "^WAYLAND_DISPLAY$"
    "^XDG_RUNTIME_DIR$" "^PULSE_SERVER$"))

(define studio* android-studio:quail)

;; Extra shared libraries the *downloaded* Android emulator dynamically links
;; against (merged from (gundroid packages emulator)).  Studio's own specs
;; already cover mesa/vulkan/fontconfig/etc.; these are the ones that are only
;; needed once the emulator itself is launched from within the IDE.
(define emulator-extra-lib-specs
  '("openlibm" "pth" "libcxx" "ell" "libgccjit" "gperftools"
    ;; GPU / EGL dispatch so the IDE and the emulator get accelerated
    ;; rendering (populates share/glvnd/egl_vendor.d in the FHS union).
    "libglvnd" "egl-wayland"))

(define (spec->input s)
  (list s (specification->package s)))

(define android-studio:packages
  (append
   fhs-min-libs
   (studio:specs (get-verinfo (package-version studio*) versioning))
   (map spec->input emulator-extra-lib-specs)))

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

(define-public android-studio
 (nonguix-container->package android-studio-container))

android-studio
