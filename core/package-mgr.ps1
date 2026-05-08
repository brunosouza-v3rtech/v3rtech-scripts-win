#!/usr/bin/env pwsh
# ==============================================================================
# Script: core/package-mgr.ps1
# Versão: 1.0.0
# Data: 2026-05-08
# Objetivo: Abstração winget / chocolatey / scoop
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

function Test-Winget { return [bool](Get-Command winget -ErrorAction SilentlyContinue) }
function Test-Choco  { return [bool](Get-Command choco  -ErrorAction SilentlyContinue) }
function Test-Scoop  { return [bool](Get-Command scoop  -ErrorAction SilentlyContinue) }

function Bootstrap-Winget {
    if (Test-Winget) { return }
    Log-Warn "winget não encontrado. Tentando registrar Microsoft.DesktopAppInstaller..."
    if ($global:DRY_RUN) { Log-Info "[DRY-RUN] Registraria DesktopAppInstaller"; return }
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
}

function Bootstrap-Choco {
    if (Test-Choco) { return }
    Log-Info "Instalando Chocolatey..."
    if ($global:DRY_RUN) { Log-Info "[DRY-RUN] Instalaria Chocolatey"; return }
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

function Bootstrap-Scoop {
    if (Test-Scoop) { return }
    Log-Info "Instalando Scoop..."
    if ($global:DRY_RUN) { Log-Info "[DRY-RUN] Instalaria Scoop"; return }
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

function Test-AppInstalled {
    param([string]$AppName)
    if (-not (Test-Winget)) { return $false }
    $result = winget list --name $AppName --exact 2>$null
    return ($LASTEXITCODE -eq 0 -and $result -match [regex]::Escape($AppName))
}

function Install-ViaWinget {
    param([string]$WingetId)
    if (-not $WingetId) { return $false }
    Log-Info "winget: $WingetId"
    if ($global:DRY_RUN) { Log-Info "[DRY-RUN] winget install --id $WingetId -e --silent"; return $true }
    winget install --id $WingetId -e --silent --accept-package-agreements --accept-source-agreements
    return ($LASTEXITCODE -eq 0)
}

function Install-ViaChoco {
    param([string]$ChocoId)
    if (-not $ChocoId) { return $false }
    Log-Info "choco: $ChocoId"
    if ($global:DRY_RUN) { Log-Info "[DRY-RUN] choco install $ChocoId -y"; return $true }
    choco install $ChocoId -y
    return ($LASTEXITCODE -eq 0)
}

function Install-ViaScoop {
    param([string]$ScoopId, [string]$ScoopBucket = "")
    if (-not $ScoopId) { return $false }
    Log-Info "scoop: $ScoopId"
    if ($global:DRY_RUN) { Log-Info "[DRY-RUN] scoop install $ScoopId"; return $true }
    if ($ScoopBucket) { scoop bucket add $ScoopBucket 2>$null }
    scoop install $ScoopId
    return ($LASTEXITCODE -eq 0)
}

function Get-InstallOrder {
    param([hashtable]$App)
    $order = [System.Collections.Generic.List[string]]::new()

    $explicit = $App.Method
    if ($explicit -and $explicit -ne "any") { $order.Add($explicit) }

    $priority = if ($global:CONFIG["prefer_winget"]) { @("winget","choco","scoop") }
                else                                  { @("choco","winget","scoop") }

    foreach ($m in $priority) { if (-not $order.Contains($m)) { $order.Add($m) } }
    return $order.ToArray()
}

function Install-App {
    param([string]$AppName)

    $app = $global:APP_MAP[$AppName]
    if (-not $app) { Log-Warn "App '$AppName' não encontrado."; return $false }

    if (Test-AppInstalled -AppName $AppName) {
        Log-Info "'$AppName' já instalado. Pulando."
        return $true
    }

    Log-Step "Instalando $AppName..."
    $methods = Get-InstallOrder -App $app

    foreach ($method in $methods) {
        $ok = switch ($method) {
            "winget" { Install-ViaWinget -WingetId $app.WingetId }
            "choco"  { Install-ViaChoco  -ChocoId  $app.ChocoId  }
            "scoop"  { Install-ViaScoop  -ScoopId  $app.ScoopId  }
            default  { $false }
        }
        if ($ok) { Log-Success "$AppName instalado via $method."; return $true }
    }

    Log-Error "Falha ao instalar '$AppName' por todos os métodos."
    return $false
}

# Bootstrap winget no carregamento do módulo
Bootstrap-Winget
