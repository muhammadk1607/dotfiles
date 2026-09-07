#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "Installing fonts"

folder="$HOME/.local/share/fonts"
mkdir -p "$folder"

# Iosevka: Slab for UI, Term Slab for the terminal.
# Upstream renamed its release archives more than once — SuperTTC-* became
# PkgTTC-* — so resolve the asset name from the release itself rather than
# guessing, and fail loudly instead of silently installing nothing.
repo="be5invis/Iosevka"
tag="$(latest_git_release "$repo")"
version="${tag#v}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for variant in FixedSlab TermSlab; do
	archive="PkgTTC-SGr-Iosevka${variant}-${version}.zip"
	url="https://github.com/${repo}/releases/download/${tag}/${archive}"

	info "Downloading Iosevka ${variant} ${version}"
	if ! curl -fsSL "$url" -o "$tmp/${variant}.zip"; then
		warn "Could not download ${archive}."
		warn "Check the asset names at https://github.com/${repo}/releases/tag/${tag}"
		continue
	fi
	unzip -oq "$tmp/${variant}.zip" -d "$folder" '*.ttc'
done

fc-cache -f "$folder" >/dev/null
info "Font cache rebuilt"
