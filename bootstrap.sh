#!/usr/bin/env bash

# bootstrap 中に必要な PATH を先に通す。
# bash で起動された bootstrap.sh は zsh のログイン設定を読まないため、
# ~/.local/bin と mise の shims を明示的に追加しないと、
# このスクリプト内でインストール直後の npx / claude / gh などが見つからず、
# `npx skills` `claude mcp` `npx playwright install` などが初回実行で空振りする。
# shims 配下のバイナリは後段の `mise install` 完了後に初めて利用可能になる。
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# install zsh
if [[ "$(uname)" == "Darwin" ]]; then
  # Mac: zsh is pre-installed, ensure brew is available
  if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
else
  # WSL/Linux
  if ! command -v zsh &>/dev/null; then
    sudo apt-get update -y && sudo apt-get install -y zsh
  fi
fi

# install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin

# symlink dotfiles to chezmoi default source dir
mkdir -p ~/.local/share
if [[ ! -e ~/.local/share/chezmoi ]]; then
  ln -s "$(cd "$(dirname "$0")" && pwd)" ~/.local/share/chezmoi
fi

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
if ! command -v mise &>/dev/null && [[ ! -x "$HOME/.local/bin/mise" ]]; then
  curl https://mise.run | sh
fi

# install tools via mise (node, go, etc.)
~/.local/bin/mise install

# install oh-my-zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# install packages via Brewfile (Mac only)
if [[ "$(uname)" == "Darwin" ]]; then
  brew bundle --file="$(cd "$(dirname "$0")" && pwd)/dot_config/homebrew/Brewfile"
else
  # install docker on Linux/WSL2
  if ! command -v docker &>/dev/null; then
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
  fi

  # install neovim on Linux
  if ! command -v nvim &>/dev/null; then
    ARCH=$(uname -m)
    curl -LO "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.tar.gz"
    tar -xzf "nvim-linux-${ARCH}.tar.gz" -C ~/.local/ --strip-components=1
    rm "nvim-linux-${ARCH}.tar.gz"
  fi

  # install apm (Agent Package Manager) on Linux
  # Mac は Brewfile (microsoft/apm/apm) で入れるためここではスキップ。
  # PATH 上の `apm` は Atom 製 package manager の可能性があるため、
  # ~/.local/bin/apm の有無だけで判定する。
  if [[ ! -x "$HOME/.local/bin/apm" ]]; then
    # apm のリリース命名に揃える（uname -m の aarch64 は apm では arm64）
    APM_ARCH=$(uname -m)
    [[ "$APM_ARCH" == "aarch64" ]] && APM_ARCH="arm64"
    mkdir -p ~/.local/share/apm ~/.local/bin
    curl -fsSL "https://github.com/microsoft/apm/releases/latest/download/apm-linux-${APM_ARCH}.tar.gz" \
      -o /tmp/apm.tar.gz \
      || { echo "apm download failed for arch=${APM_ARCH}" >&2; exit 1; }
    tar -xzf /tmp/apm.tar.gz -C ~/.local/share/apm/ --strip-components=1 \
      || { rm -f /tmp/apm.tar.gz; exit 1; }
    ln -snf ~/.local/share/apm/apm ~/.local/bin/apm
    rm -f /tmp/apm.tar.gz
    unset APM_ARCH
  fi
fi


# install powerlevel10k
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
fi

# install zsh-syntax-highlighting
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
fi

# install TPM (tmux plugin manager) and plugins
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ~/.tmux/plugins/tpm/bin/install_plugins
fi

# install JetBrainsMono Nerd Font
if [[ "$(uname)" == "Darwin" ]]; then
  font_dir="$HOME/Library/Fonts/JetBrainsMono"
  _font_check() { ls "$HOME/Library/Fonts/JetBrainsMono"/*.ttf &>/dev/null; }
else
  font_dir="$HOME/.local/share/fonts/JetBrainsMono"
  _font_check() { fc-list | grep -qi "JetBrainsMono"; }
fi
if ! _font_check; then
  mkdir -p "$font_dir"
  curl -Lo /tmp/JetBrainsMono.zip \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  if [[ "$(uname)" == "Darwin" ]]; then
    unzip -o /tmp/JetBrainsMono.zip \
      "JetBrainsMonoNerdFontMono-Regular.ttf" \
      "JetBrainsMonoNerdFontMono-Bold.ttf" \
      -d "$font_dir"
  else
    unzip -o /tmp/JetBrainsMono.zip -d "$font_dir"
    fc-cache -fv
  fi
  rm /tmp/JetBrainsMono.zip
fi

# install claude skills（~/.agents/.skill-lock.json を読んで一括復元）
# cd しないと npx skills が CWD/.agents 配下にインストールしてしまう
if command -v npx &>/dev/null && [[ -f "$HOME/.agents/.skill-lock.json" ]]; then
  (cd "$HOME" && npx -y skills experimental_install)
fi

# install claude skills via apm（~/.apm/apm.yml と apm.lock.yaml を読んで一括復元）
# cd ~ しないと apm がカレントを project root として扱う
# ~/.local/bin/apm を優先（PATH の `apm` は Atom 製 package manager の可能性があるため）
_APM_BIN=""
if [[ -x "$HOME/.local/bin/apm" ]]; then
  _APM_BIN="$HOME/.local/bin/apm"
elif command -v apm &>/dev/null; then
  _APM_BIN=$(command -v apm)
fi
if [[ -f "$HOME/.apm/apm.yml" ]] && [[ -n "$_APM_BIN" ]]; then
  (cd "$HOME" && "$_APM_BIN" install -g)
fi
unset _APM_BIN

# register MCP servers for claude code
if command -v claude &>/dev/null; then
  claude mcp get chrome-devtools --scope user &>/dev/null || \
    claude mcp add --scope user chrome-devtools -- npx -y chrome-devtools-mcp@latest --slim --headless
  claude mcp get playwright --scope user &>/dev/null || \
    claude mcp add --scope user playwright -- npx @playwright/mcp@latest --browser chromium
fi

# install playwright chromium browser
if command -v npx &>/dev/null; then
  npx playwright install chromium || true
fi
