#!/usr/bin/env bash
############################
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
# It also installs the system programming essentials for myself
# It installs all the packages I need for my development environment
############################

# shellcheck source=/dev/null

GREEN='\e[32m'
NC='\e[0m'

# Check if curl is installed, if not install it
type -p curl >/dev/null || sudo apt install curl -y

# Check if xargs is installed, if not install it
type -p xargs >/dev/null || sudo apt install xargs -y

# Install apt packages
echo -e "\n${GREEN}Setting Up APT Packages...${NC}"
xargs sudo apt install -y < lists/apt-packages.txt

# Install or update nvm
./scripts/install-nvm.sh
source ~/.bashrc

# Install nvm node versions
for version in lts/* node; do
	echo -e "\n${GREEN}Setting Up Node Version: $version...${NC}"
	nvm install "$version" &&
		xargs npm install -g <lists/npm-packages.txt &&
		corepack enable &&
		corepack prepare yarn@stable --activate &&
		corepack prepare pnpm@latest --activate
done
nvm alias lts/* default
nvm use default
source ~/.bashrc

# Install rbenv and latest ruby
if ! command -v rbenv &> /dev/null
then
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  source ~/.bashrc
  mkdir -p "$(rbenv root)"/plugins
  git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
  source ~/.bashrc
  rbenv install 3.1.3 --verbose
  rbenv global 3.1.3
  gem install rails bundler
fi

# Install Deno
if ! command -v deno &>/dev/null; then
	echo -e "\n${GREEN}Installing Deno...${NC}"
	curl -fsSL https://deno.land/install.sh | sh &&
		export DENO_INSTALL="$HOME/.deno" &&
		export PATH="$DENO_INSTALL/bin:$PATH"
fi

# install gh cli
if ! command -v gh &>/dev/null; then
	echo -e "\n${GREEN}Installing GitHub CLI...${NC}"
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg &&
		sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg &&
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null &&
		sudo apt update &&
		sudo apt install gh -y &&
		gh extension install mislav/gh-license
fi

# install vs code
if ! command -v code &>/dev/null; then
	echo -e "\n${GREEN}Installing VS Code...${NC}"
	sudo apt-get install wget gpg &&
		wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >packages.microsoft.gpg &&
		sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg &&
		sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' &&
		rm -f packages.microsoft.gpg &&
		sudo apt install apt-transport-https &&
		sudo apt update &&
		sudo apt install code
fi

#install postman
if ! command -v postman &>/dev/null; then
	echo -e "\n${GREEN}Installing Postman...${NC}"
	curl https://gist.githubusercontent.com/SanderTheDragon/1331397932abaa1d6fbbf63baed5f043/raw/postman-deb.sh | sh &&
		source ~/.bashrc
fi

# install anydesk
if ! command -v anydesk &>/dev/null; then
	echo
	read -p "Do you want to install AnyDesk (y/n)? " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo -e "\n${GREEN}Installing AnyDesk...${NC}"
		wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | apt-key add - &&
			echo "deb http://deb.anydesk.com/ all main" >/etc/apt/sources.list.d/anydesk-stable.list &&
			sudo apt update &&
			sudo apt install anydesk

	fi
fi

# install mongodb compass
if ! command -v mongodb-compass &>/dev/null; then
	echo -e "\n${GREEN}Installing MongoDB Compass...${NC}"
	wget https://downloads.mongodb.com/compass/mongodb-compass_1.34.2_amd64.deb -O compass.deb &&
		sudo apt install ./compass.deb &&
		rm ./compass.deb
fi

# Setup Themes
scripts/install-themes.sh

# Setup Fonts
scripts/install-fonts.sh

# Setup Dotfiles
echo -e "\n${GREEN}Creating symlinks for dotfiles...${NC}"
cp -rsTvf ~/dotfiles/config ~/

# Install Completions
scripts/install-completions.sh

source ~/.bashrc
