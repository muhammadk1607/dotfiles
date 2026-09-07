#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Symlinks everything in dot/ into $HOME, so edits in either place are the same
# file and `git status` in this repo shows what has drifted.

step "Linking dotfiles into \$HOME"

for file in "$DOTFILES_ROOT"/dot/.*; do
	name="$(basename "$file")"
	case "$name" in
		. | ..) continue ;;
	esac
	target="$HOME/$name"

	# Already the right symlink — nothing to do.
	if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$file")" ]; then
		continue
	fi

	# Move a real file out of the way rather than clobbering it.
	if [ -e "$target" ] && [ ! -L "$target" ]; then
		backup="$target.backup.$(date +%Y%m%d%H%M%S)"
		mv "$target" "$backup"
		warn "$name existed — backed up to $(basename "$backup")"
	fi

	ln -sfn "$file" "$target"
	info "$name"
done

# ~/.bash.profile is deliberately a copy, not a symlink: .bashrc sources it for
# machine-local settings that should stay out of the repo. Never overwrite one.
if [ ! -e "$HOME/.bash.profile" ]; then
	cp "$DOTFILES_ROOT/templates/bash.profile" "$HOME/.bash.profile"
	info ".bash.profile (local copy, not tracked)"
fi
