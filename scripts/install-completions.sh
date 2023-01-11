#!/usr/bin/env bash

################
# Completeions #
################

# git completion
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash

# pnpm completion
pnpm install-completion bash &&
  mv .bashrc .bashrc-old && head -n -4 .bashrc-old > .bashrc &&
  if grep -q '[ -f ~/.config/tabtab/bash/__tabtab.bash ] && . ~/.config/tabtab/bash/__tabtab.bash || true' .bash.profile; then
    echo 'Added pnpm completion to .bash.profile'
    tail -n -4 .bashrc-old >> .bash.profile
  else
    echo 'pnpm completion is already added'
  fi &&
  rm .bashrc-old
