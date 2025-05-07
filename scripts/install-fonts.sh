#!/usr/bin/env bash

# shellcheck source=latest-git-release.sh
source ~/dotfiles/scripts/latest-git-release.sh

folder="$HOME/.local/share/fonts"

# Install iosevka fonts
# Term Slab for Terminal Use
# Slab for Normal Use
repo="be5invis/Iosevka"
tag="$(latest_git_release $repo)"
version="${tag:1}"
url_prefix="https://github.com/$repo/releases/download"
name_prefix="SuperTTC-SGr-Iosevka"
if [ -n "$version" ]; then
  wget -q --show-progress "$url_prefix/$tag/${name_prefix}FixedSlab-$version.zip" -O slab.zip &&
    wget -q --show-progress "$url_prefix/$tag/${name_prefix}TermSlab-$version.zip" -O term.zip &&
    unzip slab.zip -d "$folder" "*.ttc" &&
    unzip term.zip -d "$folder" "*.ttc" &&
    rm slab.zip term.zip
fi
