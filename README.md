# .dotfiles

Dotfiles repository for my personal setup.

## Prerequisites

Dotfiles include a script to install all the required packages for the dotfiles to work properly.
The script is based on apt-get so it will only work on Debian based distributions.

## Installation

All you need to do is clone the repository in your home ~ directory inside the dotfiles folder.

```bash
cd ~
git clone https://github.com/MBM1607/dotfiles
cd dotfiles
```

Then run the install script.

```bash
./install.sh
```

It performs the following actions:

- Installs all apt packages required for the dotfiles to work properly.
- Installs and sets up my dev environment.
  - VSCode
  - Postman
  - Anydesk
  - MongoDB Compass
  - Vivaldi
  - Slack
  - ProtonVPN
  - Foliate
  - Remmina
  - OBS Studio
  - Deno
  - GH CLI
  - nvm
  - node
  - rbenv
  - ruby
- Install and configures the gnome shell extensions.
- Sets up the gnome shell theme, default terminal, fonts and bash completions.
- Moves all wallpapers to ~/Pictures/Wallpapers and sets up the gnome shell wallpaper.
- Moves all the dotfiles to ~ and creates symlinks to the dotfiles folder.
