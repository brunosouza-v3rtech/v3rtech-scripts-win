#!/usr/bin/env pwsh
# ==============================================================================
# Script: core/env.ps1
# Versão: 1.0.0
# Data: 2026-05-08
# Objetivo: Variáveis globais, configuração persistente, flags de execução
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Localização do projeto
# Use BASE_DIR pré-definido pelo script chamador (se existir) para evitar
# caminhos errados quando dot-sourced de profundidades variadas.
# Caso contrário, calcula a partir do PSScriptRoot de env.ps1 (core/ → pai).
# ---------------------------------------------------------------------------
if (-not $global:BASE_DIR) {
    $global:BASE_DIR = Split-Path -Parent $PSScriptRoot
}

# Resolve home directory cross-platform (Windows: USERPROFILE, Linux/macOS: HOME)
$script:_homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
$global:CONFIG_DIR  = Join-Path $script:_homeDir ".config" "v3rtech-scripts-win"
$global:CONFIG_FILE = Join-Path $global:CONFIG_DIR "config.json"
$global:LOG_DIR     = Join-Path $global:CONFIG_DIR "logs"
$global:LOG_FILE    = Join-Path $global:LOG_DIR    "v3rtech-install.log"

# Expose the resolved home directory for tests and other modules
$global:HOME_DIR    = $script:_homeDir

# ---------------------------------------------------------------------------
# Flags de execução — variáveis de ambiente têm prioridade
# ---------------------------------------------------------------------------
$global:DRY_RUN      = ($env:DRY_RUN      -eq "1")
$global:VERBOSE_MODE = ($env:VERBOSE      -eq "1")
$global:AUTO_CONFIRM = ($env:AUTO_CONFIRM -eq "1")

# ---------------------------------------------------------------------------
# Configuração padrão (preenchida / sobrescrita por Load-Config)
# ---------------------------------------------------------------------------
$global:CONFIG = [ordered]@{
    prefer_winget      = $true
    install_categories = @()
    last_update        = ""
}

# ---------------------------------------------------------------------------
# Funções de persistência
# ---------------------------------------------------------------------------
function Save-Config {
    if (-not (Test-Path $global:CONFIG_DIR)) {
        New-Item -ItemType Directory -Path $global:CONFIG_DIR -Force | Out-Null
    }
    $global:CONFIG | ConvertTo-Json -Depth 3 | Set-Content $global:CONFIG_FILE -Encoding UTF8
}

function Load-Config {
    if (-not (Test-Path $global:CONFIG_FILE)) { return }
    $json = Get-Content $global:CONFIG_FILE -Raw | ConvertFrom-Json
    foreach ($key in $json.PSObject.Properties.Name) {
        $global:CONFIG[$key] = $json.$key
    }
}

# ---------------------------------------------------------------------------
# Garantir diretórios de trabalho
# ---------------------------------------------------------------------------
foreach ($dir in @($global:CONFIG_DIR, $global:LOG_DIR)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Carregar config persistida (se existir)
Load-Config
