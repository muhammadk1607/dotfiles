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

COLOR_PRIMARY='\[\e[0;36m\]'
COLOR_RESET='\[\e[0m\]'

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

		echo -n "$COLOR_PRIMARY]$COLOR_RESET"
	fi
}

function prompt() {
	PS1="\n$COLOR_PRIMARY┌─[$COLOR_RESET\[\e[1;33m\]\u$COLOR_RESET\[\e[1;36m\] @ $COLOR_RESET\[\e[1;33m\]\h$COLOR_RESET$COLOR_PRIMARY]─[$COLOR_RESET\[\e[1;34m\]\w$COLOR_RESET$COLOR_PRIMARY]$COLOR_PRIMARY─[$COLOR_RESET\[\e[0;31m\]\t$COLOR_RESET$COLOR_PRIMARY]$(git_prompt)$COLOR_RESET\n$COLOR_PRIMARY└─[$COLOR_RESET\[\e[1;37m\]\$$COLOR_RESET$COLOR_PRIMARY]─› $COLOR_RESET"
}

PROMPT_COMMAND=prompt

export EDITOR="code -w"

##############################################################################
# 02. Aliases                                                                #
##############################################################################

# simple update alias
alias update='sudo apt update && sudo apt full-upgrade -y'
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
