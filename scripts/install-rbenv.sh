#!/usr/bin/env bash

GREEN='\e[32m'
NC='\e[0m'

# Install rbenv and latest ruby
if ! command -v rbenv &> /dev/null
then
  echo -e "\n${GREEN}Setting Up rbenv...${NC}"
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
  mkdir -p "$(rbenv root)"/plugins
  git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
  git clone https://github.com/rbenv/rbenv-vars.git "$(rbenv root)"/plugins/rbenv-vars
  rbenv install 3.3.3 --verbose
  rbenv global 3.3.3
  gem install rails bundler prettier_print syntax_tree syntax_tree-haml syntax_tree-rbs rainbow
fi
