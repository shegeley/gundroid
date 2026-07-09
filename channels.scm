;; -*- mode: scheme; -*-
;;
;; Example channels file for consuming gundroid as a Guix channel.
;;
;;   guix pull -C channels.scm
;;
;; gundroid declares nonguix and guix as dependencies in its own
;; `.guix-channel', so pulling gundroid automatically pulls them too — you do
;; not need to list nonguix here.  After pulling:
;;
;;   guix install android-studio        # the IDE (FHS container wrapper)
;;   guix install android-sdk           # assembled read-only ANDROID_HOME
;;   guix install android-emulator      # standalone emulator
;;   guix package -A android            # list everything the channel provides
;;
;; Note: this channel ships nonfree software; do not promote it on official
;; Guix channels.

(list
 (channel
  (name 'gundroid)
  (url "https://github.com/shegeley/gundroid")
  (branch "master")))
