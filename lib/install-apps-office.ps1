#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/install-apps-office.ps1
# Versão: 1.1.0
# Data: 2026-05-08
# Objetivo: Instalar apps de Escritório (suites, PDF, notes)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# Execução standalone: $env:DRY_RUN=1; .\lib\install-apps-office.ps1
# ==============================================================================

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")
. (Join-Path $BASE_DIR "core" "package-mgr.ps1")
. (Join-Path $BASE_DIR "lib" "apps-data.ps1")

if ($global:DRY_RUN) { Log-Warn "Modo DRY-RUN ativado — nenhuma instalação será realizada." }

function Install-Apps-Office {
    Log-Step "Instalando apps de Escritório..."

    $apps = Get-AppsByCategory -Category "office"

    if ($apps.Count -eq 0) {
        Log-Warn "Nenhum app ativo na categoria 'office'."
        return
    }

    $ok = 0; $fail = 0
    foreach ($appName in $apps) {
        if (Install-App -AppName $appName) { $ok++ } else { $fail++ }
    }

    Log-Success "Office: $ok instalados, $fail falhas."
}

Install-Apps-Office
