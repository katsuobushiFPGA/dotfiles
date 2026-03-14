#!/usr/bin/env bash

# install zsh
if [[ "$(uname)" == "Darwin" ]]; then
  # Mac: zsh is pre-installed, ensure brew is available
  if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
else
  # WSL/Linux
  sudo apt-get update -y && sudo apt-get install -y zsh
fi

# install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# install mise
curl https://mise.run | sh

# install tools via mise (node, go, etc.)
~/.local/bin/mise install

# install oh-my-zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# install neovim
if ! command -v nvim &>/dev/null; then
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install neovim
  else
    ARCH=$(uname -m)
    curl -LO "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.tar.gz"
    tar -xzf "nvim-linux-${ARCH}.tar.gz" -C ~/.local/ --strip-components=1
    rm "nvim-linux-${ARCH}.tar.gz"
  fi
fi

# install cmux (Mac only)
if [[ "$(uname)" == "Darwin" ]] && ! command -v cmux &>/dev/null; then
  brew install cmux
fi

# install difit
if ! ~/.local/bin/mise exec -- command -v difit &>/dev/null; then
  ~/.local/bin/mise exec -- npm install -g difit
fi

# install powerlevel10k
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
fi
