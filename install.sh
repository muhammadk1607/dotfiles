#!/usr/bin/env bash
############################
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
# It also installs the system programming essentials for myself
############################

########## Variables

# dotfiles directory
dir=~/dotfiles

# old dotfiles backup directory
olddir=~/dotfiles_old

# list of files/folders to symlink in homedir
files=".bashrc .gitconfig .gitmessage .gitignore .bash.profile .ssh-completion.bash"


# create dotfiles_old in homedir
echo "Creating $olddir for backup of any existing dotfiles in ~"
mkdir -p $olddir
echo "...done"

# change to the dotfiles directory
echo "Changing to the $dir directory"
cd $dir
echo "...done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks
for file in $files; do
	echo "Moving any existing dotfiles from ~ to $olddir"
	mv ~/$file ~/dotfiles_old/
	echo "Creating symlink to $file in home directory."
	ln -s $dir/$file ~/$file
done

# Install git completion script
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash

# Install apt packages
sudo apt install direnv httpie bat python-is-python3 tilix gcc make libssl-dev libreadline-dev zlib1g-dev libsqlite3-dev gnome-tweaks ffmpeg libmagickwand-dev

# Install nvm and latest node
if ! command -v nvm &> /dev/null
then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
  source ~/.bashrc
  nvm install node
  source ~/.bashrc
  corepack enable yarn
  corepack enable pnpm
  corepack prepare pnpm@latest --activate
fi

# Install rbenv and latest ruby
if ! command -v rbenv &> /dev/null
then
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  source ~/.bashrc
  mkdir -p "$(rbenv root)"/plugins
  git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
  source ~/.bashrc
  rbenv install 3.1.2 --verbose
  rbenv global 3.1.2
  gem install rails bundler
fi

# Install Deno
if ! command -v deno &> /dev/null
then
	curl -fsSL https://deno.land/install.sh | sh
fi

# Install global packages
npm install -g nodemon npm-check electron eslint tldr jsdoc ngrok eslint-plugin-jsdoc vsce typescript @svgr/cli expo-cli ts-node dotenv-vault npkill stylelint stylelint-config-standard stylelint-config-standard-scss

# Install postman
curl https://gist.githubusercontent.com/SanderTheDragon/1331397932abaa1d6fbbf63baed5f043/raw/postman-deb.sh | sh

# Install gh cli through .deb
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg &&
	sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg &&
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null &&
	sudo apt update &&
	sudo apt install gh -y
gh extension install mislav/gh-license
