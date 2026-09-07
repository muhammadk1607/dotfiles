#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Restores the COSMIC settings captured by scripts/export-cosmic-config.sh.
# Replaces the old GNOME path: dconf dumps, the extensions.gnome.org installer,
# and the Orchis/Tela theme builds, none of which apply under COSMIC.

step "Restoring COSMIC config"

if ! is_cosmic; then
	warn "XDG_CURRENT_DESKTOP is '${XDG_CURRENT_DESKTOP:-unset}', not COSMIC — skipping."
	exit 0
fi

source_dir="$DOTFILES_ROOT/config/cosmic"
target_dir="$HOME/.config/cosmic"

[ -d "$source_dir" ] || { warn "No config/cosmic/ in the repo yet. Run scripts/export-cosmic-config.sh first."; exit 0; }

# Back up what is there now — these are live settings and a bad restore is
# tedious to undo by hand.
if [ -d "$target_dir" ]; then
	backup="$target_dir.backup.$(date +%Y%m%d%H%M%S)"
	cp -r "$target_dir" "$backup"
	info "Backed up existing config to $backup"
fi

mkdir -p "$target_dir"
cp -r "$source_dir"/. "$target_dir"/

# Some values (wallpaper path, colour scheme) store an absolute home directory.
# Rewrite whatever home the export came from to this user's, so the config is
# not tied to the machine it was captured on.
while IFS= read -r -d '' file; do
	if grep -qE '/home/[^/"]+' "$file" 2>/dev/null; then
		sed -i -E "s|/home/[^/\"]+|${HOME}|g" "$file"
	fi
done < <(find "$target_dir" -type f -print0)

info "Restored $(find "$source_dir" -mindepth 1 -maxdepth 1 -type d | wc -l) components"
warn "Log out and back in for panel and theme changes to fully apply."
