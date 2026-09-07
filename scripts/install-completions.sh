#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "Installing bash completions"

dir="$HOME/.config/bash-completion/completions"
mkdir -p "$dir"

# Completions checked into this repo.
for file in "$DOTFILES_ROOT"/completions/*; do
	[ -e "$file" ] || continue
	ln -sf "$file" "$dir/$(basename "${file%.sh}")"
done

# fetch <name> <url> — download a completion, keeping the old one on failure.
fetch() {
	local name="$1" url="$2"
	if curl -fsSL "$url" -o "$dir/.$name.tmp"; then
		mv "$dir/.$name.tmp" "$dir/$name"
		info "$name"
	else
		rm -f "$dir/.$name.tmp"
		warn "Could not fetch $name completions"
	fi
}

fetch git "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"

# generate <name> <command...> — write a completion a tool produces itself.
generate() {
	local name="$1"; shift
	if have "$1"; then
		if "$@" >"$dir/.$name.tmp" 2>/dev/null && [ -s "$dir/.$name.tmp" ]; then
			mv "$dir/.$name.tmp" "$dir/$name"
			info "$name"
		else
			rm -f "$dir/.$name.tmp"
			warn "Could not generate $name completions"
		fi
	fi
}

generate npm npm completion
generate deno deno completions bash
generate gh gh completion -s bash
generate pnpm pnpm completion bash
generate mise mise completion bash
generate docker docker completion bash
generate bun bun completions bash
generate rustup rustup completions bash

# Note: docker-compose is a `docker` subcommand now, so its completions come
# with the docker completion above rather than as a separate file.
rm -f "$dir/docker-compose"
