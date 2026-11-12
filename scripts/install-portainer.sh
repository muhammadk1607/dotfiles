#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Run Portainer (a web UI for Docker) at https://localhost:9443, or recreate
# its container when a newer image is out.
#
#   scripts/install-portainer.sh            start Portainer, or update it
#   scripts/install-portainer.sh --update   only update an existing container

parse_update_flag "$@"

image="portainer/portainer-ce:lts"

have docker || exit 0

# Right after the docker step, this login isn't in the docker group yet.
docker=(docker)
docker info >/dev/null 2>&1 || docker=(sudo docker)

if ! "${docker[@]}" container inspect portainer >/dev/null 2>&1; then
	[ "$UPDATE_ONLY" = true ] && exit 0
	step "Portainer"
	info "Starting Portainer"
else
	step "Portainer"
	"${docker[@]}" pull -q "$image" >/dev/null || die "Could not pull $image"
	if [ "$("${docker[@]}" container inspect -f '{{.Image}}' portainer)" = "$("${docker[@]}" image inspect -f '{{.Id}}' "$image")" ]; then
		info "Portainer is up to date"
		exit 0
	fi
	# Settings live in the portainer_data volume, so the container is disposable.
	info "Recreating Portainer on the new image"
	"${docker[@]}" rm -f portainer >/dev/null
fi

# Bound to 127.0.0.1: Docker's published ports bypass ufw, and this UI
# controls the Docker daemon, which is root on this machine.
"${docker[@]}" volume create portainer_data >/dev/null
"${docker[@]}" run -d --name portainer --restart=always \
	-p 127.0.0.1:9443:9443 \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v portainer_data:/data \
	"$image" >/dev/null
info "Portainer is at https://localhost:9443"
