#!/usr/bin/env bash
# Complete `rdp` (see .bashrc) from the aliases of saved RustDesk peers.

_rdp_aliases() {
	local cur aliases
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"

	aliases="$(grep -rh "^alias = '" "$HOME/.config/rustdesk/peers" 2>/dev/null |
		sed -e "s/^alias = '//" -e "s/'\$//")"

	mapfile -t COMPREPLY < <(compgen -W "$aliases" -- "$cur")
	return 0
}

complete -F _rdp_aliases rdp
