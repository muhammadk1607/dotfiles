##############################################################################
# Sections:                                                                  #
#   01. General ................. General Bash behavior                      #
#   02. Aliases ................. Aliases                                    #
#   03. Functions ............... Helper functions                           #
#   04. Ruby .................... ruby installation                          #
##############################################################################

##############################################################################
# 01. General                                                                #
##############################################################################

WHITE='\[\e[1;37m\]'
RED='\[\e[0;31m\]'
YELLOW='\[\e[1;33m\]'
BLUE='\[\e[0;36m\]'
PURPLE='\[\e[1;34m\]'
COLOR_RESET='\[\e[0m\]'
LIGHT_PURPLE='\[\e[0;95m'

function git_prompt() {
	# GIT PROMPT
	COLOR_GIT_CLEAN='\[\e[0;32m\]'
	COLOR_GIT_MODIFIED='\[\e[0;31m\]'
	COLOR_GIT_STAGED='\[\e[0;33m\]'


	if [ -e ".git" ]; then
		branch_name=$(git symbolic-ref -q HEAD)
		branch_name=${branch_name##refs/heads/}
		branch_name=${branch_name:-HEAD}

		echo -n "-["

		if [[ $(git status 2> /dev/null | tail -n1) = *"nothing to commit"* ]]; then
		echo -n "$COLOR_GIT_CLEAN$branch_name$COLOR_RESET"
		elif [[ $(git status 2> /dev/null | head -n5) = *"Changes to be committed"* ]]; then
		echo -n "$COLOR_GIT_STAGED$branch_name$COLOR_RESET"
		else
		echo -n "$COLOR_GIT_MODIFIED$branch_name*$COLOR_RESET"
		fi

		echo -n "$BLUE]$COLOR_RESET"
	fi
}

function dir_details() {
	# Get number of files and the total space occupied
	echo "\$(/bin/ls -1 | /usr/bin/wc -l | /bin/sed 's: ::g') files, \$(/bin/ls -lah | /bin/grep -m 1 total | /bin/sed 's/total //')b"
}

function prompt() {
	PS1="\n$BLUE┌─[$COLOR_RESET$YELLOW\u$COLOR_RESET$BLUE @ $COLOR_RESET$YELLOW\h$COLOR_RESET$BLUE]─[$COLOR_RESET$PURPLE\w$COLOR_RESET$BLUE]$BLUE─[$COLOR_RESET$LIGHT_PURPLE$(dir_details)$COLOR_RESET$BLUE]$(git_prompt)$COLOR_RESET\n$BLUE└─[$COLOR_RESET$WHITE\$$COLOR_RESET$BLUE]─› $COLOR_RESET"
}

PROMPT_COMMAND=prompt

export EDITOR="code -w"

##############################################################################
# 02. Aliases                                                                #
##############################################################################

# simple update alias
alias update='sudo apt update && sudo apt full-upgrade -y --allow-downgrades && sudo apt autoremove'
# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ssh-hosts="grep -P \"^Host ([^*]+)$\" $HOME/.ssh/config | sed 's/Host //'"


##############################################################################
# 03. Functions                                                              #
##############################################################################

# Make a directory and move into it
mkcdir ()
{
	mkdir -p -- "$1" && cd -P -- "$1"
}

##############################################################################
# 04. Ruby                                                                   #
##############################################################################

if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
