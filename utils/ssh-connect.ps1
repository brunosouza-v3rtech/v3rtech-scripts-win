#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/ssh-connect.ps1
# Versão: 1.2.0
# Data: 2026-05-08
# Objetivo: Gerenciador de conexões SSH com fix automático de permissões de chave
# Uso: .\utils\ssh-connect.ps1 -HostAlias nas
#      .\utils\ssh-connect.ps1          (lista hosts disponíveis)
# Config: copie configs/ssh-hosts.example.ps1 → configs/ssh-hosts.ps1
# ==============================================================================

param([string]$HostAlias = "")

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")

$hostsFile = Join-Path $BASE_DIR "configs" "ssh-hosts.ps1"
if (-not (Test-Path $hostsFile)) {
    Log-Warn "Arquivo de hosts não encontrado: $hostsFile"
    Log-Info "Copie configs/ssh-hosts.example.ps1 → configs/ssh-hosts.ps1 e configure seus servidores."
    exit 1
}
. $hostsFile

function Set-SshKeyPermissions {
    param([string]$KeyPath)
    if (-not (Test-Path $KeyPath)) { Die "Chave SSH não encontrada: $KeyPath" }
    if (-not $IsWindows) { return }

    Log-Info "Corrigindo permissões da chave SSH: $KeyPath"
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    icacls $KeyPath /inheritance:r 2>$null | Out-Null
    takeown /F $KeyPath 2>$null | Out-Null
    icacls $KeyPath /grant:r "${currentUser}:F" 2>$null | Out-Null
    icacls $KeyPath /remove "Authenticated Users" 2>$null | Out-Null
    icacls $KeyPath /remove "BUILTIN\Administrators" 2>$null | Out-Null
    icacls $KeyPath /remove "Everyone" 2>$null | Out-Null
}

function Show-Hosts {
    Write-Host ""
    Write-Host "  Hosts SSH disponíveis:" -ForegroundColor Cyan
    Write-Host ""
    foreach ($alias in ($global:SSH_HOSTS.Keys | Sort-Object)) {
        $h = $global:SSH_HOSTS[$alias]
        $port = if ($h.Port -ne 22) { ":$($h.Port)" } else { "" }
        Write-Host "  $($alias.PadRight(20)) $($h.User)@$($h.Host)$port" -ForegroundColor White
    }
    Write-Host ""
}

if (-not $HostAlias) {
    Show-Hosts
    exit 0
}

$hostDef = $global:SSH_HOSTS[$HostAlias]
if (-not $hostDef) {
    Log-Error "Host '$HostAlias' não encontrado."
    Show-Hosts
    exit 1
}

$keyPath     = $global:SSH_KEY
$sshUser     = if ($hostDef.User) { $hostDef.User } else { $global:SSH_USER }
$sshHost     = $hostDef.Host
$sshPort     = if ($hostDef.Port) { $hostDef.Port } else { 22 }

Set-SshKeyPermissions -KeyPath $keyPath

Log-Step "Conectando a $HostAlias ($sshUser@${sshHost}:$sshPort)"
ssh -i $keyPath -p $sshPort "${sshUser}@${sshHost}"
