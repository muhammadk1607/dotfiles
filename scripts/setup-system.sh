#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "Configuring the system"

## Firewall — deny inbound by default, allow the dev server port ranges.
if have ufw; then
	sudo ufw --force enable
	sudo ufw allow ssh
	for range in 3000:3050 4000:4999 5000:5050 8000:8999; do
		sudo ufw allow "${range}/tcp"
		sudo ufw allow "${range}/udp"
	done
	info "ufw enabled"
else
	warn "ufw is not installed; skipping firewall setup"
fi

## Raise the inotify watch limit — the default is far too low for file watchers
## in JS/Ruby toolchains. Written as a drop-in so re-runs replace rather than
## append, which is what the old `tee -a /etc/sysctl.conf` did.
sysctl_file="/etc/sysctl.d/99-dotfiles.conf"
cat <<'CONF' | sudo tee "$sysctl_file" >/dev/null
# Managed by ~/dotfiles — see scripts/setup-system.sh
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=1024
CONF
sudo sysctl --system >/dev/null
info "inotify limits raised (${sysctl_file})"

if have cosmic-term; then
	sudo update-alternatives --install /usr/bin/x-terminal-emulator \
		x-terminal-emulator /usr/bin/cosmic-term 60 >/dev/null 2>&1 || true
	sudo update-alternatives --set x-terminal-emulator /usr/bin/cosmic-term >/dev/null 2>&1 || true
	info "cosmic-term set as the default terminal"
fi
