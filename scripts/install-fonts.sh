#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Install Iosevka (Fixed Slab for the UI, Term Slab for the terminal), or update
# it when a new release is out.
#
#   scripts/install-fonts.sh            install, or update if out of date
#   scripts/install-fonts.sh --update   only update fonts already installed

parse_update_flag "$@"

folder="$HOME/.local/share/fonts"
# The installed version, since the font file names don't include it.
marker="$HOME/.local/state/dotfiles/iosevka-version"

if [ "$UPDATE_ONLY" = true ] && ! compgen -G "$folder/*Iosevka*" >/dev/null; then
	exit 0
fi

step "Fonts"

# Upstream renamed its release archives more than once — SuperTTC-* became
# PkgTTC-* — so resolve the asset name from the release itself rather than
# guessing, and fail loudly instead of silently installing nothing.
repo="be5invis/Iosevka"
tag="$(latest_git_release "$repo")"
version="${tag#v}"

if [ "$(cat "$marker" 2>/dev/null)" = "$version" ]; then
	info "Iosevka $version is up to date"
	exit 0
fi

mkdir -p "$folder"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

failed=0
for variant in FixedSlab TermSlab; do
	archive="PkgTTC-SGr-Iosevka${variant}-${version}.zip"
	url="https://github.com/${repo}/releases/download/${tag}/${archive}"

	info "Downloading Iosevka ${variant} ${version}"
	if ! curl -fsSL "$url" -o "$tmp/${variant}.zip"; then
		warn "Could not download ${archive}."
		warn "Check the asset names at https://github.com/${repo}/releases/tag/${tag}"
		failed=1
		continue
	fi
	unzip -oq "$tmp/${variant}.zip" -d "$folder" '*.ttc'
done

fc-cache -f "$folder" >/dev/null
info "Font cache rebuilt"

# Record the version only when both variants installed, so a failed download
# is retried next time.
if [ "$failed" -eq 0 ]; then
	mkdir -p "$(dirname "$marker")"
	echo "$version" >"$marker"
fi
exit "$failed"
