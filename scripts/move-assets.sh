#!/usr/bin/env bash

#####################
#  Wallpaper Setup  #
#####################

GREEN='\e[32m'
NC='\e[0m'

echo -e "\n${GREEN}Setting Up Wallpaper...${NC}"
cp -rTvf ~/dotfiles/wallpapers ~/Pictures/Wallpapers
gsettings set org.gnome.desktop.background picture-uri file:///home/"$(whoami)"/Pictures/Wallpapers/purple-firewatch.jpg
