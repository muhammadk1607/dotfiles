#!/usr/bin/env bash

GREEN='\e[32m'
NC='\e[0m'

echo -e "\n${GREEN}Setting Up SSH config...${NC}" &&
	ssh-keygen -t ed25519 -C "muhammadkhan1607@gmail.com" -f ~/.ssh/id-github -N "" &&
	eval "$(ssh-agent -s)" &&
	ssh-add ~/.ssh/id-github &&
	echo -e -n "${GREY}Enter a title for your new github ssh key:${NC} " &&
	read -r ssh_key_title &&
	gh ssh-key add ~/.ssh/id-github.pub -t "${ssh_key_title}"

[ ! -f "$HOME/.ssh/config" ] && cp ~/dotfiles/config/.ssh/* ~/.ssh/
