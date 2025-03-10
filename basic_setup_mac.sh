#!/bin/bash

# Prompt for sudo password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished
while true; do sudo -n true; sleep 60; kill -0 "$PPID" || exit; done 2>/dev/null &

echo "Atualizando o macOS e instalando as ferramentas básicas..."
# Atualiza o macOS
softwareupdate -i -a

# Instala Xcode Command Line Tools
xcode-select --install

echo "Instalando o Homebrew..."
# Baixa e instala o Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$($(brew --prefix)/bin/brew shellenv)"' >> ~/.zprofile
eval "$($(brew --prefix)/bin/brew shellenv)"

# Atualiza e verifica o Homebrew
brew update
brew upgrade

echo "Instalando pacotes via Homebrew..."
# Instala pacotes essenciais
brew install git
brew install node
brew install php
brew install wget

echo "Instalando aplicativos via Homebrew Cask..."
# Instala aplicativos via Cask
brew install --cask visual-studio-code
brew install --cask sublime-text
brew install --cask google-chrome
brew install --cask arc
brew install --cask filezilla
brew install --cask insomnia
brew install --cask beekeeper-studio

# Limpeza após a instalação
brew cleanup

echo "Configuração concluída!"
