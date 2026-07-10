;; -*- mode: scheme; -*-
;;
;; Channel news for gundroid, shown by `guix pull --news'.
;; See "Writing Channel News" in the Guix manual.

(channel-news
 (version 0)

 (entry (commit "fdb2bfa0d0e7b1d9d14471ef960842c3db92fdc2")
        (title (en "gundroid works: Android Studio, emulator and real devices"))
        (body (en "gundroid now works end to end on a current Guix.

Install and run Android Studio (it also gets a desktop-menu entry + icon):

@example
guix install android-studio
android-studio
@end example

Android Studio runs in an FHS container (the Steam technique) and downloads and
runs its own SDK and emulator inside the sandbox.  The emulator boots a virtual
device with KVM acceleration, using hardware Vulkan on a machine with a working
GPU (mesa RADV/ANV for AMD/Intel) and software rendering otherwise.  Tested with
a Pixel 10 AVD (Android 37) booting to the home screen, and a Pixel 9 physical
device over the network (ADB Wi-Fi) for on-hardware deploy/debug.

Also available: the latest Android Studio releases (Quail 2026.1.1.8 by
default), and a standalone CLI SDK — @code{android-cmdline-tools},
@code{android-platform-tools}, @code{android-build-tools} and
@code{android-emulator}, assembled into an @env{ANDROID_HOME} by
@code{android-sdk} and run under @command{guix shell --emulate-fhs}."))))
