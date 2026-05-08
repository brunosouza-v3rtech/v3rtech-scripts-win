#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/upall.ps1
# Versão: 1.2.0
# Data: 2026-05-08
# Objetivo: Atualiza todos os gerenciadores de pacotes instalados
# Uso: .\utils\upall.ps1 [-DryRun]
# ==============================================================================

param([switch]$DryRun)

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")

$isDry = $DryRun -or $global:DRY_RUN

Log-Step "Atualizando todos os gerenciadores de pacotes..."

function Update-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Log-Warn "winget não encontrado. Pulando."
        return
    }
    Log-Info "winget upgrade --all"
    if ($isDry) { Log-Info "[DRY-RUN] winget upgrade --all --silent"; return }
    winget upgrade --all --accept-package-agreements --accept-source-agreements `
        --ignore-warnings --disable-interactivity --include-pinned --silent
    if ($LASTEXITCODE -eq 0) { Log-Success "winget: atualização concluída." }
    else { Log-Warn "winget: concluído com avisos (exit $LASTEXITCODE)." }
}

function Update-Choco {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Log-Warn "chocolatey não encontrado. Pulando."
        return
    }
    Log-Info "choco upgrade all"
    if ($isDry) { Log-Info "[DRY-RUN] choco upgrade all -y"; return }
    choco upgrade all -y
    if ($LASTEXITCODE -eq 0) { Log-Success "chocolatey: atualização concluída." }
    else { Log-Warn "chocolatey: concluído com avisos (exit $LASTEXITCODE)." }
}

function Update-Scoop {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Log-Warn "scoop não encontrado. Pulando."
        return
    }
    Log-Info "scoop update *"
    if ($isDry) { Log-Info "[DRY-RUN] scoop update * ; scoop cleanup *"; return }
    scoop update *
    scoop cleanup *
    Log-Success "scoop: atualização concluída."
}

Update-Winget
Update-Choco
Update-Scoop

Log-Success "Todos os gerenciadores atualizados."
