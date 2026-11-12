#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Install Watchman (Metro's file watcher) from its GitHub releases, or update
# it. The 24.04 archive ships a 2017 build.
#
#   scripts/install-watchman.sh            install Watchman, or update it
#   scripts/install-watchman.sh --update   only update an installed Watchman

parse_update_flag "$@"

current=''
have watchman && current="$(watchman --version 2>/dev/null || true)"
[ -z "$current" ] && [ "$UPDATE_ONLY" = true ] && exit 0

step "Watchman"

# Most weekly releases have no Linux build, so take the newest one that does.
tag="$(curl -fsSL "https://api.github.com/repos/facebook/watchman/releases?per_page=30" |
	jq -r '[.[] | select(any(.assets[]; .name | test("linux\\.zip$")))][0].tag_name // empty')"
[ -n "$tag" ] || die "Could not find a Watchman release with a Linux build"

# Tags look like v2026.11.09.00 and `watchman --version` like 20261109.012849.0,
# so compare the dates.
latest_date="$(tr -d 'v.' <<<"${tag:0:11}")"
if [ -n "$current" ] && [ "${current:0:8}" = "$latest_date" ]; then
	info "watchman $current is up to date"
	exit 0
fi

info "Installing Watchman $tag${current:+ (replacing $current)}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL "https://github.com/facebook/watchman/releases/download/${tag}/watchman-${tag}-linux.zip" -o "$tmp/watchman.zip" ||
	die "Could not download Watchman $tag"
unzip -q "$tmp/watchman.zip" -d "$tmp"
src="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d -name 'watchman-*' | head -1)"
[ -n "$src" ] || die "Unexpected Watchman archive layout"

# Stop the running server so the next client starts the new version.
if [ -n "$current" ]; then
	watchman shutdown-server >/dev/null 2>&1 || true
fi

# Layout from https://facebook.github.io/watchman/docs/install#prebuilt-binaries
sudo install -d /usr/local/bin /usr/local/lib /usr/local/var/run/watchman
sudo install -m 755 "$src"/bin/* /usr/local/bin/
sudo cp -a "$src"/lib/. /usr/local/lib/
sudo chmod 2777 /usr/local/var/run/watchman
sudo ldconfig
