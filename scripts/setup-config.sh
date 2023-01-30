#!/usr/bin/env bash

##################
#  Config Setup  #
##################

GREEN='\e[32m'
NC='\e[0m'

config_folder=~/dotfiles/config

echo -e "\n${GREEN}Installing Gnome Shell Extensions...${NC}"
rm -f ./install-gnome-extensions.sh &&
	wget -N -q "https://raw.githubusercontent.com/cyfrost/install-gnome-extensions/master/install-gnome-extensions.sh" -O ./install-gnome-extensions.sh &&
	chmod +x install-gnome-extensions.sh &&
	./install-gnome-extensions.sh --enable --file ~/dotfiles/lists/shell-extensions.txt &&
	rm ./install-gnome-extensions.sh &&
	killall -3 gnome-shell

echo -e "\n${GREEN}Setting Up Orchis Theme...${NC}"
git clone https://github.com/vinceliuice/Orchis-theme orchis &&
	cd orchis &&
	./install.sh -t purple -c dark -s compact -l --round 5px --tweaks compact primary dracula &&
	cp -rvf ./src/firefox/chrome ~/.mozilla/firefox/*.default/ &&
	cp -vf ./src/firefox/configuration/user.js ~/.mozilla/firefox/*.default/ &&
	cd .. &&
	rm -rf orchis

echo -e "\n${GREEN}Setting Up Tela Icon Theme...${NC}"
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

echo -e "\n${GREEN}Setting Up Gtk Terminal Styles...${NC}"
rm -f "$HOME/.config/gtk-3.0/gtk.css" &&
	ln -s "$HOME/dotfiles/config/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"

echo -e "\n${GREEN}Setting Up Config With Dconf...${NC}"
# Update settings with:
# dconf dump {{name}} >$config_folder/{{file}}.dconf

dconf load /org/gnome/desktop/ <"$config_folder"/desktop.dconf
dconf load /org/gnome/eog/ <"$config_folder"/eog.dconf
dconf load /org/gnome/shell/extensions/ <"$config_folder"/extensions.dconf
dconf load /org/gnome/gedit/ <"$config_folder"/gedit.dconf
sudo dconf load /org/gnome/gedit/ <"$config_folder"/gedit.sudo.dconf
dconf load /org/gnome/nautilus/ <"$config_folder"/nautilus.dconf
dconf load /org/gnome/system/ <"$config_folder"/system.dconf
dconf load /com/gexperts/Tilix/ <"$config_folder"/tilix.dconf
dconf load /org/gnome/weather/ <"$config_folder"/weather.dconf

# TODO setup gnome shell extensions status bar placement

echo -e "\n${GREEN}Setting Up UFW firewall...${NC}"
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 3000:3050/tcp
sudo ufw allow 3000:3050/udp
sudo ufw allow 5000:5050/tcp
sudo ufw allow 5000:5050/udp
sudo ufw allow 8000:8999/tcp
sudo ufw allow 8000:8999/udp

echo -e "\n${GREEN}Setting Tilix as the default...${NC}"
sudo update-alternatives --set x-terminal-emulator /usr/bin/tilix.wrapper &&
	sudo apt install python3-pip python3-nautilus &&
	pip install --user nautilus-open-any-terminal &&
	nautilus -q &&
	glib-compile-schemas ~/.local/share/glib-2.0/schemas/ &&
	gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal tilix

[ ! -f "$HOME/.ssh/config" ] &&
	echo -e "\n${GREEN}Setting Up SSH config...${NC}" &&
	ssh-keygen -t ed25519 -C "muhammadkhan1607@gmail.com" -f ~/.ssh/id_ed25519 -N "" &&
	eval "$(ssh-agent -s)" &&
	ssh-add ~/.ssh/id_ed25519 &&
	cp ~/dotfiles/config/.ssh/* ~/.ssh/ &&
	echo -e -n "${GREY}Enter a title for your new github ssh key:${NC} " &&
	read -r ssh_key_title &&
	gh ssh-key add ~/.ssh/id_ed25519.pub -t "${ssh_key_title}"

killall -3 gnome-shell
