#!/usr/bin/env bash

# shellcheck source=latest-git-release.sh
source ~/dotfiles/scripts/latest-git-release.sh

GREEN='\e[32m'
NC='\e[0m'

echo -e "\n${GREEN}Setting Up NVM...${NC}"
version="$(latest_git_release "nvm-sh/nvm")" &&
  curl --progress-bar -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$version/install.sh" | bash &&
  export NVM_DIR="$HOME/.nvm" &&
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" &&                # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# Install nvm node versions
for version in lts/* node; do
  echo -e "\n${GREEN}Setting Up Node Version: $version...${NC}"
  nvm install "$version" &&
    xargs npm install -g < "$HOME"/dotfiles/lists/npm-packages.txt &&
    corepack enable &&
    corepack prepare yarn@stable --activate &&
    corepack prepare pnpm@latest --activate
done
nvm alias default lts/*
nvm use default
