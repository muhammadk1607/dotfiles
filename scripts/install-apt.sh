#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "Installing apt packages"

sudo apt-get update -qq
sudo apt-get full-upgrade -y

mapfile -t packages < <(read_list "$DOTFILES_ROOT/lists/apt-packages.txt")
apt_install "${packages[@]}"

# Ubuntu ships these under alternate binary names to avoid clashes; the .bashrc
# aliases bat/fd to them, but a symlink makes scripts and $EDITOR integrations work too.
sudo install -d -m 0755 /usr/local/bin
[ -x /usr/bin/batcat ] && sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
[ -x /usr/bin/fdfind ] && sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd

step "Installing pipx tools"
pipx ensurepath >/dev/null 2>&1 || true
while read -r tool; do
	if pipx list --short 2>/dev/null | grep -q "^${tool} "; then
		skip "$tool"
	else
		info "Installing $tool"
		pipx install "$tool"
	fi
done < <(read_list "$DOTFILES_ROOT/lists/pipx-packages.txt")
