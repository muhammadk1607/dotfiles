#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "Setting up the GitHub SSH key"

key="$HOME/.ssh/id-github"

if [ -f "$key" ]; then
	skip "$key"
else
	install -d -m 0700 "$HOME/.ssh"
	ssh-keygen -t ed25519 -C "$(git config --global user.email || echo "$USER@$(hostname)")" -f "$key" -N ""
	eval "$(ssh-agent -s)" >/dev/null
	ssh-add "$key"

	if have gh && gh auth status >/dev/null 2>&1; then
		read -r -p "    Title for the new GitHub SSH key: " title
		gh ssh-key add "${key}.pub" --title "${title:-$(hostname)}"
		gh ssh-key add "${key}.pub" --title "${title:-$(hostname)} (signing)" --type signing
	else
		warn "gh is not authenticated. Run 'gh auth login', then add the key:"
		warn "  gh ssh-key add ${key}.pub --title \"\$(hostname)\""
	fi
fi

# The Host alias used by .gitconfig's insteadOf rewrite.
if [ ! -f "$HOME/.ssh/config" ]; then
	info "Writing ~/.ssh/config"
	install -m 0600 "$DOTFILES_ROOT/config/ssh/config" "$HOME/.ssh/config"
fi
