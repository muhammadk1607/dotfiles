#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "Setting up Docker"

if have docker; then
	skip "docker"
else
	# Pop!_OS reports itself as `pop` with no Docker repo of its own, so the
	# repo is keyed off the Ubuntu codename it is built on (noble for 24.04).
	codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"

	add_apt_repo "docker" \
		"https://download.docker.com/linux/ubuntu/gpg" \
		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable"

	# compose is a CLI plugin now (`docker compose`); the standalone v1 binary
	# this repo used to fetch is end-of-life.
	apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

if getent group docker >/dev/null && ! id -nG "$USER" | grep -qw docker; then
	info "Adding $USER to the docker group"
	sudo usermod -aG docker "$USER"
	warn "Log out and back in (or reboot) for docker group membership to take effect."
fi
