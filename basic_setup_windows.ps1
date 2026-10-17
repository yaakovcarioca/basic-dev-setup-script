<#
.SYNOPSIS
    Configura um Windows 10/11 recem-formatado para desenvolvimento, usando o winget.

.DESCRIPTION
    Instala apps essenciais, ferramentas de desenvolvimento e ferramentas de IA.
    Apps ja instalados sao pulados, entao o script pode ser executado mais de uma vez.

.PARAMETER Extras
    Instala tambem os opcionais: PHP, wget, Sublime Text, Insomnia,
    Beekeeper Studio, Azure CLI, WSL e Docker Desktop.

.PARAMETER SkipAI
    Pula as ferramentas de IA (Claude Code, OpenCode, Codex, Gemini CLI, Ollama, Kiro, Antigravity).

.EXAMPLE
    .\basic_setup_windows.ps1
.EXAMPLE
    .\basic_setup_windows.ps1 -Extras
#>
param(
    [switch]$Extras,
    [switch]$SkipAI
)

$ErrorActionPreference = 'Continue'
$script:Falhas = New-Object System.Collections.Generic.List[string]

function Write-Step([string]$Texto) {
    Write-Host ''
    Write-Host "==> $Texto" -ForegroundColor Cyan
}

function Update-SessionPath {
    # Recarrega o PATH e as variaveis do nvm sem precisar reabrir o terminal
    $maquina = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $usuario = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$maquina;$usuario"
    foreach ($nome in 'NVM_HOME', 'NVM_SYMLINK') {
        $valor = [Environment]::GetEnvironmentVariable($nome, 'Machine')
        if (-not $valor) { $valor = [Environment]::GetEnvironmentVariable($nome, 'User') }
        if ($valor) { Set-Item -Path "env:$nome" -Value $valor }
    }
}

function Install-App([string]$Id, [string]$Nome) {
    winget list --id $Id -e --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   [ok] $Nome ja instalado" -ForegroundColor DarkGray
        return
    }
    Write-Host "   Instalando $Nome..."
    winget install --id $Id -e --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { $script:Falhas.Add($Nome) }
}

function Install-NpmGlobal([string]$Pacote, [string]$Nome) {
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        $script:Falhas.Add("$Nome (npm nao encontrado)")
        return
    }
    Write-Host "   Instalando $Nome..."
    npm install -g $Pacote
    if ($LASTEXITCODE -ne 0) { $script:Falhas.Add($Nome) }
}

# --- Verificacoes iniciais ----------------------------------------------------

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Write-Host 'Execute este script em um PowerShell aberto como Administrador.' -ForegroundColor Red
    exit 1
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host 'winget nao encontrado. Atualize o "App Installer" pela Microsoft Store e rode de novo.' -ForegroundColor Red
    exit 1
}

# --- 1. Apps essenciais --------------------------------------------------------

Write-Step 'Apps essenciais'
Install-App 'Bitwarden.Bitwarden'        'Bitwarden'
Install-App 'Google.Chrome'              'Google Chrome'
Install-App 'Microsoft.VisualStudioCode' 'Visual Studio Code'
Install-App 'Anthropic.Claude'           'Claude (desktop)'
Install-App 'Obsidian.Obsidian'          'Obsidian'
Install-App 'Microsoft.PowerShell'       'PowerShell 7'
Install-App 'Microsoft.WindowsTerminal'  'Windows Terminal'
Install-App '7zip.7zip'                  '7-Zip'
Install-App 'Microsoft.PowerToys'        'PowerToys'

# --- 2. Ferramentas de desenvolvimento -----------------------------------------

Write-Step 'Ferramentas de desenvolvimento'
Install-App 'Git.Git'                    'Git'
Install-App 'GitHub.cli'                 'GitHub CLI'
Install-App 'CoreyButler.NVMforWindows'  'NVM for Windows'
Install-App 'Oven-sh.Bun'                'Bun'
Install-App 'Python.Python.3.13'         'Python 3.13'
Update-SessionPath

Write-Step 'Node.js LTS (via nvm) e pnpm'
if (Get-Command nvm -ErrorAction SilentlyContinue) {
    nvm install lts
    $versao = (nvm list | Select-String -Pattern '\d+\.\d+\.\d+' | Select-Object -First 1).Matches.Value
    if ($versao) {
        nvm use $versao
        Update-SessionPath
        Install-NpmGlobal 'pnpm' 'pnpm'
    } else {
        $script:Falhas.Add('Node.js LTS')
    }
} else {
    $script:Falhas.Add('Node.js (nvm nao encontrado; reabra o terminal e rode o script de novo)')
}

# --- 3. Configuracao do Git e SSH ----------------------------------------------

Write-Step 'Configuracao do Git'
if (Get-Command git -ErrorAction SilentlyContinue) {
    if (-not (git config --global user.name)) {
        $gitNome = Read-Host '   Seu nome para os commits (Enter para pular)'
        if ($gitNome) { git config --global user.name $gitNome }
    }
    if (-not (git config --global user.email)) {
        $gitEmail = Read-Host '   Seu e-mail para os commits (Enter para pular)'
        if ($gitEmail) { git config --global user.email $gitEmail }
    }
    git config --global init.defaultBranch main
} else {
    Write-Host '   Git nao encontrado no PATH; configure depois de reabrir o terminal.' -ForegroundColor Yellow
}

Write-Step 'Chave SSH'
$chave = Join-Path $HOME '.ssh\id_ed25519'
if (Test-Path $chave) {
    Write-Host '   [ok] Chave SSH ja existe' -ForegroundColor DarkGray
} else {
    Write-Host '   Se voce tem um backup da pasta .ssh, responda N e restaure-a depois.'
    $resposta = Read-Host '   Gerar uma nova chave SSH agora? (s/N)'
    if ($resposta -match '^[sSyY]') {
        $comentario = git config --global user.email
        if (-not $comentario) { $comentario = $env:USERNAME }
        New-Item -ItemType Directory -Force -Path (Split-Path $chave) | Out-Null
        ssh-keygen -t ed25519 -C $comentario -f $chave
        Write-Host "   Chave publica criada em $chave.pub. Adicione-a no GitHub (gh ssh-key add)."
    }
}

# --- 4. Ferramentas de IA ------------------------------------------------------

if (-not $SkipAI) {
    Write-Step 'Ferramentas de IA'
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Write-Host '   [ok] Claude Code ja instalado' -ForegroundColor DarkGray
    } else {
        Write-Host '   Instalando Claude Code...'
        try { Invoke-RestMethod 'https://claude.ai/install.ps1' | Invoke-Expression }
        catch { $script:Falhas.Add('Claude Code') }
    }
    Install-App 'SST.opencode'    'OpenCode'
    Install-App 'Ollama.Ollama'   'Ollama'
    Install-App 'Amazon.Kiro'     'Kiro'
    Install-App 'Google.Antigravity' 'Google Antigravity'
    Install-NpmGlobal '@openai/codex'      'Codex CLI'
    Install-NpmGlobal '@google/gemini-cli' 'Gemini CLI'
}

# --- 5. Opcionais (-Extras) ----------------------------------------------------

if ($Extras) {
    Write-Step 'Opcionais'
    Install-App 'PHP.PHP.8.4'                       'PHP 8.4'
    Install-App 'JernejSimoncic.Wget'               'wget'
    Install-App 'SublimeHQ.SublimeText.4'           'Sublime Text'
    Install-App 'Insomnia.Insomnia'                 'Insomnia'
    Install-App 'beekeeper-studio.beekeeper-studio' 'Beekeeper Studio'
    Install-App 'Microsoft.AzureCLI'                'Azure CLI'

    Write-Host '   Habilitando o WSL (necessario para o Docker)...'
    wsl --install --no-distribution
    Install-App 'Docker.DockerDesktop' 'Docker Desktop'

    Write-Host '   FileZilla nao esta disponivel no winget: baixe em https://filezilla-project.org' -ForegroundColor Yellow
}

# --- Resumo --------------------------------------------------------------------

Write-Step 'Resumo'
if ($script:Falhas.Count -gt 0) {
    Write-Host '   Nao foi possivel instalar:' -ForegroundColor Yellow
    $script:Falhas | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
    Write-Host '   Tente de novo com: winget install --id <ID> -e   (ou procure com: winget search <nome>)'
} else {
    Write-Host '   Tudo instalado sem erros.' -ForegroundColor Green
}

Write-Host ''
Write-Host 'Proximos passos:'
Write-Host '  1. Reinicie o computador (necessario para PATH, WSL e Docker).'
Write-Host '  2. Faca login no Bitwarden, Chrome, VS Code (Settings Sync) e no app do Claude.'
Write-Host '  3. Rode "gh auth login" e teste o SSH com "ssh -T git@github.com".'
Write-Host '  4. Rode "claude" uma vez para fazer login no Claude Code.'
