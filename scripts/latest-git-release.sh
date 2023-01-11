#!/usr/bin/env bash

# Usage `latest_git_release ":user/:repo"`
latest_git_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                             # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                     # Pluck JSON value
}
