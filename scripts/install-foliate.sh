#!/usr/bin/env bash

GREEN='\e[32m'
NC='\e[0m'

if ! command -v com.github.johnfactotum.Foliate &>/dev/null; then
  echo -e "\n${GREEN}Installing Foliate...${NC}"
  wget -q --show-progress https://github.com/johnfactotum/foliate/releases/download/3.0.1/foliate_3.0.1_all.deb -O foliate.deb &&
    sudo apt -qq install -y ./foliate.deb &&
    rm ./foliate.deb
fi
