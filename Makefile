# gundroid — build and debug Android Studio (FHS container).
#
#   make build   # build the android-studio container package
#   make debug   # clean up, build, then launch with logging -> android-studio.log

studio  := src/gundroid/studio.scm
sandbox := $(HOME)/.local/share/guix-sandbox-home
# --no-offload: build locally (the offload node may be unreachable).
guix    := guix build --no-offload -L src -f $(studio)

.PHONY: build debug clean-runtime

build:
	$(guix)

# Pre-launch cleanup (the container runs with --network, i.e. it shares the
# host network, so a stray host adb server on :5037 collides with Studio's own
# adb; a crashed emulator also leaves *.lock files behind):
#   - stop any host adb server so Studio's bundled adb owns port 5037
#   - free port 5037 if something else holds it
#   - remove stale AVD locks (only safe because we stop the emulator first)
clean-runtime:
	-pkill -f 'qemu-system-x86' 2>/dev/null
	-adb kill-server 2>/dev/null
	-fuser -k 5037/tcp 2>/dev/null
	-rm -f $(sandbox)/.android/avd/*.avd/*.lock

# Launch with verbose logging.  G_MESSAGES_DEBUG and LIBGL_DEBUG are among the
# variables the nonguix container forwards into the sandbox, so they reach
# Studio and its emulator; all console output is tee'd to android-studio.log.
debug: build clean-runtime
	G_MESSAGES_DEBUG=all LIBGL_DEBUG=verbose \
	  $$($(guix) | tail -1)/bin/android-studio 2>&1 | tee android-studio.log
