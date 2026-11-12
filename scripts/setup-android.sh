#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Everything React Native / Expo development on Android needs:
# https://docs.expo.dev/get-started/set-up-your-environment
#
# Android Studio isn't installed: the SDK, emulator and scrcpy cover running
# apps, and Studio can be added from Flathub when you need its tooling.

"$DOTFILES_ROOT/scripts/install-android-sdk.sh"
"$DOTFILES_ROOT/scripts/install-watchman.sh"
"$DOTFILES_ROOT/scripts/install-scrcpy.sh"

step "Hardware acceleration for the emulator"

# The emulator runs far faster with KVM. It needs CPU virtualisation enabled
# in the firmware, and read/write access to /dev/kvm.
if [ ! -e /dev/kvm ]; then
	warn "/dev/kvm is missing; turn on virtualisation (VT-x / AMD-V) in the firmware settings"
elif id -nG "$USER" | grep -qw kvm; then
	skip "kvm group"
else
	# logind usually grants the desktop user access already, but that doesn't
	# cover ssh sessions or a headless emulator.
	sudo usermod -aG kvm "$USER"
	info "Added $USER to the kvm group (takes effect at next login)"
fi
