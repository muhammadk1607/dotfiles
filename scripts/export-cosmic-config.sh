#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Snapshot the live COSMIC settings into config/cosmic/ so they can be committed.
# This is the COSMIC equivalent of the `dconf dump` this repo used to run.

is_cosmic || warn "Not in a COSMIC session — exporting whatever is on disk anyway"

source_dir="$HOME/.config/cosmic"
target_dir="$DOTFILES_ROOT/config/cosmic"

[ -d "$source_dir" ] || die "$source_dir does not exist"

step "Exporting COSMIC config"

rm -rf "$target_dir"
mkdir -p "$target_dir"

exported=0
while read -r component; do
	if [ -d "$source_dir/$component" ]; then
		cp -r "$source_dir/$component" "$target_dir/"
		exported=$((exported + 1))
	fi
done < <(read_list "$DOTFILES_ROOT/lists/cosmic-components.txt")

info "Exported $exported components to config/cosmic/"
info "Review with 'git diff' before committing — some keys hold machine-specific paths."
