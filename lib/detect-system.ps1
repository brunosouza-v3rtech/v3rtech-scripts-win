#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/detect-system.ps1
# Versão: 1.0.0
# Data: 2026-05-08
# Objetivo: Detecta Windows version, GPU, arquitetura, tipo de sessão
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

Log-Step "Detectando sistema..."

# Windows version
if ($IsWindows) {
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $global:CONFIG["windows_name"]    = $osInfo.Caption
    $global:CONFIG["windows_build"]   = $osInfo.BuildNumber
    $global:CONFIG["windows_version"] = [System.Environment]::OSVersion.Version.ToString()
} else {
    $global:CONFIG["windows_name"]    = "Linux (dev environment)"
    $global:CONFIG["windows_build"]   = "0"
    $global:CONFIG["windows_version"] = "0.0.0"
}

# Arquitetura
$global:CONFIG["arch"] = $env:PROCESSOR_ARCHITECTURE ?? "unknown"  # AMD64, ARM64

# Sessão (local, RDP, etc.)
$sessionType = if ($env:SESSIONNAME -eq "Console") { "local" }
               elseif ($env:SESSIONNAME -match "RDP") { "rdp" }
               else { "unknown" }
$global:CONFIG["session_type"] = $sessionType

# GPU vendor
if ($IsWindows) {
    $gpuName = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
    if (-not $gpuName) { $gpuName = "unknown" }
    $gpuVendor = switch -Regex ($gpuName) {
        "NVIDIA"      { "nvidia" }
        "AMD|Radeon"  { "amd" }
        "Intel"       { "intel" }
        default       { "unknown" }
    }
} else {
    $gpuName   = "unknown (dev environment)"
    $gpuVendor = "unknown"
}
$global:CONFIG["gpu_vendor"] = $gpuVendor
$global:CONFIG["gpu_name"]   = $gpuName

# Admin check
if ($IsWindows) {
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $global:IS_ADMIN  = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} else {
    $global:IS_ADMIN = $false
}

Log-Info "Sistema: $($global:CONFIG['windows_name']) (build $($global:CONFIG['windows_build']))"
Log-Info "Arch: $($global:CONFIG['arch']) | GPU: $gpuVendor ($gpuName)"
Log-Info "Sessão: $sessionType | Admin: $($global:IS_ADMIN)"

Save-Config
