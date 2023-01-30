#!/usr/bin/env bash

################
# Completeions #
################

GREEN='\e[32m'
NC='\e[0m'

echo -e "\n${GREEN}Setting Up Completions...${NC}\n"

# Create bash-completion user directory
mkdir -p ~/.config/bash-completion/completions

echo -e "\n${GREEN}Copying from completions folder...${NC}"
cp -rsTvf ~/dotfiles/completions ~/.config/bash-completion

echo -e "\n${GREEN}Add Docker Completions...${NC}"
curl --progress-bar https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker -o ~/.config/bash-completion/completions/docker

echo -e "\n${GREEN}Add Docker-Compose Completions...${NC}"
curl --progress-bar https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose -o ~/.config/bash-completion/completions/docker-compose

echo -e "\n${GREEN}Add Git Completions...${NC}"
curl --progress-bar https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.config/bash-completion/completions/git

echo -e "\n${GREEN}Add Yarn Completions...${NC}"
curl --progress-bar https://raw.githubusercontent.com/dsifford/yarn-completion/master/yarn-completion.bash -o ~/.config/bash-completion/completions/yarn

echo -e "\n${GREEN}Adding NVM Completions...${NC}"
curl --progress-bar https://raw.githubusercontent.com/nvm-sh/nvm/master/bash_completion -o ~/.config/bash-completion/completions/nvm

echo -e "\n${GREEN}Adding NPM Completions...${NC}"
npm completion >~/.config/bash-completion/completions/npm

echo -e "\n${GREEN}Adding Deno Completions...${NC}"
deno completions bash >~/.config/bash-completion/completions/deno

echo -e "\n${GREEN}Adding Gitub CLI Completions...${NC}"
gh completion -s bash > ~/.config/bash-completion/completions/gh

echo -e "\n${GREEN}Adding PNPM Completions...${NC}"
pnpm install-completion bash &&
  mv dot/.bashrc .bashrc-old &&
  head -n -4 .bashrc-old >dot/.bashrc &&
  if grep -q '[ -f  ] && . ~/.config/tabtab/bash/__tabtab.bash || true' ~/.config/bash-completion/completions/pnpm; then
    echo 'pnpm completion is already added'
  else
    echo 'Added pnpm completions'
    tail -n -4 .bashrc-old >>~/.config/bash-completion/completions/pnpm
  fi &&
  rm .bashrc-old



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
