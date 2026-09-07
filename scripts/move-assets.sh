#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "Installing wallpapers"

target="$HOME/Pictures/wallpapers"
mkdir -p "$target"
cp -rTf "$DOTFILES_ROOT/wallpapers" "$target"
info "Copied to $target"

# COSMIC stores the wallpaper in ~/.config/cosmic/com.system76.CosmicBackground,
# which setup-cosmic.sh restores. There is no gsettings equivalent, so the
# old `gsettings set org.gnome.desktop.background picture-uri` call is gone.
if is_cosmic; then
	info "Set the wallpaper in COSMIC Settings → Desktop → Wallpaper, then run scripts/export-cosmic-config.sh to record it."
fi
