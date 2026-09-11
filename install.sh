#!/usr/bin/env bash
set -euo pipefail
############################################################################
# Provisions a Pop!_OS 24.04 (COSMIC) machine from scratch.
#
# Every step is idempotent, so this is safe to re-run to pick up changes.
#
#   ./install.sh                 run everything
#   ./install.sh --list          show the available steps
#   ./install.sh dotfiles mise   run only the named steps
#   ./install.sh --skip docker   run everything except the named steps
############################################################################

# shellcheck source=SCRIPTDIR/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

# Ordered list of steps: <name>:<script>
STEPS=(
	"dotfiles:link-dotfiles.sh"
	"apt:install-apt.sh"
	"gh:install-gh.sh"
	"ssh:generate-ssh-key.sh"
	"mise:install-mise.sh"
	"docker:install-docker.sh"
	"vscode:install-vscode.sh"
	"claude:install-claude.sh"
	"antigravity:install-antigravity.sh"
	"flatpak:install-flatpak.sh"
	"apps:install-apps.sh"
	"fonts:install-fonts.sh"
	"completions:install-completions.sh"
	"assets:move-assets.sh"
	"cosmic:setup-cosmic.sh"
	"system:setup-system.sh"
)

usage() {
	cat <<-EOF
	Usage: ./install.sh [--list] [--skip STEP]... [STEP...]

	With no arguments, every step runs in order.
	Naming steps runs only those. --skip excludes steps from a full run.

	Steps:
	EOF
	local entry
	for entry in "${STEPS[@]}"; do
		printf '  %-12s %s\n' "${entry%%:*}" "scripts/${entry#*:}"
	done
}

selected=()
skipped=()

while [ $# -gt 0 ]; do
	case "$1" in
		-h | --help) usage; exit 0 ;;
		--list) usage; exit 0 ;;
		--skip)
			[ $# -ge 2 ] || die "--skip needs a step name"
			skipped+=("$2")
			shift 2
			;;
		-*) die "Unknown option: $1 (try --help)" ;;
		*) selected+=("$1"); shift ;;
	esac
done

# Validate names up front so a typo fails immediately rather than 20 minutes in.
known_step() {
	local entry
	for entry in "${STEPS[@]}"; do
		[ "${entry%%:*}" = "$1" ] && return 0
	done
	return 1
}
for name in "${selected[@]}" "${skipped[@]}"; do
	known_step "$name" || die "Unknown step: $name (try --list)"
done

wants() {
	local name="$1" entry
	for entry in "${skipped[@]}"; do
		[ "$entry" = "$name" ] && return 1
	done
	[ ${#selected[@]} -eq 0 ] && return 0
	for entry in "${selected[@]}"; do
		[ "$entry" = "$name" ] && return 0
	done
	return 1
}

require_not_root
have curl || sudo apt-get install -y curl
keep_sudo_alive

failed=()
for entry in "${STEPS[@]}"; do
	name="${entry%%:*}"
	script="${entry#*:}"
	wants "$name" || continue

	if ! "$DOTFILES_ROOT/scripts/$script"; then
		err "Step '$name' failed"
		failed+=("$name")
	fi
done

echo
if [ ${#failed[@]} -gt 0 ]; then
	err "Finished with failures in: ${failed[*]}"
	err "Re-run just those with: ./install.sh ${failed[*]}"
	exit 1
fi

step "Done"
info "Open a new shell (or 'exec bash') to pick up the new environment."
if ! id -nG "$USER" | grep -qw docker; then
	info "Log out and back in to activate docker group membership."
fi
