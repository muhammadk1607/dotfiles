#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Installs every extension in lists/vscode-extensions.txt.
# Regenerate that list from the running editor with:
#   ./scripts/export-vscode-extensions.sh

step "Installing VS Code extensions"

have code || { warn "code is not on PATH; skipping extensions"; exit 0; }

# Compare case-insensitively: the marketplace treats publisher.name that way,
# and `code --list-extensions` casing does not always match the list file.
installed="$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"

while read -r extension; do
	if grep -qxF "$(tr '[:upper:]' '[:lower:]' <<<"$extension")" <<<"$installed"; then
		continue
	fi
	info "Installing $extension"
	code --install-extension "$extension" --force >/dev/null ||
		warn "Could not install $extension"
done < <(read_list "$DOTFILES_ROOT/lists/vscode-extensions.txt")
