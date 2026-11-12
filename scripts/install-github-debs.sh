#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Install or update the apps published only as .deb files on GitHub releases.
# They add no apt source, so `apt full-upgrade` never updates them.
#
#   scripts/install-github-debs.sh            install missing apps, update the rest
#   scripts/install-github-debs.sh --update   only update apps already installed

parse_update_flag "$@"

# "<package> <user/repo> <asset>": in <asset>, {version} is the release tag
# without a leading v, and {tag} is the tag itself.
apps=(
	# The native package registers the systemd service that unattended access
	# needs, which the sandboxed Flathub build can't do.
	"rustdesk rustdesk/rustdesk rustdesk-{version}-x86_64.deb"
	# neofetch's replacement. Not in the 24.04 archive (it lands in 24.10).
	"fastfetch fastfetch-cli/fastfetch fastfetch-linux-amd64.deb"
	# ppa:o2sh/onefetch has no noble build.
	"onefetch o2sh/onefetch onefetch_amd64.deb"
	# Mounts Google Drive (scripts/setup-gdrive.sh). The 24.04 archive's
	# version is years behind.
	"rclone rclone/rclone rclone-{tag}-linux-amd64.deb"
)

step "GitHub release .debs"

rclone_before="$(deb_version rclone)"

status=0
for app in "${apps[@]}"; do
	read -r package repo asset <<<"$app"
	install_github_deb "$package" "$repo" "$asset" || {
		warn "Could not install or update $package"
		status=1
	}
done

# The running mount still uses the old binary until it restarts. Only restart
# when rclone actually changed, because a restart drops open files on the mount.
if [ -n "$rclone_before" ] && [ "$(deb_version rclone)" != "$rclone_before" ] &&
	systemctl --user is-active --quiet rclone-gdrive.service 2>/dev/null; then
	info "Restarting the Google Drive mount for the new rclone"
	systemctl --user restart rclone-gdrive.service
fi

exit "$status"
