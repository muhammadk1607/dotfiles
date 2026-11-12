#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Install scrcpy (mirror and control an Android device) from its GitHub
# releases, or update it. The 24.04 archive is on 1.25, without audio or camera
# mirroring.
#
#   scripts/install-scrcpy.sh            install scrcpy, or update it
#   scripts/install-scrcpy.sh --update   only update an installed scrcpy

parse_update_flag "$@"

dir="$HOME/.local/share/scrcpy"
bin="$HOME/.local/bin/scrcpy"
marker="$dir/VERSION"

[ ! -x "$bin" ] && [ "$UPDATE_ONLY" = true ] && exit 0

step "scrcpy"

tag="$(latest_git_release "Genymobile/scrcpy")"
current="$(cat "$marker" 2>/dev/null || true)"
if [ -x "$bin" ] && [ "$current" = "$tag" ]; then
	info "scrcpy $tag is up to date"
	exit 0
fi

info "Installing scrcpy $tag${current:+ (replacing $current)}"
archive="scrcpy-linux-x86_64-${tag}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL "https://github.com/Genymobile/scrcpy/releases/download/${tag}/${archive}.tar.gz" -o "$tmp/scrcpy.tar.gz" ||
	die "Could not download scrcpy $tag"
tar xzf "$tmp/scrcpy.tar.gz" -C "$tmp"

# The release is self-contained: the binary looks for scrcpy-server next to
# itself, so keep the folder together and link the binary onto PATH.
rm -rf "$dir"
mv "$tmp/$archive" "$dir"
echo "$tag" >"$marker"
mkdir -p "$(dirname "$bin")"
ln -sfn "$dir/scrcpy" "$bin"
