#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Install every package in lists/npm-packages.txt that the current mise node
# doesn't have yet.
#
# Global npm packages belong to one node version. When `update` moves node to a
# new version (mise upgrade --bump), the new one starts with only npm, so this
# runs after every upgrade to bring the list back.

step "Global npm packages"

if ! have mise || ! mise which node >/dev/null 2>&1; then
	warn "node is not available through mise; skipping npm packages"
	exit 0
fi

mapfile -t wanted < <(read_list "$DOTFILES_ROOT/lists/npm-packages.txt")
installed="$(mise exec -- npm ls -g --depth=0 --json 2>/dev/null | jq -r '.dependencies // {} | keys[]')"

missing=()
for package in "${wanted[@]}"; do
	grep -qxF "$package" <<<"$installed" || missing+=("$package")
done

if [ ${#missing[@]} -eq 0 ]; then
	info "All $(mise exec -- node -v) globals are installed"
else
	info "Installing on node $(mise exec -- node -v): ${missing[*]}"
	mise exec -- npm install -g "${missing[@]}"
fi

# Enable corepack for yarn only. pnpm comes from mise, and a corepack pnpm shim
# would compete with it on PATH.
if mise exec -- corepack --version >/dev/null 2>&1; then
	mise exec -- corepack enable yarn
fi

mise reshim 2>/dev/null || true
