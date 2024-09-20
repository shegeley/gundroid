(define-module (gundroid studio)
 #:use-module (guix packages)
 #:use-module (gundroid packages studio)
 #:use-module (gnu packages bash)
 #:use-module (nonguix multiarch-container))

(define android-studio:shared '("/tmp/.X11-unix" "/dev/shm" "/dev/kvm"))
(define android-studio:exposed '("/etc/machine-id"))
(define android-studio:preserved-env '("XAUTHORITY" "DISPLAY"))

(define studio* android-studio:electric-eel)

(define union (fhs-union (studio:specs (get-verinfo (package-version studio*) versioning))))

(define android-studio:ld.so.conf (packages->ld.so.conf (list union)))
(define android-studio:ld.so.cache
 (ld.so.conf->ld.so.cache android-studio:ld.so.conf))

(define android-studio-container
 (nonguix-container
  (name "android-studio")
  (wrap-package studio*)
  (run "/bin/studio.sh")
  (exposed android-studio:exposed)
  (shared android-studio:shared)
  (preserved-env android-studio:preserved-env)
  (ld.so.conf android-studio:ld.so.conf)
  (union64 union)
  (union32 union)
  (ld.so.cache android-studio:ld.so.cache)
  (description "")))

(define-public android-studio
 (nonguix-container->package android-studio-container))

android-studio
