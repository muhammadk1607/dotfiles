#!/usr/bin/env bash

GREEN='\e[32m'
NC='\e[0m'

# shellcheck source=latest-git-release.sh
source ~/dotfiles/scripts/latest-git-release.sh

# Install Docker
if ! command -v docker &>/dev/null; then
  echo -e "\n${GREEN}Installing Docker...${NC}"
  sudo apt -qq update &&
    sudo apt -qq install -y apt-transport-https ca-certificates curl gnupg lsb-release &&
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &&
    echo \
      "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list &&
    sudo apt -qq update &&
    sudo apt -qq install -y docker-ce docker-ce-cli containerd.io &&
    sudo usermod -aG docker "$USER"
fi

# Install Docker Compose
if ! command -v docker-compose &>/dev/null; then
  echo -e "\n${GREEN}Installing Docker Compose...${NC}"

  version="$(latest_git_release "docker/compose")" &&
    sudo curl -L "https://github.com/docker/compose/releases/download/${version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &&
    sudo chmod +x /usr/local/bin/docker-compose
fi
