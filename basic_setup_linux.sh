#!/usr/bin/env bash
#
# Configura um Ubuntu/Debian (ou derivados, como Linux Mint e Pop!_OS) recem-instalado
# para desenvolvimento. Apps ja instalados sao pulados, entao o script pode ser
# executado mais de uma vez.
#
# Uso:
#   ./basic_setup_linux.sh            # instalacao padrao
#   ./basic_setup_linux.sh --extras   # inclui os opcionais
#   ./basic_setup_linux.sh --skip-ai  # pula as ferramentas de IA

EXTRAS=0
SKIP_AI=0
for arg in "$@"; do
  case "$arg" in
    --extras)  EXTRAS=1 ;;
    --skip-ai) SKIP_AI=1 ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) echo "Opcao desconhecida: $arg"; exit 1 ;;
  esac
done

FALHAS=()
AVISOS=()
NVM_VERSION="v0.40.8"
ARCH="$(dpkg --print-architecture 2>/dev/null)"

step() { printf '\n\033[36m==> %s\033[0m\n' "$1"; }
has()  { command -v "$1" &>/dev/null; }

apt_install() {
  echo "   Instalando: $*"
  sudo apt-get install -y "$@" || FALHAS+=("$*")
}

# Instala um .deb baixado de uma URL oficial (o proprio pacote configura o repositorio de atualizacoes)
deb_install() {
  local nome="$1" url="$2" tmp
  tmp="$(mktemp --suffix=.deb)"
  echo "   Instalando $nome..."
  if curl -fsSL -o "$tmp" "$url"; then
    sudo apt-get install -y "$tmp" || FALHAS+=("$nome")
  else
    FALHAS+=("$nome (download)")
  fi
  rm -f "$tmp"
}

# Instala um app grafico pelo Snap ou, se nao houver Snap, pelo Flatpak (Flathub)
gui_install() {
  local nome="$1" snap="$2" snap_flags="$3" flatpak_id="$4"
  if has snap; then
    if snap list "$snap" &>/dev/null; then echo "   [ok] $nome ja instalado"; return; fi
    echo "   Instalando $nome..."
    # shellcheck disable=SC2086
    sudo snap install "$snap" $snap_flags || FALHAS+=("$nome")
  elif has flatpak && [[ -n "$flatpak_id" ]]; then
    echo "   Instalando $nome..."
    flatpak install -y flathub "$flatpak_id" || FALHAS+=("$nome")
  else
    AVISOS+=("$nome: instale manualmente (nem Snap nem Flatpak disponiveis)")
  fi
}

npm_global() {
  if ! has npm; then FALHAS+=("$2 (npm nao encontrado)"); return; fi
  echo "   Instalando $2..."
  npm install -g "$1" || FALHAS+=("$2")
}

# --- Verificacoes iniciais ------------------------------------------------------

if ! has apt-get; then
  echo "Este script e para distribuicoes baseadas em Debian/Ubuntu (apt)."
  exit 1
fi

sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- 1. Sistema e pacotes basicos -------------------------------------------------

step "Atualizando o sistema"
sudo apt-get update && sudo apt-get upgrade -y

step "Pacotes basicos"
apt_install git curl wget unzip zip jq zsh build-essential ca-certificates gnupg \
  software-properties-common python3 python3-pip python3-venv

step "Oh My Zsh"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  echo "   [ok] ja instalado"
else
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  AVISOS+=("Para usar o zsh como shell padrao: chsh -s \$(which zsh)")
fi

# --- 2. Apps essenciais --------------------------------------------------------------

step "Apps essenciais"
if has google-chrome; then
  echo "   [ok] Google Chrome ja instalado"
elif [[ "$ARCH" == "amd64" ]]; then
  deb_install "Google Chrome" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
else
  AVISOS+=("Google Chrome: sem pacote oficial para $ARCH; use o Chromium")
fi

if has code; then
  echo "   [ok] Visual Studio Code ja instalado"
elif [[ "$ARCH" == "amd64" || "$ARCH" == "arm64" ]]; then
  echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
  [[ "$ARCH" == "amd64" ]] && VSC_OS="linux-deb-x64" || VSC_OS="linux-deb-arm64"
  deb_install "Visual Studio Code" "https://code.visualstudio.com/sha/download?build=stable&os=$VSC_OS"
fi

gui_install "Bitwarden" "bitwarden" ""          "com.bitwarden.desktop"
gui_install "Obsidian"  "obsidian"  "--classic" "md.obsidian.Obsidian"
AVISOS+=("Claude: nao ha app desktop oficial para Linux; use https://claude.ai no navegador")

# --- 3. Ferramentas de desenvolvimento ----------------------------------------------

step "GitHub CLI"
if has gh; then
  echo "   [ok] ja instalado"
else
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update && apt_install gh
fi

step "Node.js LTS (via nvm) e pnpm"
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh)"
fi
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
if nvm install --lts && nvm alias default 'lts/*'; then
  npm_global pnpm "pnpm"
else
  FALHAS+=("Node.js LTS")
fi

step "Bun"
if [[ -x "$HOME/.bun/bin/bun" ]] || has bun; then
  echo "   [ok] ja instalado"
else
  curl -fsSL https://bun.sh/install | bash || FALHAS+=("Bun")
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
  if has claude; then
    echo "   [ok] Claude Code ja instalado"
  else
    echo "   Instalando Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash || FALHAS+=("Claude Code")
  fi
  npm_global opencode-ai        "OpenCode"
  npm_global @openai/codex      "Codex CLI"
  npm_global @google/gemini-cli "Gemini CLI"
  if has ollama; then
    echo "   [ok] Ollama ja instalado"
  else
    curl -fsSL https://ollama.com/install.sh | sh || FALHAS+=("Ollama")
  fi
  AVISOS+=("Kiro e Google Antigravity: baixe o pacote .deb nos sites oficiais (kiro.dev e antigravity.google)")
fi

# --- 6. Opcionais (--extras) -------------------------------------------------------------

if [[ $EXTRAS -eq 1 ]]; then
  step "Opcionais"
  apt_install php-cli filezilla
  gui_install "Sublime Text"     "sublime-text"     "--classic" "com.sublimetext.three"
  gui_install "Insomnia"         "insomnia"         ""          "rest.insomnia.Insomnia"
  gui_install "Beekeeper Studio" "beekeeper-studio" ""          "io.beekeeperstudio.Studio"

  if has docker; then
    echo "   [ok] Docker ja instalado"
  else
    echo "   Instalando Docker Engine..."
    if curl -fsSL https://get.docker.com | sudo sh; then
      sudo usermod -aG docker "$USER"
      AVISOS+=("Docker: faca logout/login para usar o docker sem sudo")
    else
      FALHAS+=("Docker")
    fi
  fi

  if has az; then
    echo "   [ok] Azure CLI ja instalado"
  else
    curl -fsSL https://aka.ms/InstallAzureCLIDeb | sudo bash || FALHAS+=("Azure CLI")
  fi
fi

sudo apt-get autoremove -y

# --- Resumo -------------------------------------------------------------------------------

step "Resumo"
if [[ ${#FALHAS[@]} -gt 0 ]]; then
  echo "   Nao foi possivel instalar:"
  printf '   - %s\n' "${FALHAS[@]}"
else
  echo "   Tudo instalado sem erros."
fi
if [[ ${#AVISOS[@]} -gt 0 ]]; then
  echo "   Avisos:"
  printf '   - %s\n' "${AVISOS[@]}"
fi

cat <<'EOF'

Proximos passos:
  1. Feche e reabra o terminal (ou faca logout/login) para carregar nvm, Bun e o PATH.
  2. Faca login no Bitwarden, Chrome e VS Code (Settings Sync).
  3. Rode "gh auth login" e teste o SSH com "ssh -T git@github.com".
  4. Rode "claude" uma vez para fazer login no Claude Code.
EOF
