# 🚀 Mac & Windows Setup Script

Automatize a configuração do seu ambiente de desenvolvimento em um novo Mac ou Windows com apenas um comando! Este script instala todas as ferramentas e aplicativos essenciais, economizando tempo e esforço.

## 🛠️ O que este script faz?

### Para Mac
- Atualiza o macOS e instala ferramentas básicas
- Instala o Homebrew e atualiza pacotes
- Instala ferramentas de desenvolvimento:
  - Xcode Command Line Tools
  - Node.js
  - PHP
  - Git
  - wget
- Instala aplicativos via Homebrew Cask:
  - Visual Studio Code
  - Sublime Text
  - Google Chrome
  - Arc Browser
  - FileZilla
  - Insomnia
  - Beekeeper Studio

### Para Windows
- Instala o gerenciador de pacotes Chocolatey
- Instala ferramentas de desenvolvimento:
  - Node.js
  - PHP
  - Git
  - wget
- Instala aplicativos essenciais:
  - Visual Studio Code
  - Sublime Text
  - Google Chrome
  - FileZilla
  - Insomnia
  - Beekeeper Studio

---

## 📥 Como usar?

### Para Mac
1. Clone o repositório (se não possuir git, apenas faça download e continue...) :
```bash
git clone https://github.com/yaakovcarioca/basic-dev-setup-script.git
cd basic-dev-setup-script
```

2. Torne o script executável:
```bash
chmod +x basic_setup_mac.sh
```

3. Execute o script:
```bash
./basic_setup_mac.sh
```

### Para Windows
1. Clone o repositório (se não possuir git, apenas faça download e continue...) :
```powershell
git clone https://github.com/yaakovcarioca/basic-dev-setup-script.git
cd basic-dev-setup-script
```

2. Permita a execução de scripts no PowerShell:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

3. Execute o script:
```powershell
./basic_setup_windows.ps1
```

---

## 💡 Dicas
- Certifique-se de que o Terminal (ou PowerShell) tenha permissões administrativas.
- Mantenha o sistema operacional atualizado antes de executar o script.
- Se desejar adicionar mais aplicativos, edite o script e inclua-os na seção de instalação do gerenciador de pacotes (Homebrew ou Chocolatey).

---

## 📝 Licença
Este projeto está licenciado sob a [MIT License](LICENSE).

---

Desenvolvido com ❤️ por [Yaakov Carioca](https://github.com/yaakovcarioca)
