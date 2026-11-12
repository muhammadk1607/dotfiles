#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# mise replaces nvm and rbenv: one tool for node, ruby, python, java, gradle
# and pnpm, with a single shell hook instead of three, and no `cd` override.

step "Setting up mise"

if have mise; then
	skip "mise"
else
	ensure_mise
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

"$DOTFILES_ROOT/scripts/install-npm-globals.sh"

step "Installing Ruby gems"
if mise which ruby >/dev/null 2>&1; then
	mise exec -- gem install --no-document \
		rails bundler prettier_print syntax_tree syntax_tree-haml syntax_tree-rbs rainbow
	mise reshim 2>/dev/null || true
else
	warn "ruby is not available through mise; skipping gems"
fi
