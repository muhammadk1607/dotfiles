#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "Installing Flatpak applications"

have flatpak || apt_install flatpak

# Pop!_OS configures both of these already; adding them makes the script work
# on a plain Ubuntu install too. `cosmic` is Pop's own repository and is where
# most COSMIC applets live — they are not on Flathub.
flatpak remote-add --if-not-exists --user \
	flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists --user \
	cosmic https://apt.pop-os.org/cosmic/cosmic.flatpakrepo ||
	warn "Could not add the COSMIC flatpak remote; its applets will be skipped"

installed="$(flatpak list --app --columns=application 2>/dev/null || true)"

while read -r app remote; do
	remote="${remote:-flathub}"

	if grep -qxF "$app" <<<"$installed"; then
		skip "$app"
		continue
	fi

	info "Installing $app (from $remote)"
	flatpak install --user --noninteractive --or-update "$remote" "$app" ||
		warn "Could not install $app from $remote — it may have been renamed or removed"
done < <(read_list "$DOTFILES_ROOT/lists/flatpak-apps.txt")
