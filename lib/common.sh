#!/usr/bin/env bash
#
# Shared helpers for every script in this repository.
# Source it, don't execute it:
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Resolve the repository root from this file's location, so scripts work no
# matter which directory they are invoked from.
DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_ROOT

GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
BLUE='\e[34m'
NC='\e[0m'

step() { echo -e "\n${GREEN}==>${NC} ${GREEN}$*${NC}"; }
info() { echo -e "    ${BLUE}·${NC} $*"; }
warn() { echo -e "    ${YELLOW}!${NC} $*" >&2; }
err()  { echo -e "    ${RED}✗${NC} $*" >&2; }
skip() { echo -e "    ${BLUE}·${NC} $* — already present, skipping"; }

# have <command> — is this command on PATH?
have() { command -v "$1" >/dev/null 2>&1; }

# die <message> — print and exit non-zero.
die() { err "$*"; exit 1; }

# Guard against running the whole thing as root; individual steps call sudo.
require_not_root() {
	[ "${EUID:-$(id -u)}" -ne 0 ] || die "Run this as your normal user, not root. Individual steps will call sudo."
}

# Ask for sudo once up front and keep the timestamp alive, so a long install
# doesn't stall waiting for a password halfway through.
keep_sudo_alive() {
	sudo -v || die "sudo is required"
	while true; do
		sudo -n true
		sleep 60
		kill -0 "$$" 2>/dev/null || exit
	done 2>/dev/null &
}

# apt_install <package>... — install only what is missing, quietly.
apt_install() {
	local missing=()
	local pkg
	for pkg in "$@"; do
		dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "^install ok installed$" || missing+=("$pkg")
	done
	if [ ${#missing[@]} -eq 0 ]; then
		return 0
	fi
	info "Installing: ${missing[*]}"
	sudo apt-get install -y --no-install-recommends "${missing[@]}"
}

# add_apt_repo <name> <key-url> <repo-line>
# Installs a signing key into /etc/apt/keyrings and writes a .list entry.
# Idempotent: re-running refreshes the key but does not duplicate sources.
add_apt_repo() {
	local name="$1" key_url="$2" repo_line="$3"
	local keyring="/etc/apt/keyrings/${name}.gpg"
	local list="/etc/apt/sources.list.d/${name}.list"

	sudo install -d -m 0755 /etc/apt/keyrings
	if [ ! -s "$keyring" ]; then
		info "Adding signing key for ${name}"
		# Fetch to a temp file first: piping curl straight into gpg hides a
		# failed download, leaving an empty keyring and an unusable source.
		local tmp_key
		tmp_key="$(mktemp)"
		if ! curl -fsSL "$key_url" -o "$tmp_key" || [ ! -s "$tmp_key" ]; then
			rm -f "$tmp_key"
			err "Could not download the signing key for ${name}"
			return 1
		fi
		# Dearmor as the user, then install with sudo — sudo does not apply to
		# a shell redirect, so `sudo gpg -o "$keyring"` would need the redirect
		# handled separately anyway.
		if ! gpg --dearmor --yes -o "${tmp_key}.gpg" <"$tmp_key"; then
			rm -f "$tmp_key" "${tmp_key}.gpg"
			err "Invalid signing key for ${name}"
			return 1
		fi
		sudo install -m 0644 "${tmp_key}.gpg" "$keyring"
		rm -f "$tmp_key" "${tmp_key}.gpg"
	fi
	if [ ! -f "$list" ] || ! grep -qF "$repo_line" "$list"; then
		info "Adding apt source for ${name}"
		echo "$repo_line" | sudo tee "$list" >/dev/null
		sudo apt-get update -qq
	fi
}

# install_deb_from_url <url> — download to a temp dir and install, always cleaning up.
install_deb_from_url() {
	local url="$1"
	local tmp
	tmp="$(mktemp -d)"
	# shellcheck disable=SC2064  # expand $tmp now, not at trap time
	trap "rm -rf '$tmp'" RETURN
	curl -fsSL "$url" -o "$tmp/package.deb" || { err "Download failed: $url"; return 1; }
	sudo apt-get install -y "$tmp/package.deb"
}

# latest_git_release <user/repo> — newest release tag, e.g. "v1.2.3".
# Uses gh when authenticated (higher rate limit), else the public API.
latest_git_release() {
	local repo="$1" tag=''
	if have gh && gh auth status >/dev/null 2>&1; then
		tag="$(gh api "repos/${repo}/releases/latest" --jq .tag_name 2>/dev/null)"
	fi
	if [ -z "$tag" ]; then
		tag="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null |
			grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
	fi
	[ -n "$tag" ] || { err "Could not resolve latest release for ${repo}"; return 1; }
	echo "$tag"
}

# parse_update_flag "$@" — for scripts that can either install or update.
# With no argument (./install.sh) they install what's missing and update what's
# there. With --update (the `update` shell function) they only refresh what is
# already installed, so `update` never pulls in something you chose to skip.
parse_update_flag() {
	UPDATE_ONLY=false
	case "${1:-}" in
		"") ;;
		--update) UPDATE_ONLY=true ;;
		*) die "Unknown option: $1 (the only option is --update)" ;;
	esac
}

# deb_version <package> — the installed version, or nothing if not installed.
deb_version() {
	{ dpkg-query -W -f='${db:Status-Status} ${Version}' "$1" 2>/dev/null || true; } | sed -n 's/^installed //p'
}

# install_github_deb <package> <user/repo> <asset>
# Install or update an app published as a .deb on GitHub releases. Such apps add
# no apt source, so `apt full-upgrade` never sees a newer version.
# In <asset>, {version} is the release tag without a leading v, {tag} the tag.
# Honours UPDATE_ONLY (see parse_update_flag).
install_github_deb() {
	local package="$1" repo="$2" asset="$3"
	local installed tag version
	installed="$(deb_version "$package")"
	if [ -z "$installed" ] && [ "${UPDATE_ONLY:-false}" = true ]; then
		return 0
	fi

	tag="$(latest_git_release "$repo")" || return 1
	version="${tag#v}"
	# Some packages add a Debian revision (onefetch is 2.28.1-1); tags never do.
	if [ "$installed" = "$version" ] || [ "${installed%-*}" = "$version" ]; then
		info "$package $installed is up to date"
		return 0
	fi

	asset="${asset//\{version\}/$version}"
	asset="${asset//\{tag\}/$tag}"
	info "Installing $package $version${installed:+ (replacing $installed)}"
	install_deb_from_url "https://github.com/${repo}/releases/download/${tag}/${asset}"
}

# ensure_mise — install mise from its apt repo if it is missing. Shared by the
# mise step and by anything earlier in the run that needs a mise-managed CLI.
ensure_mise() {
	have mise && return 0
	add_apt_repo "mise" \
		"https://mise.jdx.dev/gpg-key.pub" \
		"deb [signed-by=/etc/apt/keyrings/mise.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main"
	apt_install mise
}

# read_list <file> — emit list entries, ignoring blank lines and # comments.
read_list() {
	sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
}

# is_cosmic — are we in a COSMIC session? Desktop steps are skipped if not.
is_cosmic() {
	[[ "${XDG_CURRENT_DESKTOP:-}" == *COSMIC* ]]
}
