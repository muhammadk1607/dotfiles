#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Install or update Zoom. It has no apt repo, so apt never updates it.
#
#   scripts/install-zoom.sh            install Zoom, or update it
#   scripts/install-zoom.sh --update   only update an installed Zoom

parse_update_flag "$@"

installed="$(deb_version zoom)"
[ -z "$installed" ] && [ "$UPDATE_ONLY" = true ] && exit 0

step "Zoom"

# The unversioned URL redirects to .../prod/<version>/zoom_amd64.deb, so the
# redirect target gives the latest version without downloading the package.
url="$(curl -fsSIL -o /dev/null -w '%{url_effective}' https://zoom.us/client/latest/zoom_amd64.deb)" ||
	die "Could not reach zoom.us"
latest="$(grep -oP '/prod/\K[0-9.]+(?=/)' <<<"$url" || true)"

if [ -n "$latest" ] && [ "$installed" = "$latest" ]; then
	info "zoom $installed is up to date"
	exit 0
fi

info "Installing Zoom ${latest:-(latest)}${installed:+ (replacing $installed)}"
install_deb_from_url "$url"
