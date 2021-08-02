sudo apt install -y gcc make libssl-dev libreadline-dev zlib1g-dev libsqlite3-dev tilix gnome-tweak-tool mysql-server mysql-client libmagickwand-dev

# Download Iosevka slab and term slab and set them up in fonts
wget https://github.com/be5invis/Iosevka/releases/download/v9.0.1/ttf-iosevka-slab-9.0.1.zip
wget https://github.com/be5invis/Iosevka/releases/download/v9.0.1/ttf-iosevka-term-slab-9.0.1.zip

# Ruby setup
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
PATH="$HOME/.rbenv/bin:$PATH"
rbenv init
mkdir -p "$(rbenv root)"/plugins
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
rbenv install 2.7.3
rbenv global 2.7.3

# Download and setup dracula theme for gedit
wget https://raw.githubusercontent.com/dracula/gedit/master/dracula.xml
mkdir -p $HOME/.local/share/gedit/styles/
mv dracula.xml $HOME/.local/share/gedit/styles/

# Download gtk theme Dracula
git clone https://github.com/dracula/gtk $HOME/.themes/Dracula

# Paer Icon Theme
sudo add-apt-repository -u ppa:snwh/ppa
sudo apt install -y paper-icon-theme

# Setup themes
gsettings set org.gnome.desktop.interface icon-theme "Paper"
gsettings set org.gnome.desktop.interface cursor-theme "Paper"
gsettings set org.gnome.desktop.interface gtk-theme "Dracula"
gsettings set org.gnome.desktop.wm.preferences theme "Dracula"

