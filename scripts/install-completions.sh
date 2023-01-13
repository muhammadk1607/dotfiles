#!/usr/bin/env bash

################
# Completeions #
################

## TODO - Move completions to predefined bash-completion user directory and source them all

# Create bash-completion user directory
mkdir -p ~/.config/bash-completion/completions

# Add docker completions to bash-completion user directory
curl https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker -o ~/.config/bash-completion/completions/docker

# Add docker-compose completions to bash-completion user directory
curl https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose -o ~/.config/bash-completion/completions/docker-compose


# Add git completions to bash-completion user directory
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.config/bash-completion/completions/git

# Add yarn completions to bash-completion user directory
curl https://raw.githubusercontent.com/dsifford/yarn-completion/master/yarn-completion.bash -o ~/.config/bash-completion/completions/yarn

# Add npm completion to bash-completion user directory
npm completion > ~/.config/bash-completion/completions/npm

# Add pnpm completion
pnpm install-completion bash &&
  mv .bashrc .bashrc-old && head -n -4 .bashrc-old > .bashrc &&
  if grep -q '[ -f  ] && . ~/.config/tabtab/bash/__tabtab.bash || true' .bash.profile; then
    echo 'pnpm completion is already added'
  else
    echo 'Added pnpm completion to .bash.profile'
    tail -n -4 .bashrc-old >> .bash.profile
  fi &&
  rm .bashrc-old

# Add nvm completion to bash-completion user directory
curl https://raw.githubusercontent.com/nvm-sh/nvm/master/bash_completion -o ~/.config/bash-completion/completions/nvm
