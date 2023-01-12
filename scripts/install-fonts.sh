#!/usr/bin/env bash

# shellcheck source=latest-git-release.sh
source latest-git-release.sh

folder="$HOME/.local/share/fonts"

# Install iosevka fonts
# Term Slab for Terminal Use
# Slab for Normal Use
repo="be5invis/iosevka"
tag="$(latest_git_release $repo)"
version="${tag:1}"
url_prefix="https://github.com/$repo/releases/download"
name_prefix="super-ttc-sgr-iosevka"
if [ -n "$version" ]; then
  wget -q --show-progress "$url_prefix/$tag/$name_prefix-fixed-slab-$version.zip" -O slab.zip &&
    wget -q --show-progress "$url_prefix/$tag/$name_prefix-term-slab-$version.zip" -O term.zip &&
    unzip slab.zip -d "$folder" "*.ttc" &&
    unzip term.zip -d "$folder" "*.ttc" &&
    rm slab.zip term.zip
fi
