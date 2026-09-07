#!/usr/bin/env bash
# Complete `ssh` from the Host aliases in ~/.ssh/config, ignoring patterns.

_ssh_hosts() {
	local cur hosts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"

	hosts="$(grep -h '^Host' ~/.ssh/config ~/.ssh/config.d/* 2>/dev/null |
		grep -v '[?*]' | cut -d ' ' -f 2-)"

	mapfile -t COMPREPLY < <(compgen -W "$hosts" -- "$cur")
	return 0
}

complete -F _ssh_hosts ssh scp sftp
