#!/usr/bin/env pwsh
# ==============================================================================
# Script: v3rtech-install.ps1
# Versão: 1.0.0
# Objetivo: Orquestrador principal — wizard CLI de instalação
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

$BASE_DIR = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")
. (Join-Path $BASE_DIR "core" "package-mgr.ps1")
. (Join-Path $BASE_DIR "lib" "apps-data.ps1")

trap { Log-Error $_.Exception.Message; exit 1 }

if ($global:DRY_RUN) {
    Write-Host ""
    Write-Host "  [DRY-RUN] Modo simulação ativado — nenhuma alteração será feita." -ForegroundColor Yellow
    Write-Host ""
}

function Show-Header {
    Write-Host ""
    Write-Host "  ██╗   ██╗██████╗ ██████╗ ████████╗███████╗ ██████╗██╗  ██╗" -ForegroundColor Cyan
    Write-Host "  ██║   ██║╚════██╗██╔══██╗╚══██╔══╝██╔════╝██╔════╝██║  ██║" -ForegroundColor Cyan
    Write-Host "  ██║   ██║ █████╔╝██████╔╝   ██║   █████╗  ██║     ███████║" -ForegroundColor Cyan
    Write-Host "  ╚██╗ ██╔╝ ╚═══██╗██╔══██╗   ██║   ██╔══╝  ██║     ██╔══██║" -ForegroundColor Cyan
    Write-Host "   ╚████╔╝ ██████╔╝██║  ██║   ██║   ███████╗╚██████╗██║  ██║" -ForegroundColor Cyan
    Write-Host "    ╚═══╝  ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  v3rtech-scripts-win — Automação Windows 11" -ForegroundColor White
    Write-Host "  Versão 1.0.0 | PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Menu {
    Write-Host "  Selecione uma opção:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Instalar apps — Internet"   -ForegroundColor Cyan
    Write-Host "  [2] Instalar apps — Dev"         -ForegroundColor Cyan
    Write-Host "  [3] Instalar perfil completo"    -ForegroundColor Cyan
    Write-Host "  [0] Sair"                        -ForegroundColor DarkGray
    Write-Host ""
}

function Invoke-ProfileInstall {
    $profilesDir = Join-Path $BASE_DIR "profiles"
    $profileFiles = Get-ChildItem $profilesDir -Filter "*.json" | Sort-Object Name

    Write-Host ""
    Write-Host "  Perfis disponíveis:" -ForegroundColor White
    $i = 1
    $profiles = @()
    foreach ($f in $profileFiles) {
        $p = Get-Content $f.FullName -Raw | ConvertFrom-Json
        Write-Host "  [$i] $($p.name) — $($p.description)" -ForegroundColor Cyan
        $profiles += $p
        $i++
    }
    Write-Host ""

    $choice = if ($global:AUTO_CONFIRM) { "1" } else { Read-Host "  Escolha o perfil" }
    $idx = [int]$choice - 1
    if ($idx -lt 0 -or $idx -ge $profiles.Count) { Log-Warn "Opção inválida."; return }

    $selectedProfile = $profiles[$idx]
    Log-Step "Aplicando perfil: $($selectedProfile.name)"

    foreach ($category in $selectedProfile.categories) {
        $script = Join-Path $BASE_DIR "lib" "install-apps-$category.ps1"
        if (Test-Path $script) {
            Log-Info "Categoria: $category"
            & $script
        } else {
            Log-Warn "Categoria '$category' ainda não implementada (Plano 2)."
        }
    }
}

# ── MAIN ─────────────────────────────────────────────────────────────────────

Show-Header

# Detectar sistema na primeira execução
if (-not $global:CONFIG["windows_build"]) {
    . (Join-Path $BASE_DIR "lib" "detect-system.ps1")
}

do {
    Show-Menu
    $opt = if ($global:AUTO_CONFIRM) { "0" } else { Read-Host "  > " }

    switch ($opt) {
        "1" { & (Join-Path $BASE_DIR "lib" "install-apps-internet.ps1") }
        "2" {
            Log-Warn "Categoria 'dev' será implementada no Plano 2."
        }
        "3" { Invoke-ProfileInstall }
        "0" { Log-Info "Saindo."; break }
        default { Log-Warn "Opção inválida." }
    }
} while ($opt -ne "0")
