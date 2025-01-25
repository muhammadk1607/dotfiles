#!/usr/bin/env bash
############################
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
# It also installs the system programming essentials for myself
# It installs all the packages I need for my development environment
############################

# shellcheck source=SCRIPTDIR/scripts/latest-git-release.sh
source scripts/latest-git-release.sh

# shellcheck source=/dev/null

GREEN='\e[32m'
NC='\e[0m'

# Setup Dotfiles
echo -e "\n${GREEN}Creating symlinks for dotfiles...${NC}"
cp -rsTvf ~/dotfiles/dot ~/

# Check if curl is installed, if not install it
type -p curl >/dev/null || sudo apt install curl -y

# Check if xargs is installed, if not install it
type -p xargs >/dev/null || sudo apt install xargs -y

# Install apt packages
echo -e "\n${GREEN}Setting Up APT Packages...${NC}"
xargs sudo apt install -y < lists/apt-packages.txt

# Install pip packages
echo -e "\n${GREEN}Installing PIP Packages...${NC}"
pip install -r lists/pip-packages.txt

# Install onefetch https://github.com/o2sh/onefetch
sudo add-apt-repository ppa:o2sh/onefetch
sudo apt-get update
sudo apt install onefetch

# install gh cli
if ! command -v gh &>/dev/null; then
	echo -e "\n${GREEN}Installing GitHub CLI...${NC}"
	(type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y
fi

# Generate & Add SSH key for github access
./scripts/generate-ssh-key.sh

# Install or update nvm
./scripts/install-nvm.sh
source ~/.bashrc

# Install docker and docker-compose
# ? This will require a reboot for the user to be added to the docker group
./scripts/install-docker.sh

# Install rbenv and latest ruby
./scripts/install-rbenv.sh

# Install Bun
curl -fsSL https://bun.sh/install | bash

# Install Deno
if ! command -v deno &>/dev/null; then
	echo -e "\n${GREEN}Installing Deno...${NC}"
	curl -fsSL https://deno.land/install.sh | sh &&
		export DENO_INSTALL="$HOME/.deno" &&
		export PATH="$DENO_INSTALL/bin:$PATH"
fi

# install vs code
./scripts/install-vscode.sh

# install remmina
if ! command -v remmina &>/dev/null; then
	echo -e "\n${GREEN}Installing Remmina...${NC}"
	sudo apt-add-repository ppa:remmina-ppa-team/remmina-next &&
		sudo apt update &&
		sudo apt install remmina remmina-plugin-rdp remmina-plugin-secret
fi

# install obs studio
if ! command -v obs &>/dev/null; then
	echo -e "\n${GREEN}Installing OBS Studio...${NC}"
	sudo add-apt-repository ppa:obsproject/obs-studio
	sudo apt update
	sudo apt install ffmpeg obs-studio
fi

# install postman
if ! command -v postman &>/dev/null; then
	echo -e "\n${GREEN}Installing Postman...${NC}"
	curl https://gist.githubusercontent.com/SanderTheDragon/1331397932abaa1d6fbbf63baed5f043/raw/postman-deb.sh | sh &&
		source ~/.bashrc
fi

# install vivaldi
if ! command -v vivaldi-stable &>/dev/null; then
	echo -e "\n${GREEN}Installing Vivaldi...${NC}"
	wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | gpg --dearmor | sudo dd of=/usr/share/keyrings/vivaldi-browser.gpg &&
		echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vivaldi-browser.gpg] https://repo.vivaldi.com/archive/deb/ stable main" | sudo tee /etc/apt/sources.list.d/vivaldi.list &&
		sudo apt update &&
		sudo apt install vivaldi-stable
fi

# install slack
if ! command -v slack &>/dev/null; then
	echo -e "\n${GREEN}Installing Slack...${NC}"
	version="$(curl --silent https://slack.com/downloads/linux --stderr - | grep -Po -m 1 "(?<=Version )[0-9.]*")" &&
		wget -q --show-progress "https://downloads.slack-edge.com/releases/linux/${version}/prod/x64/slack-desktop-${version}-amd64.deb" -O slack.deb &&
		sudo apt -qq install -y ./slack.deb &&
		rm ./slack.deb
fi

# install proton vpn cli
./scripts/install-proton-vpn.sh

echo
read -p "Do you want to install Turso CLI (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	curl -sSfL https://get.tur.so/install.sh | bash
fi

echo
read -p "Do you want to install FlyCTL CLI (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	curl -L https://fly.io/install.sh | sh
fi

## TODO Add JetBrains Toolbox installation
### TODO Install Android Studio
### TODO Install DataGrip
### TODO Install Gradle

# Setup Configs for theming and other stuff
scripts/setup-config.sh

# Setup Fonts
scripts/install-fonts.sh

# Install Completions
scripts/install-completions.sh

# Move assets i.e wallpapers, icons, etc
scripts/move-assets.sh

source ~/.bashrc
