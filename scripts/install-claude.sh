#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "Installing Claude Code CLI"

if have claude; then
	skip "claude"
else
	# The native installer needs no Node.js/npm and keeps itself updated,
	# unlike the `npm install -g @anthropic-ai/claude-code` alternative.
	curl -fsSL https://claude.ai/install.sh | bash
fi

# The installer puts the binary under ~/.local/bin, which isn't on PATH yet
# in this non-interactive script (only .bashrc adds it, for login shells).
export PATH="$HOME/.local/bin:$PATH"

step "Setting up Claude Desktop"

if have claude-desktop; then
	skip "claude-desktop"
else
	add_apt_repo "claude-desktop" \
		"https://downloads.claude.ai/claude-desktop/key.asc" \
		"deb [signed-by=/etc/apt/keyrings/claude-desktop.gpg] https://downloads.claude.ai/claude-desktop/apt/stable stable main"
	apt_install claude-desktop
fi

step "Installing the mattpocock-skills plugin"

# It ships in Claude Code's own built-in "claude-plugins-official" marketplace,
# so there is no marketplace to add first.
if ! have claude; then
	warn "claude is not on PATH; skipping the mattpocock-skills plugin"
elif claude plugin list --json 2>/dev/null | grep -q '"mattpocock-skills'; then
	skip "mattpocock-skills plugin"
else
	claude plugin install mattpocock-skills@claude-plugins-official --yes ||
		warn "Could not install the mattpocock-skills plugin"
fi
