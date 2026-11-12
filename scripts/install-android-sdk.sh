#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Install the Android SDK packages React Native / Expo builds need, or update
# every installed SDK package.
#
#   scripts/install-android-sdk.sh            install the SDK, or update it
#   scripts/install-android-sdk.sh --update   only update an SDK already installed

parse_update_flag "$@"

sdk="$HOME/Android/Sdk"
tools="$sdk/cmdline-tools"
android_cli="$tools/latest/bin/android"

# What a fresh install gets. The NDK is the one current React Native pins.
packages=(
	platform-tools
	emulator
	platforms/android-36
	build-tools/36.0.0
	ndk/27.1.12297006
)

[ "$UPDATE_ONLY" = true ] && [ ! -d "$tools/latest" ] && exit 0

step "Android SDK"

# sdkmanager and the android CLI need java, which mise provides.
if ! have java && have mise; then
	eval "$(mise env -s bash)"
fi
have java || die "java is not installed; run ./install.sh mise first"

# Since command-line tools 23, the `android` CLI replaces sdkmanager. It sends
# usage data unless told not to.
android_sdk() {
	"$android_cli" --no-metrics --sdk="$sdk" sdk "$@"
}

# sdkmanager can't replace the copy it runs from, so it installs the new one
# next to it as latest-2.
move_new_tools_into_place() {
	if [ -d "$tools/latest-2" ]; then
		rm -rf "$tools/latest"
		mv "$tools/latest-2" "$tools/latest"
	fi
}

if [ ! -d "$tools/latest" ]; then
	info "Installing the Android command-line tools"
	# Start from a fixed older release; its sdkmanager installs the latest
	# tools. https://developer.android.com/studio#command-tools
	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"' EXIT
	curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" -o "$tmp/tools.zip" ||
		die "Could not download the Android command-line tools"
	unzip -q "$tmp/tools.zip" -d "$tmp"
	yes | "$tmp/cmdline-tools/bin/sdkmanager" --sdk_root="$sdk" --licenses >/dev/null || true
	"$tmp/cmdline-tools/bin/sdkmanager" --sdk_root="$sdk" "cmdline-tools;latest"

	info "Installing ${packages[*]}"
	android_sdk install "${packages[@]}"
	exit 0
fi

# Command-line tools from before the android CLI never update themselves.
if [ ! -x "$android_cli" ]; then
	info "Updating the Android command-line tools"
	"$tools/latest/bin/sdkmanager" --sdk_root="$sdk" "cmdline-tools;latest"
	move_new_tools_into_place
fi

info "Updating installed SDK packages"
android_sdk update
move_new_tools_into_place
