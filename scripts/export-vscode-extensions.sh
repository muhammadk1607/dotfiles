#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Snapshot the currently installed extensions back into the repo.
# This replaces the old DevTools-console scraping in scripts/get-extensions.js.

have code || die "code is not on PATH"

target="$DOTFILES_ROOT/lists/vscode-extensions.txt"
code --list-extensions | sort >"$target"

step "Wrote $(wc -l <"$target") extensions to lists/vscode-extensions.txt"
