#!/usr/bin/env bash
# shellcheck disable=SC2148

##############################################################################
# Sections:                                                                  #
#   01. General ................. Bash behaviour and the prompt              #
#   02. Aliases ................. Aliases                                    #
#   03. Functions ............... Helper functions                           #
#   04. Environment ............. PATH, runtimes and shell integrations      #
##############################################################################

# Only continue for interactive shells.
case $- in
	*i*) ;;
	*) return ;;
esac

##############################################################################
# 01. General                                                                #
##############################################################################

HISTCONTROL=ignoreboth:erasedups
HISTSIZE=100000
HISTFILESIZE=200000
shopt -s histappend checkwinsize globstar

WHITE='\[\e[1;37m\]'
YELLOW='\[\e[1;33m\]'
BLUE='\[\e[0;36m\]'
PURPLE='\[\e[1;34m\]'
COLOR_RESET='\[\e[0m\]'
NODE='\[\e[1;32m\]'
RUBY='\[\e[1;31m\]'
PYTHON='\[\e[1;36m\]'

git_prompt() {
	local branch status
	branch="$(git symbolic-ref --short -q HEAD 2>/dev/null)" || return

	# --porcelain is a stable, parseable format; the old version grepped
	# human-readable `git status` output, which breaks under other locales.
	status="$(git status --porcelain 2>/dev/null)"

	local COLOR_GIT_CLEAN='\[\e[0;32m\]'
	local COLOR_GIT_MODIFIED='\[\e[0;31m\]'
	local COLOR_GIT_STAGED='\[\e[0;33m\]'

	if [ -z "$status" ]; then
		printf -- '-[%s%s%s%s]%s' "$COLOR_GIT_CLEAN" "$branch" "$COLOR_RESET" "$BLUE" "$COLOR_RESET"
	elif grep -q '^[MADRC]' <<<"$status"; then
		printf -- '-[%s%s%s%s]%s' "$COLOR_GIT_STAGED" "$branch" "$COLOR_RESET" "$BLUE" "$COLOR_RESET"
	else
		printf -- '-[%s%s*%s%s]%s' "$COLOR_GIT_MODIFIED" "$branch" "$COLOR_RESET" "$BLUE" "$COLOR_RESET"
	fi
}

# Runtime versions are shown only in directories that actually use that
# runtime. Previously every prompt shell-outed to node, rbenv and python
# regardless, which cost three process spawns per prompt in every directory.
runtime_prompt() {
	local segments=''

	# Each segment needs both a project marker in the cwd and the runtime
	# actually installed, so the prompt never shows a half-empty version.
	if [ -e package.json ] || [ -e .nvmrc ] || [ -e node_modules ]; then
		local node_version
		node_version="$(node -v 2>/dev/null)" &&
			segments+="$BLUE─[$COLOR_RESET$NODE⬢  - ${node_version#v}$COLOR_RESET$BLUE]"
	fi
	if [ -e Gemfile ] || [ -e .ruby-version ]; then
		local ruby_version
		ruby_version="$(ruby -e 'print RUBY_VERSION' 2>/dev/null)" &&
			segments+="$BLUE─[$COLOR_RESET$RUBY⬘  - ${ruby_version}$COLOR_RESET$BLUE]"
	fi
	if [ -e pyproject.toml ] || [ -e requirements.txt ] || [ -e .python-version ] || [ -n "${VIRTUAL_ENV:-}" ]; then
		local python_version
		python_version="$(python --version 2>/dev/null)" &&
			segments+="$BLUE─[$COLOR_RESET$PYTHON🐍 - ${python_version#Python }$COLOR_RESET$BLUE]"
	fi

	printf '%s' "$segments"
}

prompt() {
	PS1="\n$BLUE┌─[$COLOR_RESET$YELLOW\u$COLOR_RESET$BLUE @ $COLOR_RESET$YELLOW\h$COLOR_RESET$BLUE]─[$COLOR_RESET$PURPLE\w$COLOR_RESET$BLUE]$(git_prompt)$(runtime_prompt)$COLOR_RESET\n$BLUE└─[$COLOR_RESET$WHITE\$$COLOR_RESET$BLUE]─› $COLOR_RESET"
}

PROMPT_COMMAND=prompt

export EDITOR="code -w"
export VISUAL="$EDITOR"

##############################################################################
# 02. Aliases                                                                #
##############################################################################

alias ll="eza -al --group-directories-first --icons"
alias la="eza -a --group-directories-first --icons"
alias l="eza --group-directories-first --icons"
alias lt="eza --tree --level=2 --icons"
alias ls="ls --color=auto"

alias ssh-hosts="grep -P \"^Host ([^*]+)$\" \$HOME/.ssh/config | sed 's/Host //'"
alias git-open="gh repo view --web"
alias apti="apt list --installed"
alias pn="pnpm"
alias pnx="pnpm dlx"
alias open="xdg-open"

# Ubuntu ships bat as batcat and fd as fdfind; install-apt.sh also symlinks
# them into /usr/local/bin, so these are just the preferred defaults.
alias bat="bat --paging=never --theme=Dracula"
alias cat="bat --plain --paging=never"

# Wayland clipboard
alias pbcopy="wl-copy"
alias pbpaste="wl-paste"

alias dc="docker compose"

# Work Claude Code account, kept in its own config dir so it logs in and
# stores history separately from the default (personal) `claude`.
alias claude-work='CLAUDE_CONFIG_DIR="$HOME/.claude-work" claude'

##############################################################################
# 03. Functions                                                              #
##############################################################################

# Update everything this machine installs.
update() {
	echo "› apt"
	sudo apt update &&
		sudo apt full-upgrade -y --allow-downgrades --fix-missing &&
		sudo apt autoremove -y || return

	if command -v flatpak >/dev/null; then
		echo "› flatpak"
		flatpak update -y
	fi

	if command -v mise >/dev/null; then
		echo "› mise"
		mise --yes self-update 2>/dev/null || true
		mise upgrade --bump
		mise --yes prune
	fi

	if command -v npm >/dev/null; then
		echo "› npm globals"
		npm-check -gu
	fi

	command -v deno >/dev/null && { echo "› deno"; deno upgrade; }
	command -v bun >/dev/null && { echo "› bun"; bun upgrade; }
	command -v pipx >/dev/null && { echo "› pipx"; pipx upgrade-all; }
	command -v gh >/dev/null && { echo "› gh extensions"; gh extension upgrade --all; }
	command -v tldr >/dev/null && { echo "› tldr"; tldr --update; }
}

# Make a directory and move into it
mkcdir() {
	mkdir -p -- "$1" && cd -P -- "$1" || return
}

# Kill whatever is listening on a TCP port
killport() {
	[ -n "${1:-}" ] || { echo "Usage: killport <port>"; return 1; }
	local pids
	pids="$(sudo fuser -n tcp "$1" 2>/dev/null)"
	if [ -z "$pids" ]; then
		echo "Nothing is listening on port $1"
		return 1
	fi
	# shellcheck disable=SC2086  # word splitting is intended: fuser returns a list
	sudo kill -9 $pids
}

# Local IPv4 addresses. Uses `ip`, which is always present, rather than
# `ifconfig` from net-tools.
local_ip() {
	ip -brief -family inet address show scope global | awk '{print $1": "$3}'
}

public_ip() {
	curl -s https://ipinfo.io/ip
	echo
}

# Recursively convert a directory of images to webp
cwebpdir() {
	if [ -z "${1:-}" ]; then
		echo "Usage: cwebpdir <directory>"
		return 1
	fi

	local file
	for file in "$1"/*; do
		if [ -f "$file" ]; then
			cwebp -m 6 -q 70 -mt -af -progress "$file" -o "${file%.*}.webp"
		elif [ -d "$file" ]; then
			cwebpdir "$file"
		fi
	done
}

mkv_to_mp4() {
	ffmpeg -i "$1" -c:v libx265 -crf 28 -c:a aac "${1%.*}.mp4"
}

webm_to_mp4() {
	ffmpeg -i "$1" -c:v libx264 -c:a aac "${1%.*}.mp4"
}

##############################################################################
# 04. Environment                                                            #
##############################################################################

# path_prepend <dir> — add to PATH only if it exists and is not already there.
path_prepend() {
	[ -d "$1" ] || return 0
	case ":$PATH:" in
		*":$1:"*) ;;
		*) PATH="$1:$PATH" ;;
	esac
}

path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"

# Bun
export BUN_INSTALL="$HOME/.bun"
path_prepend "$BUN_INSTALL/bin"

# Deno
export DENO_INSTALL="$HOME/.deno"
path_prepend "$DENO_INSTALL/bin"

# Turso
path_prepend "$HOME/.turso"

# Fly.io
export FLYCTL_INSTALL="$HOME/.fly"
path_prepend "$FLYCTL_INSTALL/bin"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
path_prepend "$PNPM_HOME"

export PATH

# mise manages node, ruby, python, java and gradle. It replaces nvm and rbenv,
# and picks up .nvmrc / .ruby-version / .tool-versions on cd, so the old
# `alias cd='cdnvm'` override is no longer needed.
if command -v mise >/dev/null; then
	eval "$(mise activate bash)"
fi

# JAVA_HOME follows mise when it manages java, otherwise the system JDK.
if command -v mise >/dev/null && mise which java >/dev/null 2>&1; then
	JAVA_HOME="$(dirname "$(dirname "$(mise which java)")")"
	export JAVA_HOME
elif [ -d /usr/lib/jvm/java-21-openjdk-amd64 ]; then
	export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
fi

# Android SDK
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
path_prepend "$ANDROID_HOME/platform-tools"
path_prepend "$ANDROID_HOME/tools"
export PATH

# Flutter's web target needs a Chromium-family browser; set it only if one is
# actually installed rather than hardcoding a path.
for browser in google-chrome chromium brave-browser vivaldi-stable; do
	if command -v "$browser" >/dev/null; then
		CHROME_EXECUTABLE="$(command -v "$browser")"
		export CHROME_EXECUTABLE
		break
	fi
done
unset browser

# Completions. bash-completion pulls in ~/.config/bash-completion/completions
# lazily, but sourcing these explicitly keeps the ones generated by
# scripts/install-completions.sh working for aliases too.
if [ -f /usr/share/bash-completion/bash_completion ]; then
	# shellcheck source=/dev/null
	. /usr/share/bash-completion/bash_completion
fi

shopt -s nullglob
for completion in "$HOME"/.config/bash-completion/completions/*; do
	# shellcheck source=/dev/null
	[ -r "$completion" ] && . "$completion"
done
shopt -u nullglob
unset completion

command -v direnv >/dev/null && eval "$(direnv hook bash)"
command -v zoxide >/dev/null && eval "$(zoxide init bash)"

# Machine-specific settings that should not be committed.
if [ -f "$HOME/.bash.profile" ]; then
	# shellcheck source=/dev/null
	. "$HOME/.bash.profile"
fi
