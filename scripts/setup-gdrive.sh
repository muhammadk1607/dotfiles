#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=SCRIPTDIR/../lib/bitwarden.sh
source "$DOTFILES_ROOT/lib/bitwarden.sh"

# Sign rclone in to Google Drive and mount it at ~/GoogleDrive on every login.
#
# rclone's shared Google OAuth client is being retired during 2026, so this
# uses your own client, kept in Bitwarden as an item named
# $GDRIVE_CLIENT_ITEM with custom fields `client_id` and `client_secret`.
# Make one at https://rclone.org/drive/#making-your-own-client-id.
#
# GDRIVE_SCOPE picks the Drive access: drive.file (the default) sees only files
# rclone itself created; drive sees everything, but needs Google to verify an
# OAuth client that isn't in testing mode.

GDRIVE_CLIENT_ITEM="${GDRIVE_CLIENT_ITEM:-rclone-google-drive-client}"
GDRIVE_SCOPE="${GDRIVE_SCOPE:-drive.file}"
remote="gdrive"
unit="rclone-gdrive.service"

step "Google Drive"

have rclone || die "rclone isn't installed; run ./install.sh apps first"
apt_install fuse3

signed_in() {
	rclone config show "$remote" 2>/dev/null | grep -q '^token'
}

if signed_in; then
	skip "rclone remote $remote"
else
	if [ ! -t 0 ]; then
		warn "Signing in to Google needs a terminal and a browser; skipping. Run ./install.sh gdrive later."
		exit 0
	fi

	client_id='' client_secret=''
	ensure_bw
	bw_unlock
	if item="$(bw get item "$GDRIVE_CLIENT_ITEM" 2>/dev/null)"; then
		client_id="$(jq -r '.fields[]? | select(.name == "client_id").value' <<<"$item")"
		client_secret="$(jq -r '.fields[]? | select(.name == "client_secret").value' <<<"$item")"
	fi
	if [ -z "$client_id" ] || [ -z "$client_secret" ]; then
		warn "No '$GDRIVE_CLIENT_ITEM' item with client_id and client_secret fields in Bitwarden."
		warn "Falling back to rclone's shared client, which stops working during 2026."
	fi

	# Write the remote directly rather than through `rclone config create`,
	# which would put the client secret in argv (readable in /proc). printf is
	# a shell builtin, so the secret never reaches a process's arguments.
	config="$(rclone config file | tail -1)"
	install -d -m 700 "$(dirname "$config")"
	rclone config delete "$remote" >/dev/null 2>&1 || true
	(
		umask 077
		printf '\n[%s]\ntype = drive\nscope = %s\n' "$remote" "$GDRIVE_SCOPE"
		if [ -n "$client_id" ] && [ -n "$client_secret" ]; then
			printf 'client_id = %s\nclient_secret = %s\n' "$client_id" "$client_secret"
		fi
	) >>"$config"
	chmod 600 "$config"
	unset client_id client_secret item

	info "Sign in to your Google account in the browser window that opens"
	rclone config reconnect "$remote:"
	signed_in || die "Google Drive sign-in didn't finish; run ./install.sh gdrive to retry"
fi

step "Mounting Google Drive at ~/GoogleDrive"
install -Dm644 "$DOTFILES_ROOT/config/systemd/$unit" "$HOME/.config/systemd/user/$unit"
systemctl --user daemon-reload
systemctl --user enable --now "$unit"
info "Mounted; it remounts on every login"
