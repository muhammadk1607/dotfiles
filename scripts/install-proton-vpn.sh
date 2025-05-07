#!/usr/bin/env bash

GREEN='\e[32m'
NC='\e[0m'

if ! command -v protonvpn-cli &>/dev/null; then
  echo -e "\n${GREEN}Installing Proton VPN CLI...${NC}"
  wget -q --show-progress https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb -O proton_repo.deb &&
    sudo dpkg -i proton_repo.deb &&
    rm ./proton_repo.deb &&
    sudo apt update &&
    sudo apt install proton-vpn-gnome-desktop
fi
