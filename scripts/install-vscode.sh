#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "Setting up VS Code"

if have code; then
	skip "code"
else
	add_apt_repo "vscode" \
		"https://packages.microsoft.com/keys/microsoft.asc" \
		"deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/vscode.gpg] https://packages.microsoft.com/repos/code stable main"
	apt_install code
fi

"$DOTFILES_ROOT/scripts/install-vscode-extensions.sh"
