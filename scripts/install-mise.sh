#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# mise replaces nvm and rbenv: one tool for node, ruby, python, java and gradle,
# with a single shell hook instead of three, and no `cd` override.

step "Setting up mise"

if have mise; then
	skip "mise"
else
	add_apt_repo "mise" \
		"https://mise.jdx.dev/gpg-key.pub" \
		"deb [signed-by=/etc/apt/keyrings/mise.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main"
	apt_install mise
fi

# Activate for this script only; .bashrc handles interactive shells.
eval "$(mise activate bash)"

step "Installing runtimes"
while read -r tool; do
	info "mise use -g $tool"
	mise --yes use -g "$tool"
done < <(read_list "$DOTFILES_ROOT/lists/mise-tools.txt")

mise install
mise reshim 2>/dev/null || true

step "Installing global npm packages"
if have node || mise which node >/dev/null 2>&1; then
	mapfile -t npm_packages < <(read_list "$DOTFILES_ROOT/lists/npm-packages.txt")
	mise exec -- npm install -g "${npm_packages[@]}"

	# corepack ships with node and manages yarn/pnpm versions per project.
	mise exec -- corepack enable
	mise exec -- corepack prepare yarn@stable --activate
	mise exec -- corepack prepare pnpm@latest --activate
	mise reshim 2>/dev/null || true
else
	warn "node is not available through mise; skipping npm packages"
fi

step "Installing Ruby gems"
if mise which ruby >/dev/null 2>&1; then
	mise exec -- gem install --no-document \
		rails bundler prettier_print syntax_tree syntax_tree-haml syntax_tree-rbs rainbow
	mise reshim 2>/dev/null || true
else
	warn "ruby is not available through mise; skipping gems"
fi
