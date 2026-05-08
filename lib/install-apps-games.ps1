#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/install-apps-games.ps1
# Versão: 1.1.0
# Objetivo: Instalar launchers e plataformas de games
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# Execução standalone: $env:DRY_RUN=1; .\lib\install-apps-games.ps1
# ==============================================================================

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")
. (Join-Path $BASE_DIR "core" "package-mgr.ps1")
. (Join-Path $BASE_DIR "lib" "apps-data.ps1")

if ($global:DRY_RUN) { Log-Warn "Modo DRY-RUN ativado — nenhuma instalação será realizada." }

function Install-Apps-Games {
    Log-Step "Instalando plataformas de games..."

    $apps = Get-AppsByCategory -Category "games"

    if ($apps.Count -eq 0) {
        Log-Warn "Nenhum app ativo na categoria 'games'."
        return
    }

    $ok = 0; $fail = 0
    foreach ($appName in $apps) {
        if (Install-App -AppName $appName) { $ok++ } else { $fail++ }
    }

    Log-Success "Games: $ok instalados, $fail falhas."
}

Install-Apps-Games
