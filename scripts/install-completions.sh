#!/usr/bin/env bash

################
# Completeions #
################

GREEN='\e[32m'
NC='\e[0m'
COMPLETIONS_DIR=~/.config/bash-completion/completions

echo -e "\n${GREEN}Setting Up Completions...${NC}\n"

# Create bash-completion user directory
mkdir -p $COMPLETIONS_DIR

echo -e "\n${GREEN}Copying from completions folder...${NC}"
cp -rsTvf ~/dotfiles/completions $COMPLETIONS_DIR

echo -e "\n${GREEN}Add Docker Completions...${NC}"
curl --progress-bar https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker -o $COMPLETIONS_DIR/docker

echo -e "\n${GREEN}Add Docker-Compose Completions...${NC}"
curl --progress-bar https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose -o $COMPLETIONS_DIR/docker-compose

echo -e "\n${GREEN}Add Git Completions...${NC}"
curl --progress-bar https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o $COMPLETIONS_DIR/git

echo -e "\n${GREEN}Add Yarn Completions...${NC}"
curl --progress-bar https://raw.githubusercontent.com/dsifford/yarn-completion/master/yarn-completion.bash -o $COMPLETIONS_DIR/yarn

echo -e "\n${GREEN}Adding NVM Completions...${NC}"
curl --progress-bar https://raw.githubusercontent.com/nvm-sh/nvm/master/bash_completion -o $COMPLETIONS_DIR/nvm

echo -e "\n${GREEN}Adding NPM Completions...${NC}"
npm completion >$COMPLETIONS_DIR/npm

echo -e "\n${GREEN}Adding Deno Completions...${NC}"
deno completions bash >$COMPLETIONS_DIR/deno

echo -e "\n${GREEN}Adding Gitub CLI Completions...${NC}"
gh completion -s bash > $COMPLETIONS_DIR/gh

echo -e "\n${GREEN}Adding PNPM Completions...${NC}"
pnpm completion bash > $COMPLETIONS_DIR/pnpm

# TODO Add Bash Completion for the following
# - [ ] ruby
# - [ ] rails
# - [x] rbenv
# - [ ] gem
# - [ ] bundler
# - [ ] rake
# - [ ] pip
# - [ ] pipenv
# - [ ] python
