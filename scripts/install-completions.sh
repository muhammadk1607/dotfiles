#!/usr/bin/env bash

################
# Completeions #
################

## TODO - Move completions to predefined bash-completion user directory and source them all

# git completion
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash

# yarn completion
curl https://raw.githubusercontent.com/dsifford/yarn-completion/master/yarn-completion.bash -o ~/.yarn-completion.bash

# npm completion
npm completion > ~/.npm-completion.bash

# pnpm completion
pnpm install-completion bash &&
  mv .bashrc .bashrc-old && head -n -4 .bashrc-old > .bashrc &&
  if grep -q '[ -f  ] && . ~/.config/tabtab/bash/__tabtab.bash || true' .bash.profile; then
    echo 'pnpm completion is already added'
  else
    echo 'Added pnpm completion to .bash.profile'
    tail -n -4 .bashrc-old >> .bash.profile
  fi &&
  rm .bashrc-old
