# 🚀 Basic Dev Setup Script

Configure um computador recém-formatado para desenvolvimento com um único comando, no **Windows**, no **macOS** ou no **Linux (Ubuntu/Debian)**.

Os scripts instalam apps essenciais, ferramentas de desenvolvimento e ferramentas de IA, configuram o Git e, se você quiser, geram uma chave SSH. Tudo o que já estiver instalado é pulado, então dá para rodar de novo sem problema. No fim, aparece um resumo do que falhou e dos próximos passos.

## 🛠️ O que é instalado

| Categoria | Windows (winget) | macOS (Homebrew) | Linux (apt + Snap/Flatpak) |
| --- | --- | --- | --- |
| **Apps essenciais** | Bitwarden, Google Chrome, VS Code, Claude, Obsidian, PowerShell 7, Windows Terminal, 7-Zip, PowerToys | Bitwarden, Google Chrome, VS Code, Claude, Obsidian, Warp, Oh My Zsh | Bitwarden, Google Chrome, VS Code, Obsidian, Oh My Zsh |
| **Desenvolvimento** | Git, GitHub CLI, nvm + Node.js LTS, pnpm, Bun, Python 3.13 | Xcode CLT, Git, GitHub CLI, nvm + Node.js LTS, pnpm, Bun, Python 3.13, wget, jq | Git, GitHub CLI, nvm + Node.js LTS, pnpm, Bun, Python 3, build-essential, wget, jq |
| **IA** | Claude Code, OpenCode, Codex CLI, Gemini CLI, Ollama, Kiro, Google Antigravity | Claude Code, OpenCode, Codex CLI, Gemini CLI, Ollama, Kiro, Google Antigravity | Claude Code, OpenCode, Codex CLI, Gemini CLI, Ollama |
| **Opcionais** (`-Extras` / `--extras`) | PHP, wget, Sublime Text, Insomnia, Beekeeper Studio, Azure CLI, WSL, Docker Desktop | PHP, Sublime Text, Insomnia, Beekeeper Studio, Docker Desktop, Arc, Hyper | PHP, FileZilla, Sublime Text, Insomnia, Beekeeper Studio, Docker Engine, Azure CLI |

Além disso, os três scripts:

- pedem seu nome e e-mail para o Git, caso ainda não estejam configurados, e definem `main` como branch padrão;
- oferecem gerar uma chave SSH `ed25519`. Se você tem um backup da pasta `.ssh`, recuse e restaure o backup.

> **Linux:** o app desktop do Claude não tem versão oficial para Linux (use [claude.ai](https://claude.ai) no navegador). Kiro e Antigravity precisam ser baixados nos sites oficiais. O script avisa sobre isso no resumo final.

## 📥 Como usar

Antes de rodar, leia o script do seu sistema. É uma boa prática com qualquer script que instala programas.

### Windows

1. Atualize o Windows e o **App Installer** pela Microsoft Store (ele traz o `winget`).
2. Abra o **PowerShell como Administrador**.
3. Clone o repositório (ou baixe o ZIP pelo GitHub) e rode o script:

```powershell
git clone https://github.com/yaakovcarioca/basic-dev-setup-script.git
cd basic-dev-setup-script
powershell -ExecutionPolicy Bypass -File .\basic_setup_windows.ps1
```

Sem o Git instalado, dá para rodar direto do GitHub:

```powershell
irm https://raw.githubusercontent.com/yaakovcarioca/basic-dev-setup-script/main/basic_setup_windows.ps1 | iex
```

Opções: `-Extras` (instala os opcionais) e `-SkipAI` (pula as ferramentas de IA).

### macOS

```bash
git clone https://github.com/yaakovcarioca/basic-dev-setup-script.git
cd basic-dev-setup-script
chmod +x basic_setup_mac.sh
./basic_setup_mac.sh
```

Opções: `--extras` e `--skip-ai`. O script pede a senha de administrador uma vez no início. Se o Git ainda não estiver instalado, baixe o ZIP pelo GitHub em vez de clonar.

### Linux (Ubuntu, Debian e derivados)

```bash
git clone https://github.com/yaakovcarioca/basic-dev-setup-script.git
cd basic-dev-setup-script
chmod +x basic_setup_linux.sh
./basic_setup_linux.sh
```

Opções: `--extras` e `--skip-ai`. Rode como seu usuário normal, sem `sudo`. O script pede a senha quando precisar.

## ✅ Depois de rodar

1. Reinicie o computador, ou pelo menos feche e reabra o terminal.
2. Faça login no Bitwarden, no Chrome e no VS Code (ative o Settings Sync para recuperar extensões e configurações).
3. Rode `gh auth login` e teste o SSH com `ssh -T git@github.com`.
4. Rode `claude` uma vez para fazer login no Claude Code.
5. Restaure seus backups (projetos, chave SSH, configurações) e rode `pnpm install` ou `npm install` em cada projeto.

## ➕ Personalizando

Para adicionar um app, inclua uma linha na seção correspondente do script:

- **Windows:** `Install-App '<ID do winget>' '<Nome>'`. Para achar o ID, use `winget search <nome>`.
- **macOS:** inclua o nome na lista de `brew_cask` (apps) ou `brew_formula` (ferramentas de terminal). Para buscar, use `brew search <nome>`.
- **Linux:** use `apt_install <pacote>` ou `gui_install "<Nome>" "<snap>" "<flags>" "<id do Flatpak>"`.

## 📝 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

---

Desenvolvido com ❤️ por [Yaakov Carioca](https://github.com/yaakovcarioca)
