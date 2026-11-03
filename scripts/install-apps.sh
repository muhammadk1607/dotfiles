#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Applications that are not in the Ubuntu archive and not on Flathub, so each
# needs its own upstream source.

step "Installing standalone applications"

## Slack — no apt repo, only versioned .deb downloads.
if have slack; then
	skip "slack"
else
	info "Installing Slack"
	version="$(curl -fsSL https://slack.com/downloads/linux | grep -Po -m 1 "(?<=Version )[0-9.]*" || true)"
	if [ -n "$version" ]; then
		install_deb_from_url "https://downloads.slack-edge.com/releases/linux/${version}/prod/x64/slack-desktop-${version}-amd64.deb" ||
			warn "Slack install failed"
	else
		warn "Could not determine the current Slack version — download it from https://slack.com/downloads/linux"
	fi
fi

## Zoom — no apt repo; the unversioned "latest" URL redirects to the current .deb.
if have zoom; then
	skip "zoom"
else
	info "Installing Zoom"
	install_deb_from_url "https://zoom.us/client/latest/zoom_amd64.deb" ||
		warn "Zoom install failed"
fi

## fastfetch — replaces neofetch, which was archived upstream in 2024.
## Not in the 24.04 archive (it lands in 24.10), so take the upstream .deb.
if have fastfetch; then
	skip "fastfetch"
else
	info "Installing fastfetch"
	if tag="$(latest_git_release "fastfetch-cli/fastfetch")"; then
		install_deb_from_url "https://github.com/fastfetch-cli/fastfetch/releases/download/${tag}/fastfetch-linux-amd64.deb" ||
			warn "fastfetch install failed"
	fi
fi

## onefetch — the ppa:o2sh/onefetch PPA has no noble build, so use the release .deb.
if have onefetch; then
	skip "onefetch"
else
	info "Installing onefetch"
	if tag="$(latest_git_release "o2sh/onefetch")"; then
		install_deb_from_url "https://github.com/o2sh/onefetch/releases/download/${tag}/onefetch_amd64.deb" ||
			warn "onefetch install failed"
	fi
fi

## AnyDesk — official apt repo, so it updates with everything else.
## Note: AnyDesk's screen capture is X11-oriented; under a Wayland session it
## may only share via the xdg-desktop-portal prompt, or need an Xorg login.
if have anydesk; then
	skip "anydesk"
else
	info "Installing AnyDesk"
	if add_apt_repo "anydesk" \
		"https://keys.anydesk.com/repos/DEB-GPG-KEY" \
		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main"; then
		apt_install anydesk || warn "AnyDesk install failed"
	else
		warn "Could not add the AnyDesk repository"
	fi
fi

## RustDesk — upstream .deb rather than the Flathub build: the native package
## registers the systemd service needed for unattended access, which the
## sandboxed flatpak cannot do.
if have rustdesk; then
	skip "rustdesk"
else
	info "Installing RustDesk"
	if tag="$(latest_git_release "rustdesk/rustdesk")"; then
		# Tags are currently bare (1.4.9); tolerate a v prefix if that changes.
		version="${tag#v}"
		install_deb_from_url "https://github.com/rustdesk/rustdesk/releases/download/${tag}/rustdesk-${version}-x86_64.deb" ||
			warn "RustDesk install failed"
	fi
fi

## install_portable_app <user/repo> <binary-name> — install a release tarball
## into ~/.local. The tarball's *-portable.txt marker must sit beside the binary,
## or the in-app updater refuses to run; the .deb and .flatpak releases have no
## update source at all.
install_portable_app() {
	local repo="$1" name="$2"
	local bin="$HOME/.local/bin/$name"
	local tag tmp
	tag="$(latest_git_release "$repo")" || return 1

	local archive="${name}-${tag}-x86_64-unknown-linux-gnu"
	local url="https://github.com/${repo}/releases/download/${tag}"
	tmp="$(mktemp -d)"
	# shellcheck disable=SC2064  # expand $tmp now, not at trap time
	trap "rm -rf '$tmp'" RETURN
	curl -fsSL "${url}/${archive}.tar.gz" -o "${tmp}/${archive}.tar.gz" || { err "Download failed: ${archive}.tar.gz"; return 1; }
	curl -fsSL "${url}/checksums.txt" -o "${tmp}/checksums.txt" || { err "Download failed: checksums.txt"; return 1; }
	(cd "$tmp" && grep " ${archive}.tar.gz\$" checksums.txt | sha256sum -c --quiet -) || { err "Checksum failed: ${archive}.tar.gz"; return 1; }
	tar xzf "${tmp}/${archive}.tar.gz" -C "$tmp" || return 1

	local src="${tmp}/${archive}"
	install -Dm755 "${src}/${name}" "$bin"
	install -Dm644 "${src}/${name}-portable.txt" "${bin}-portable.txt"
	install -Dm644 "${src}/packaging/icons/${name}.svg" "$HOME/.local/share/icons/hicolor/scalable/apps/${name}.svg"
	# The launcher may not have ~/.local/bin on its PATH, so use the full path.
	mkdir -p "$HOME/.local/share/applications"
	sed -E "s|^Exec=${name}( \|\$)|Exec=\"${bin}\"\1|" "${src}/packaging/applications/${name}.desktop" >"$HOME/.local/share/applications/${name}.desktop"
	update-desktop-database "$HOME/.local/share/applications" &>/dev/null || true
}

## install_dracula_theme <binary-name> — add the palette from config/, and select
## it only on a machine with no settings yet, so a later choice in the app sticks.
## The apps ignore symlinked palettes, so this has to be a copy.
install_dracula_theme() {
	local name="$1"
	local dir="$HOME/.config/$name"
	install -d -m 700 "$dir" "$dir/themes"
	install -m 644 "$DOTFILES_ROOT/config/$name/themes/Dracula.json" "$dir/themes/Dracula.json"
	if [ ! -e "$dir/settings.json" ]; then
		echo '{ "custom_theme": "Dracula.json" }' >"$dir/settings.json"
		info "Selected the Dracula theme for $name"
	fi
}

## Spotifast
if [ -x "$HOME/.local/bin/spotifast" ]; then
	skip "spotifast"
else
	info "Installing Spotifast"
	# Open spotify: links here.
	if install_portable_app "crmne/spotifast" "spotifast"; then
		xdg-mime default spotifast.desktop x-scheme-handler/spotify
	else
		warn "Spotifast install failed"
	fi
fi
install_dracula_theme "spotifast"

## ZapFast
if [ -x "$HOME/.local/bin/zapfast" ]; then
	skip "zapfast"
else
	info "Installing ZapFast"
	install_portable_app "crmne/zapfast" "zapfast" || warn "ZapFast install failed"
fi
install_dracula_theme "zapfast"

## Bun and Deno both append PATH lines to ~/.bashrc. That file is a symlink into
## this repo, and section 04 of .bashrc already puts both on PATH, so an append
## only duplicates those lines and hardcodes an absolute home directory into a
## tracked file. Deno takes a flag; Bun has none, so snapshot and restore.
preserve_bashrc() {
	bashrc_backup="$(mktemp)"
	[ -e "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$bashrc_backup"
}

restore_bashrc() {
	# cp through the symlink so the repo copy is what gets restored.
	if [ -s "$bashrc_backup" ] && ! cmp -s "$bashrc_backup" "$HOME/.bashrc"; then
		cp "$bashrc_backup" "$HOME/.bashrc"
		info "Reverted the PATH lines the installer appended to .bashrc"
	fi
	rm -f "$bashrc_backup"
}

## Bun
if have bun; then
	skip "bun"
else
	info "Installing Bun"
	preserve_bashrc
	curl -fsSL https://bun.sh/install | bash || warn "Bun install failed"
	restore_bashrc
fi

## Deno
if have deno; then
	skip "deno"
else
	info "Installing Deno"
	preserve_bashrc
	curl -fsSL https://deno.land/install.sh | sh -s -- -y --no-modify-path ||
		warn "Deno install failed"
	restore_bashrc
fi
