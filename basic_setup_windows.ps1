
# PowerShell Script to Automate Windows Development Setup

# Set PowerShell Execution Policy to Unrestricted
Set-ExecutionPolicy Bypass -Scope Process -Force

# Install Chocolatey (Windows Package Manager)
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Output 'Instalando o Chocolatey...'
    Set-ExecutionPolicy Bypass -Scope Process -Force; 
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
} else {
    Write-Output 'Chocolatey já está instalado!'
}

# Atualiza todos os pacotes existentes
choco upgrade all -y

# Instala ferramentas de desenvolvimento
Write-Output 'Instalando ferramentas de desenvolvimento...'
choco install git -y
choco install nodejs -y
choco install php -y
choco install wget -y

# Instala aplicativos essenciais
Write-Output 'Instalando aplicativos essenciais...'
choco install vscode -y
choco install sublimetext3 -y
choco install googlechrome -y
choco install filezilla -y
choco install insomnia-rest-api-client -y
choco install beekeeper-studio -y

# Limpeza
Write-Output 'Limpando o sistema...'
choco clean

Write-Output 'Configuração concluída! Pronto para desenvolver!'
