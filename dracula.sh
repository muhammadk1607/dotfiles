#!/usr/bin/env bash
############################
# This script downloads dracula theme for various applications
############################

wget https://raw.githubusercontent.com/dracula/gedit/master/dracula.xml
mkdir -p $HOME/.local/share/gedit/styles/ && mv dracula.xml $HOME/.local/share/gedit/styles/


git clone https://github.com/dracula/tilix
mkdir -p ~/.config/tilix/schemes && mv tilix/Dracula.json ~/.config/tilix/schemes
rm -rf tilix
