#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Renders vscode-extensions.md from lists/vscode-extensions.txt, so the readable
# doc and the list the installer actually uses cannot drift apart.
#
# Replaces the old workflow, which was: paste a script into the VS Code DevTools
# console, scroll the extensions pane by hand for ten seconds to defeat virtual
# scrolling, then run copy(markdown).

list="$DOTFILES_ROOT/lists/vscode-extensions.txt"
target="$DOTFILES_ROOT/vscode-extensions.md"

[ -f "$list" ] || die "$list not found — run scripts/export-vscode-extensions.sh first"

step "Rendering vscode-extensions.md"

{
	cat <<-'HEADER'
	# 🧩 VS Code Extensions

	Generated from [`lists/vscode-extensions.txt`](./lists/vscode-extensions.txt) —
	edit that file, not this one, then re-run `./scripts/render-vscode-extensions.sh`.

	Install them all with `./install.sh vscode`.

	| Publisher | Extension | Marketplace |
	| --- | --- | --- |
	HEADER

	while read -r extension; do
		publisher="${extension%%.*}"
		name="${extension#*.}"
		# shellcheck disable=SC2016  # the backticks are literal markdown
		printf '| %s | `%s` | [open](https://marketplace.visualstudio.com/items?itemName=%s) |\n' \
			"$publisher" "$name" "$extension"
	done < <(read_list "$list")

	printf '\n_%s extensions._\n' "$(read_list "$list" | wc -l)"
} >"$target"

info "Wrote $(read_list "$list" | wc -l) extensions to vscode-extensions.md"
