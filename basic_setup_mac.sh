#!/usr/bin/env bash
#
# Configura um macOS recem-formatado para desenvolvimento, usando o Homebrew.
# Apps ja instalados sao pulados, entao o script pode ser executado mais de uma vez.
#
# Uso:
#   ./basic_setup_mac.sh            # instalacao padrao
#   ./basic_setup_mac.sh --extras   # inclui os opcionais
#   ./basic_setup_mac.sh --skip-ai  # pula as ferramentas de IA

EXTRAS=0
SKIP_AI=0
for arg in "$@"; do
  case "$arg" in
    --extras)  EXTRAS=1 ;;
    --skip-ai) SKIP_AI=1 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "Opcao desconhecida: $arg"; exit 1 ;;
  esac
done

FALHAS=()
NVM_VERSION="v0.40.8"

step() { printf '\n\033[36m==> %s\033[0m\n' "$1"; }

brew_formula() {
  if brew list --formula "$1" &>/dev/null; then
    echo "   [ok] $1 ja instalado"
  else
    echo "   Instalando $1..."
    brew install "$1" || FALHAS+=("$1")
  fi
}

brew_cask() {
  if brew list --cask "$1" &>/dev/null; then
    echo "   [ok] $1 ja instalado"
  else
    echo "   Instalando $1..."
    brew install --cask "$1" || FALHAS+=("$1")
  fi
}

# --- Verificacoes iniciais ------------------------------------------------------

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Este script e para macOS. No Linux, use basic_setup_linux.sh."
  exit 1
fi

# Pede a senha de administrador uma vez e a mantem valida ate o fim
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- 1. Sistema -------------------------------------------------------------------

step "Atualizacoes do macOS"
softwareupdate -i -a || echo "   Nao foi possivel atualizar agora; continue e atualize depois."

step "Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
  echo "   [ok] ja instalado"
else
  xcode-select --install
  echo "   Conclua a instalacao na janela que abriu. Aguardando..."
  until xcode-select -p &>/dev/null; do sleep 10; done
fi

step "Homebrew"
if ! command -v brew &>/dev/null; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [[ -x /opt/homebrew/bin/brew ]]; then
  BREW_BIN=/opt/homebrew/bin/brew      # Apple Silicon
else
  BREW_BIN=/usr/local/bin/brew         # Intel
fi
eval "$("$BREW_BIN" shellenv)"
grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null || \
  echo "eval \"\$($BREW_BIN shellenv)\"" >> "$HOME/.zprofile"
brew update

step "Oh My Zsh"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  echo "   [ok] ja instalado"
else
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# --- 2. Apps essenciais --------------------------------------------------------------

step "Apps essenciais"
for app in bitwarden google-chrome visual-studio-code claude obsidian warp; do
  brew_cask "$app"
done

# --- 3. Ferramentas de desenvolvimento ----------------------------------------------

step "Ferramentas de desenvolvimento"
for f in git gh wget jq python@3.13 bun; do
  brew_formula "$f"
done

step "Node.js LTS (via nvm) e pnpm"
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  PROFILE="$HOME/.zshrc" bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh)"
fi
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
if nvm install --lts && nvm alias default 'lts/*'; then
  npm install -g pnpm || FALHAS+=("pnpm")
else
  FALHAS+=("Node.js LTS")
fi

# --- 4. Configuracao do Git e SSH ------------------------------------------------------

step "Configuracao do Git"
if [[ -z "$(git config --global user.name)" ]]; then
  read -r -p "   Seu nome para os commits (Enter para pular): " GIT_NAME
  [[ -n "$GIT_NAME" ]] && git config --global user.name "$GIT_NAME"
fi
if [[ -z "$(git config --global user.email)" ]]; then
  read -r -p "   Seu e-mail para os commits (Enter para pular): " GIT_EMAIL
  [[ -n "$GIT_EMAIL" ]] && git config --global user.email "$GIT_EMAIL"
fi
git config --global init.defaultBranch main

step "Chave SSH"
if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  echo "   [ok] Chave SSH ja existe"
else
  echo "   Se voce tem um backup da pasta .ssh, responda N e restaure-a depois."
  read -r -p "   Gerar uma nova chave SSH agora? (s/N): " RESP
  if [[ "$RESP" =~ ^[sSyY] ]]; then
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$(git config --global user.email || whoami)" -f "$HOME/.ssh/id_ed25519"
    echo "   Chave publica criada em ~/.ssh/id_ed25519.pub. Adicione-a no GitHub (gh ssh-key add)."
  fi
fi

# --- 5. Ferramentas de IA --------------------------------------------------------------

if [[ $SKIP_AI -eq 0 ]]; then
  step "Ferramentas de IA"
  if command -v claude &>/dev/null; then
    echo "   [ok] Claude Code ja instalado"
  else
    echo "   Instalando Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash || FALHAS+=("Claude Code")
  fi
  brew_formula opencode
  brew_formula gemini-cli
  brew_cask codex
  brew_cask ollama-app
  brew_cask kiro
  brew_cask antigravity
fi

# --- 6. Opcionais (--extras) -------------------------------------------------------------

if [[ $EXTRAS -eq 1 ]]; then
  step "Opcionais"
  brew_formula php
  for app in sublime-text insomnia beekeeper-studio docker-desktop arc hyper; do
    brew_cask "$app"
  done
  echo "   FileZilla nao esta mais no Homebrew: baixe em https://filezilla-project.org"
  echo "   Azure CLI: veja https://learn.microsoft.com/cli/azure/install-azure-cli-macos"
fi

brew cleanup

# --- Resumo -------------------------------------------------------------------------------

step "Resumo"
if [[ ${#FALHAS[@]} -gt 0 ]]; then
  echo "   Nao foi possivel instalar:"
  printf '   - %s\n' "${FALHAS[@]}"
else
  echo "   Tudo instalado sem erros."
fi

cat <<'EOF'

Proximos passos:
  1. Feche e reabra o terminal para carregar Homebrew, nvm e Oh My Zsh.
  2. Faca login no Bitwarden, Chrome, VS Code (Settings Sync) e no app do Claude.
  3. Rode "gh auth login" e teste o SSH com "ssh -T git@github.com".
  4. Rode "claude" uma vez para fazer login no Claude Code.
EOF
