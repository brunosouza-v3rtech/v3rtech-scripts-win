#!/usr/bin/env pwsh
# ==============================================================================
# Script: v3rtech-install.ps1
# Versao: 1.1.0
# Objetivo: Orquestrador principal — wizard CLI de instalacao Windows 11
# Autor: V3RTECH Tecnologia, Consultoria e Inovacao
# Website: https://v3rtech.com.br/
# ==============================================================================

$BASE_DIR = Split-Path -Parent $PSCommandPath
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")
. (Join-Path $BASE_DIR "core" "package-mgr.ps1")
. (Join-Path $BASE_DIR "lib" "apps-data.ps1")

trap { Log-Error $_.Exception.Message; exit 1 }

if ($global:DRY_RUN) {
    Write-Host ""
    Write-Host "  [DRY-RUN] Modo simulacao ativado - nenhuma alteracao sera feita." -ForegroundColor Yellow
    Write-Host ""
}

# ── Helpers ──────────────────────────────────────────────────────────────────

function Show-Header {
    Write-Host ""
    Write-Host "  ██╗   ██╗██████╗ ██████╗ ████████╗███████╗ ██████╗██╗  ██╗" -ForegroundColor Cyan
    Write-Host "  ██║   ██║╚════██╗██╔══██╗╚══██╔══╝██╔════╝██╔════╝██║  ██║" -ForegroundColor Cyan
    Write-Host "  ██║   ██║ █████╔╝██████╔╝   ██║   █████╗  ██║     ███████║" -ForegroundColor Cyan
    Write-Host "  ╚██╗ ██╔╝ ╚═══██╗██╔══██╗   ██║   ██╔══╝  ██║     ██╔══██║" -ForegroundColor Cyan
    Write-Host "   ╚████╔╝ ██████╔╝██║  ██║   ██║   ███████╗╚██████╗██║  ██║" -ForegroundColor Cyan
    Write-Host "    ╚═══╝  ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  v3rtech-scripts-win — Automacao Windows 11" -ForegroundColor White
    Write-Host "  Versao 1.1.0 | PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray
    Write-Host ""
}

function Invoke-Category {
    param([string]$Category)
    $script = Join-Path $BASE_DIR "lib" "install-apps-$Category.ps1"
    if (Test-Path $script) {
        & $script
    } else {
        Log-Warn "Script para categoria '$Category' nao encontrado: $script"
    }
}

function Show-CategoryMenu {
    $categories = @(
        @{ Key="1"; Name="internet";    Label="Internet    (Chrome, Firefox, Wavebox, Zen)" }
        @{ Key="2"; Name="dev";         Label="Dev         (VS Code, Git, Node.js, Docker)" }
        @{ Key="3"; Name="office";      Label="Escritorio  (LibreOffice, Notion, Sejda PDF)" }
        @{ Key="4"; Name="multimedia";  Label="Multimidia  (VLC, OBS, HandBrake, FileBot)" }
        @{ Key="5"; Name="design";      Label="Design      (Scribus, GIMP, Inkscape, Blender)" }
        @{ Key="6"; Name="system";      Label="Sistema     (7-Zip, PowerToys, Everything)" }
        @{ Key="7"; Name="games";       Label="Games       (Steam, Epic, GOG Galaxy)" }
        @{ Key="8"; Name="ia";          Label="IA          (Claude Desktop, Claude Code, Whisper, Codex)" }
    )

    do {
        Write-Host ""
        Write-Host "  Instalar por categoria:" -ForegroundColor White
        Write-Host ""
        foreach ($c in $categories) {
            Write-Host "  [$($c.Key)] $($c.Label)" -ForegroundColor Cyan
        }
        Write-Host "  [A] Todas as categorias" -ForegroundColor Yellow
        Write-Host "  [0] Voltar" -ForegroundColor DarkGray
        Write-Host ""

        $opt = if ($global:AUTO_CONFIRM) { "A" } else { (Read-Host "  > ").Trim() }

        switch ($opt.ToUpper()) {
            "1" { Invoke-Category "internet" }
            "2" { Invoke-Category "dev" }
            "3" { Invoke-Category "office" }
            "4" { Invoke-Category "multimedia" }
            "5" { Invoke-Category "design" }
            "6" { Invoke-Category "system" }
            "7" { Invoke-Category "games" }
            "8" { Invoke-Category "ia" }
            "A" {
                foreach ($c in $categories) { Invoke-Category $c.Name }
                Log-Success "Todas as categorias concluidas."
            }
            "0" { return }
            default { Log-Warn "Opcao invalida." }
        }
    } while ($opt -notin @("0"))
}

function Show-ProfileMenu {
    $profilesDir = Join-Path $BASE_DIR "profiles"
    $profileFiles = Get-ChildItem $profilesDir -Filter "*.json" | Sort-Object Name

    do {
        Write-Host ""
        Write-Host "  Instalar por perfil:" -ForegroundColor White
        Write-Host ""
        $i = 1
        $profiles = @()
        foreach ($f in $profileFiles) {
            $p = Get-Content $f.FullName -Raw | ConvertFrom-Json
            Write-Host "  [$i] $($p.name) — $($p.description)" -ForegroundColor Cyan
            $profiles += $p
            $i++
        }
        Write-Host "  [0] Voltar" -ForegroundColor DarkGray
        Write-Host ""

        $opt = if ($global:AUTO_CONFIRM) { "1" } else { (Read-Host "  > ").Trim() }

        if ($opt -eq "0") { return }

        $idx = $opt -as [int]
        if ($null -eq $idx) { Log-Warn "Opcao invalida."; continue }
        $idx = $idx - 1
        if ($idx -lt 0 -or $idx -ge $profiles.Count) {
            Log-Warn "Opcao invalida."
            continue
        }

        $selectedProfile = $profiles[$idx]
        Log-Step "Aplicando perfil: $($selectedProfile.name)"

        foreach ($category in $selectedProfile.categories) {
            Invoke-Category $category
        }

        if ($selectedProfile.apps_extra -and $selectedProfile.apps_extra.Count -gt 0) {
            Log-Step "Instalando apps extras do perfil..."
            foreach ($appName in $selectedProfile.apps_extra) {
                Install-App -AppName $appName
            }
        }

        Log-Success "Perfil '$($selectedProfile.name)' aplicado."
        return

    } while ($true)
}

function Show-MainMenu {
    Write-Host "  O que deseja fazer?" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Instalar apps por categoria" -ForegroundColor Cyan
    Write-Host "  [2] Instalar por perfil"         -ForegroundColor Cyan
    Write-Host "  [A] Instalar tudo (todas as categorias)" -ForegroundColor Yellow
    Write-Host "  [0] Sair"                        -ForegroundColor DarkGray
    Write-Host ""
}

# ── MAIN ─────────────────────────────────────────────────────────────────────

Show-Header

if (-not $global:CONFIG["windows_build"]) {
    . (Join-Path $BASE_DIR "lib" "detect-system.ps1")
}

do {
    Show-MainMenu
    $opt = if ($global:AUTO_CONFIRM) { "0" } else { Read-Host "  > " }

    switch ($opt.ToUpper()) {
        "1" { Show-CategoryMenu }
        "2" { Show-ProfileMenu }
        "A" {
            $all = @("internet","dev","office","multimedia","design","system","games","ia")
            foreach ($c in $all) { Invoke-Category $c }
            Log-Success "Todas as categorias instaladas."
        }
        "0" { Log-Info "Saindo."; break }
        default { Log-Warn "Opcao invalida." }
    }
} while ($opt -notmatch "^[0]$")
