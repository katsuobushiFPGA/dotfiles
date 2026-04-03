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
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin

# apply dotfiles via chezmoi
_CHEZMOI_CONFIG="$HOME/.config/chezmoi/chezmoi.toml"
if [[ ! -f "$_CHEZMOI_CONFIG" ]]; then
  mkdir -p "$(dirname "$_CHEZMOI_CONFIG")"
  read -r -p "Enter your email for git config: " _GIT_EMAIL
  cat > "$_CHEZMOI_CONFIG" <<EOF
[data]
  email = "$_GIT_EMAIL"
EOF
fi
~/.local/bin/chezmoi apply --source "$(cd "$(dirname "$0")" && pwd)"

# install mise
curl https://mise.run | sh

# install tools via mise (node, go, etc.)
~/.local/bin/mise install

# install oh-my-zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# install packages via Brewfile (Mac only)
if [[ "$(uname)" == "Darwin" ]]; then
  brew bundle --file="$(cd "$(dirname "$0")" && pwd)/Brewfile"
else
  # install neovim on Linux
  if ! command -v nvim &>/dev/null; then
    ARCH=$(uname -m)
    curl -LO "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.tar.gz"
    tar -xzf "nvim-linux-${ARCH}.tar.gz" -C ~/.local/ --strip-components=1
    rm "nvim-linux-${ARCH}.tar.gz"
  fi
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

# install TPM (tmux plugin manager) and plugins
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ~/.tmux/plugins/tpm/bin/install_plugins
fi

# install JetBrainsMono Nerd Font
if ! fc-list | grep -qi "JetBrainsMono"; then
  font_dir="$HOME/.local/share/fonts"
  mkdir -p "$font_dir"
  curl -Lo /tmp/JetBrainsMono.zip \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  unzip -o /tmp/JetBrainsMono.zip -d "$font_dir/JetBrainsMono"
  rm /tmp/JetBrainsMono.zip
  fc-cache -fv
fi

# install claude skills
if command -v jq &>/dev/null; then
  "$HOME/dotfiles/bin/install-claude-skills"
fi

# register MCP servers for claude code
if command -v claude &>/dev/null; then
  claude mcp get chrome-devtools --scope user &>/dev/null || \
    claude mcp add --scope user chrome-devtools -- npx -y chrome-devtools-mcp@latest --slim --headless
  claude mcp get playwright --scope user &>/dev/null || \
    claude mcp add --scope user playwright -- npx @playwright/mcp@latest --browser chromium
fi

# install playwright chromium browser
npx playwright install chromium 2>/dev/null || true
