#!/usr/bin/env bash
#
# Bitwarden helpers shared by scripts/backup-ssh.sh and scripts/restore-ssh.sh.
# Source it after lib/common.sh.
#
# ~/.ssh lives in the vault as one Secure Note per file, in a folder named
# $BW_SSH_FOLDER. Notes cap out around 10k encrypted characters, so a file
# bigger than $BW_CHUNK (known_hosts, typically) is split at line boundaries
# into "name [1/3]", "name [2/3]", ... and joined again on restore.
#
# Secrets only ever travel through pipes and shell variables: never argv
# (readable in /proc), never a temp file, never a here-string (bash spills
# large ones to $TMPDIR).

BW_SSH_FOLDER="${BW_SSH_FOLDER:-SSH}"
export BW_CHUNK=6000

# ensure_bw — put the Bitwarden CLI on PATH, installing it through mise.
ensure_bw() {
	if ! have bw; then
		ensure_mise
		if ! mise which bw >/dev/null 2>&1; then
			info "Installing the Bitwarden CLI through mise"
			mise --yes use -g bitwarden@latest >/dev/null
		fi
		eval "$(mise env -s bash)"
	fi
	have bw || die "Could not install the Bitwarden CLI"
	have jq || apt_install jq
}

# bw_unlock — log in or unlock as needed and export BW_SESSION.
# Prompts (email, master password, 2FA) come from bw itself, on the terminal.
# If this function did the unlocking, the vault is locked again on exit.
bw_unlock() {
	local status
	status="$(bw status | jq -r .status)"
	case "$status" in
		unlocked) ;;
		unauthenticated)
			[ -t 0 ] || die "Bitwarden login needs an interactive terminal"
			# Self-hosted or EU vault: BW_SERVER=https://vault.bitwarden.eu
			if [ -n "${BW_SERVER:-}" ]; then
				bw config server "$BW_SERVER" >/dev/null
			fi
			step "Logging in to Bitwarden"
			BW_SESSION="$(bw login --raw)" || die "Bitwarden login failed"
			trap 'bw lock >/dev/null 2>&1 || true' EXIT
			;;
		locked)
			[ -t 0 ] || die "Unlocking Bitwarden needs an interactive terminal"
			step "Unlocking Bitwarden"
			BW_SESSION="$(bw unlock --raw)" || die "Bitwarden unlock failed"
			trap 'bw lock >/dev/null 2>&1 || true' EXIT
			;;
		*) die "Unexpected Bitwarden status: $status" ;;
	esac
	export BW_SESSION
	bw sync >/dev/null || die "Bitwarden sync failed"
}

# shellcheck disable=SC2120  # --create is optional
# bw_folder_id [--create] — id of the SSH folder, empty if it doesn't exist.
bw_folder_id() {
	local id
	id="$(bw list folders | jq -r --arg n "$BW_SSH_FOLDER" '[.[] | select(.name == $n)][0].id // empty')"
	if [ -z "$id" ] && [ "${1:-}" = "--create" ]; then
		id="$(jq -n --arg n "$BW_SSH_FOLDER" '{name: $n}' | bw encode | bw create folder | jq -r .id)"
	fi
	printf '%s' "$id"
}
