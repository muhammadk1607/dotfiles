#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "Setting up GitHub CLI"

# The Ubuntu archive lags well behind upstream, so use GitHub's own repo.
add_apt_repo "github-cli" \
	"https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/github-cli.gpg] https://cli.github.com/packages stable main"

apt_install gh
