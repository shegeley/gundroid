;; -*- mode: scheme; -*-
;;
;; Example channels file for consuming gundroid as a Guix channel:
;;
;;   guix pull -C channels.scm
;;
;; It appends gundroid to your default channels (so guix itself keeps updating
;; normally).  gundroid declares nonguix as a dependency in its own
;; `.guix-channel', so pulling gundroid pulls nonguix automatically — you do not
;; need to list nonguix here.  After pulling:
;;
;;   guix install android-studio        # the IDE (FHS container wrapper)
;;   guix install android-sdk           # assembled read-only ANDROID_HOME
;;   guix install android-emulator      # standalone emulator
;;   guix install android-cmdline-tools android-platform-tools android-build-tools
;;   guix package -A android            # list everything the channel provides
;;
;; Note: this channel ships nonfree software; do not promote it on official
;; Guix channels.

(use-modules (guix channels))

(cons (channel
       (name 'gundroid)
       (url "https://github.com/shegeley/gundroid")
       (branch "master"))
      %default-channels)
