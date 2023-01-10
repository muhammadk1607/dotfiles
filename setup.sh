#!/usr/bin/env bash
# shellcheck source=/dev/null
############################
# This scripts installs applications and sets up development environment
############################

# Usage `get-latest-release ":user/:repo"`
get-latest-release() {
	curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
		grep '"tag_name":' |                                             # Get tag line
		sed -E 's/.*"([^"]+)".*/\1/'                                     # Pluck JSON value
}

# Usage `list_from_file "path/to/file.txt"`
list_from_file() {
	local packages=''
	while IFS= read -r line; do
		packages+=" $line"
	done <"$1"
	echo "$packages"
}

# Check if curl is installed, if not install it
type -p curl >/dev/null || sudo apt install curl -y

# Install apt packages
PACKAGES="$(list_from_file ./apt-packages.txt)"
sudo apt install "$PACKAGES"

# Install nvm
if ! command -v nvm &>/dev/null; then
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
fi

# Install git completion script
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash

# get npm packages to install
NPM_PACKAGES="$(list_from_file ./npm-packages.txt)"

# Install node lts
nvm install lts/* &&
	npm i -g "$NPM_PACKAGES" &&
	corepack enable &&
	corepack prepare yarn@latest --activate &&
	corepack prepare pnpm@latest --activate

# Install node latest
nvm install node &&
	npm i -g "$NPM_PACKAGES" &&
	corepack enable &&
	corepack prepare yarn@latest --activate &&
	corepack prepare pnpm@latest --activate

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
	curl -fsSL https://deno.land/install.sh | sh
fi

deno completions bash >/usr/local/etc/bash_completion.d/deno.bash &&
	source /usr/local/etc/bash_completion.d/deno.bash

# install gh cli
if ! command -v gh &>/dev/null; then
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg &&
		sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg &&
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null &&
		sudo apt update &&
		sudo apt install gh -y &&
		gh extension install mislav/gh-license
fi

# install vs code
if ! command -v code &>/dev/null; then
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
	curl https://gist.githubusercontent.com/SanderTheDragon/1331397932abaa1d6fbbf63baed5f043/raw/postman-deb.sh | sh &&
		source ~/.bashrc
fi

# install anydesk
read -p "Do you want to install AnyDesk (y/n)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | apt-key add - &&
		echo "deb http://deb.anydesk.com/ all main" >/etc/apt/sources.list.d/anydesk-stable.list &&
		sudo apt update &&
		sudo apt install anydesk

fi

# install mongodb compass
if ! command -v mongodb-compass &>/dev/null; then
	wgeet https://downloads.mongodb.com/compass/mongodb-compass_1.34.2_amd64.deb -O compass.deb &&
		sudo apt install ./compass.deb &&
		rm ./compass.deb
fi

# install orchis theme
git clone https://github.com/vinceliuice/Orchis-theme orchis &&
	cd orchis &&
	source ./install.sh -t purple -c dark -s compact -l --round 0px --tweaks compact primary &&
	cd .. &&
	sudo rm -rf orchis

# install tela icon theme
git clone https://github.com/vinceliuice/Tela-icon-theme tela &&
	source ./install.sh &&
	cd .. &&
	rm -rf tela purple

# Install iosevka fonts
# Term Slab for Terminal Use
# Slab for Normal Use
iosveka_repo="be5invis/Iosevka"
iosevka_version=get-latest-release $iosveka_repo &&
	wget "https://github.com/$iosveka_repo/releases/download/v$iosevka_version/super-ttc-iosevka-fixed-slab-$iosevka_version.zip" -O slab.zip &&
	wget "https://github.com/$iosveka_repo/releases/download/v$iosevka_version/super-ttc-iosevka-term-slab-$iosevka_version.zip" -O slab.zip


#################
# Dracula theme #
#################

# For Gedit
wget https://raw.githubusercontent.com/dracula/gedit/master/dracula.xml
mkdir -p $HOME/.local/share/gedit/styles/ && mv dracula.xml $HOME/.local/share/gedit/styles/

# For Tilix
git clone https://github.com/dracula/tilix
mkdir -p ~/.config/tilix/schemes && mv tilix/Dracula.json ~/.config/tilix/schemes
rm -rf tilix

# setup dotfiles
source ./install.sh
