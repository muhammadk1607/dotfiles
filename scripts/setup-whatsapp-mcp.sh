#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# WhatsApp MCP server (github.com/lharries/whatsapp-mcp) for Claude Code.
#
# Two parts: a Go bridge that stays logged in to WhatsApp and keeps the session
# and messages in whatsapp-bridge/store/ (run by the whatsapp-bridge systemd
# user service), and a Python MCP server that Claude Code starts through uv.
#
# Upstream is unmaintained, so config/whatsapp-mcp/bridge.patch is applied on
# top: a current whatsmeow (WhatsApp rejects the pinned one) and the REST API
# bound to 127.0.0.1 instead of every interface.
#
# WHATSAPP_MCP_DIR  where the repo lives (default ~/workspace/whatsapp-mcp)
# WHATSAPP_MCP_REPO where to clone it from

WHATSAPP_MCP_DIR="${WHATSAPP_MCP_DIR:-$HOME/workspace/whatsapp-mcp}"
WHATSAPP_MCP_REPO="${WHATSAPP_MCP_REPO:-https://github.com/lharries/whatsapp-mcp.git}"
patch="$DOTFILES_ROOT/config/whatsapp-mcp/bridge.patch"
unit="whatsapp-bridge.service"
bridge="$WHATSAPP_MCP_DIR/whatsapp-bridge"

# Both Claude Code accounts: the default one and `claude-work` (see .bashrc).
CLAUDE_CONFIG_DIRS=("" "$HOME/.claude-work")

# pipx and the claude installer put uv and claude here.
export PATH="$HOME/.local/bin:$PATH"
# go comes from mise, which only .bashrc puts on PATH.
if ! have go && have mise; then
	eval "$(mise env -s bash)"
fi

step "WhatsApp MCP"

missing=()
for tool in go uv git claude; do
	have "$tool" || missing+=("$tool")
done
if [ ${#missing[@]} -gt 0 ]; then
	err "Missing: ${missing[*]}"
	info "go comes from the mise step, uv from the apt step (pipx), claude from the claude step."
	exit 1
fi

patch_applied() { git -C "$WHATSAPP_MCP_DIR" apply --reverse --check "$patch" 2>/dev/null; }

if [ -d "$WHATSAPP_MCP_DIR/.git" ]; then
	# Take the patch off so the pull can't conflict with it.
	patch_applied && git -C "$WHATSAPP_MCP_DIR" apply --reverse "$patch"
	if [ -n "$(git -C "$WHATSAPP_MCP_DIR" status --porcelain --untracked-files=no)" ]; then
		warn "$WHATSAPP_MCP_DIR has local changes beyond bridge.patch; not pulling"
	else
		info "Pulling $WHATSAPP_MCP_DIR"
		git -C "$WHATSAPP_MCP_DIR" pull --ff-only -q || warn "Pull failed; building what's checked out"
	fi
else
	info "Cloning into $WHATSAPP_MCP_DIR"
	mkdir -p "$(dirname "$WHATSAPP_MCP_DIR")"
	git clone -q "$WHATSAPP_MCP_REPO" "$WHATSAPP_MCP_DIR"
fi

if ! patch_applied; then
	git -C "$WHATSAPP_MCP_DIR" apply "$patch" ||
		die "bridge.patch no longer applies to upstream; refresh it from a working checkout with git diff"
fi

step "Building the WhatsApp bridge"
before="$(sha256sum "$bridge/whatsapp-bridge" 2>/dev/null || true)"
# go-sqlite3 needs cgo, so this needs gcc (build-essential, from the apt step).
(cd "$bridge" && CGO_ENABLED=1 go build -o whatsapp-bridge .)
after="$(sha256sum "$bridge/whatsapp-bridge")"
info "Built $bridge/whatsapp-bridge"

step "Registering the WhatsApp MCP server with Claude Code"
for dir in "${CLAUDE_CONFIG_DIRS[@]}"; do
	label="${dir:-default config}"
	env_args=()
	[ -n "$dir" ] && env_args=("CLAUDE_CONFIG_DIR=$dir")
	if env "${env_args[@]}" claude mcp get whatsapp >/dev/null 2>&1; then
		skip "whatsapp MCP server ($label)"
	else
		env "${env_args[@]}" claude mcp add whatsapp --scope user -- \
			uv --directory "$WHATSAPP_MCP_DIR/whatsapp-mcp-server" run main.py >/dev/null
		info "Registered whatsapp ($label)"
	fi
done

step "WhatsApp bridge service"

# Has the bridge been linked to a phone? Unpaired, it only prints a QR code
# nobody can scan from the journal, then exits.
paired() {
	local db="$bridge/store/whatsapp.db"
	[ -s "$db" ] && have python3 || return 1
	python3 -I -c '
import sqlite3, sys
db = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True)
sys.exit(0 if db.execute("select count(*) from whatsmeow_device").fetchone()[0] else 1)
' "$db" 2>/dev/null
}

# Point the unit at WHATSAPP_MCP_DIR, escaped for sed.
dir_escaped="$(printf '%s' "$WHATSAPP_MCP_DIR" | sed 's/[\\|&]/\\&/g')"
install -d "$HOME/.config/systemd/user"
sed "s|%h/workspace/whatsapp-mcp|$dir_escaped|g" "$DOTFILES_ROOT/config/systemd/$unit" \
	>"$HOME/.config/systemd/user/$unit"
chmod 644 "$HOME/.config/systemd/user/$unit"
systemctl --user daemon-reload

if systemctl --user is-active --quiet "$unit"; then
	systemctl --user enable --quiet "$unit"
	if [ "$before" != "$after" ]; then
		systemctl --user restart "$unit"
		info "Restarted on the new build"
	else
		info "Running"
	fi
elif pgrep -x whatsapp-bridge >/dev/null; then
	# Two bridges on one session fight over it and over port 8080.
	systemctl --user enable --quiet "$unit"
	warn "A bridge is already running outside systemd. Stop it, then:"
	warn "  systemctl --user start whatsapp-bridge"
elif paired; then
	systemctl --user enable --now --quiet "$unit"
	info "Started; it starts again on every login"
else
	systemctl --user enable --quiet "$unit"
	warn "Not linked to WhatsApp yet. Scan the QR code once, in the foreground:"
	warn "  cd $bridge && ./whatsapp-bridge"
	warn "When it says it's connected, Ctrl-C it and run:"
	warn "  systemctl --user start whatsapp-bridge"
fi
