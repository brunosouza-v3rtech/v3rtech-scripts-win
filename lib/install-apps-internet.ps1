#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/install-apps-internet.ps1
# Versão: 1.1.0
# Objetivo: Instalar apps de Internet (navegadores, comunicação, nuvem)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Execução standalone: $env:DRY_RUN=1; .\lib\install-apps-internet.ps1
# ==============================================================================

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")
. (Join-Path $BASE_DIR "core" "package-mgr.ps1")
. (Join-Path $BASE_DIR "lib" "apps-data.ps1")

if ($global:DRY_RUN) { Log-Warn "Modo DRY-RUN ativado — nenhuma instalação será realizada." }

function Install-Apps-Internet {
    Log-Step "Instalando apps de Internet..."

    $apps = Get-AppsByCategory -Category "internet"

    if ($apps.Count -eq 0) {
        Log-Warn "Nenhum app ativo na categoria 'internet'."
        return
    }

    $ok = 0; $fail = 0
    foreach ($appName in $apps) {
        if (Install-App -AppName $appName) { $ok++ } else { $fail++ }
    }

    Log-Success "Internet: $ok instalados, $fail falhas."
}

Install-Apps-Internet
