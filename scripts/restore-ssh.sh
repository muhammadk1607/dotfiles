#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=SCRIPTDIR/../lib/bitwarden.sh
source "$DOTFILES_ROOT/lib/bitwarden.sh"

# Restore ~/.ssh from the Bitwarden vault (see scripts/backup-ssh.sh).
#
#   ./scripts/restore-ssh.sh           restore missing files, keep local ones
#   ./scripts/restore-ssh.sh --force   also replace files that differ, keeping
#                                      the local copy as <name>.backup.<date>

force=0
[ "${1:-}" = "--force" ] && force=1

ssh_dir="$HOME/.ssh"

step "Restoring $ssh_dir from Bitwarden"

if [ -z "${BW_SESSION:-}" ] && [ ! -t 0 ]; then
	warn "No terminal for the Bitwarden prompts — skipping. Run ./install.sh ssh-restore later."
	exit 0
fi

ensure_bw
bw_unlock

folder_id="$(bw_folder_id)"
if [ -z "$folder_id" ]; then
	warn "No '$BW_SSH_FOLDER' folder in the vault — nothing to restore."
	warn "Run scripts/backup-ssh.sh (or ssh-backup) on a machine that has your keys."
	exit 0
fi
items="$(bw list items --folderid "$folder_id")"

# Group "name [i/n]" chunks back into files and check every part is present.
# Names are validated so a vault item can never write outside ~/.ssh.
# shellcheck disable=SC2016
group_jq='
	map(select(.type == 2)
		| .name as $name
		| ($name | capture("^(?<file>.+) \\[(?<i>[0-9]+)/(?<n>[0-9]+)\\]$")
			// {file: $name, i: "1", n: "1"})
		+ {notes: (.notes // "")})
	| group_by(.file)
	| map({
		file: .[0].file,
		parts: sort_by(.i | tonumber),
		ok: (
			(.[0].file | test("^[A-Za-z0-9_@+-][A-Za-z0-9._@+-]*$"))
			and (map(.n) | unique | length == 1)
			and ((sort_by(.i | tonumber) | map(.i | tonumber)) == [range(1; (.[0].n | tonumber) + 1)])
		)
	})'

listing="$(printf '%s' "$items" | jq -r "$group_jq"' | .[] | "\(.ok)\t\(.file)"')" ||
	die "Could not read the '$BW_SSH_FOLDER' folder"
mapfile -t entries < <(printf '%s' "$listing" | sed '/^$/d')
[ ${#entries[@]} -gt 0 ] || { warn "The '$BW_SSH_FOLDER' folder is empty"; exit 0; }

install -d -m 0700 "$ssh_dir"
umask 077

restored=0 kept=0 same=0 bad=0
for entry in "${entries[@]}"; do
	ok="${entry%%$'\t'*}"
	file="${entry#*$'\t'}"
	if [ "$ok" != true ]; then
		err "Skipping '$file': unsafe name or missing chunks"
		bad=$((bad + 1))
		continue
	fi

	target="$ssh_dir/$file"
	tmp="$(mktemp "$ssh_dir/.restore.XXXXXX")"
	# shellcheck disable=SC2016
	if ! printf '%s' "$items" | jq -j --arg f "$file" "$group_jq"' | .[] | select(.file == $f) | .parts | map(.notes) | add' >"$tmp"; then
		rm -f "$tmp"
		die "Could not decode '$file'"
	fi

	if [ -e "$target" ]; then
		if cmp -s "$tmp" "$target"; then
			rm -f "$tmp"
			same=$((same + 1))
			continue
		fi
		if [ "$force" -eq 0 ]; then
			rm -f "$tmp"
			warn "$file differs from the vault — kept the local copy (--force to replace)"
			kept=$((kept + 1))
			continue
		fi
		backup="$target.backup.$(date +%Y%m%d%H%M%S)"
		mv "$target" "$backup"
		warn "$file differed — local copy moved to $(basename "$backup")"
	fi

	case "$file" in
		*.pub) chmod 0644 "$tmp" ;;
		*) chmod 0600 "$tmp" ;;
	esac
	mv "$tmp" "$target"
	info "restored $file"
	restored=$((restored + 1))
done

info "$restored restored, $same already up to date, $kept kept local, $bad skipped"
[ "$bad" -eq 0 ] || exit 1
