#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

step "Setting up Antigravity"

if have antigravity; then
	skip "antigravity"
else
	add_apt_repo "antigravity" \
		"https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg" \
		"deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main"
	apt_install antigravity
fi

step "Installing mattpocock skills for Antigravity"

# Antigravity reads the same SKILL.md format Claude Code plugins use, just
# from a plain directory instead of a plugin — so mirror the repo's shipped
# skill folders (engineering/, productivity/) as symlinks rather than
# duplicating the mattpocock-skills plugin content.
#
# ~/.gemini/config/skills is the one global skills directory every Antigravity
# flavour (IDE, CLI, and the standalone app) reads, unlike ~/.gemini/skills or
# ~/.gemini/antigravity/skills which only some of them pick up.
skills_repo="$HOME/.cache/mattpocock-skills"
if [ -d "$skills_repo/.git" ]; then
	info "Updating mattpocock/skills"
	git -C "$skills_repo" pull --ff-only -q
else
	info "Cloning mattpocock/skills"
	git clone -q --depth 1 https://github.com/mattpocock/skills.git "$skills_repo"
fi

target="$HOME/.gemini/config/skills"
mkdir -p "$target"
for bucket in engineering productivity; do
	for skill_dir in "$skills_repo/skills/$bucket"/*/; do
		[ -d "$skill_dir" ] || continue
		ln -sfn "$skill_dir" "$target/$(basename "$skill_dir")"
	done
done
