#!/usr/bin/env bash

# install orchis theme
git clone https://github.com/vinceliuice/Orchis-theme orchis &&
  cd orchis &&
  ./install.sh -t purple -c dark -s compact -l --round 5px --tweaks compact primary dracula &&
  cd .. &&
  sudo rm -rf orchis

# install tela icon theme
git clone https://github.com/vinceliuice/Tela-icon-theme tela &&
  cd tela &&
  ./install.sh purple &&
  cd .. &&
  rm -rf tela

#################
# Dracula theme #
#################

# For Gedit
wget https://raw.githubusercontent.com/dracula/gedit/master/dracula.xml
mkdir -p "$HOME"/.local/share/gedit/styles/ && mv dracula.xml "$HOME"/.local/share/gedit/styles/

# For Tilix
git clone https://github.com/dracula/tilix
mkdir -p ~/.config/tilix/schemes && mv tilix/Dracula.json ~/.config/tilix/schemes
rm -rf tilix
