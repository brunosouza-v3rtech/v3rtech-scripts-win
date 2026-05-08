#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/wallpaper-rotator.ps1
# Versão: 1.2.0
# Data: 2026-05-08
# Objetivo: Rotação automática de wallpaper multi-monitor
# Uso: .\utils\wallpaper-rotator.ps1 -Path "C:\Imagens" [-IntervalMinutes 10]
# ==============================================================================

param(
    [Parameter(Mandatory)][string]$Path,
    [int]$IntervalMinutes = 10,
    [switch]$DryRun
)

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")

$isDry = $DryRun -or $global:DRY_RUN

if (-not (Test-Path $Path)) { Die "Pasta de wallpapers não encontrada: $Path" }

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    public const int SPI_SETDESKWALLPAPER = 20;
    public const int SPIF_UPDATEINIFILE   = 0x01;
    public const int SPIF_SENDCHANGE      = 0x02;
    public static void Set(string path) {
        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    }
}
"@

function Get-MonitorCount {
    if ($IsWindows) {
        try {
            $monitors = Get-CimInstance -Namespace root/wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction Stop
            return @($monitors).Count
        } catch { return 1 }
    }
    return 1
}

function Get-RandomImages {
    param([string]$Folder, [int]$Count)
    $images = Get-ChildItem -Path $Folder -Recurse -Include "*.jpg","*.jpeg","*.png","*.bmp" |
              Get-Random -Count $Count
    return @($images)
}

function Set-CombinedWallpaper {
    param([string[]]$ImagePaths)

    if ($ImagePaths.Count -eq 1) {
        [Wallpaper]::Set($ImagePaths[0])
        return
    }

    $bitmaps = $ImagePaths | ForEach-Object { [System.Drawing.Bitmap]::new($_) }
    $totalWidth  = ($bitmaps | Measure-Object -Property Width  -Sum).Sum
    $totalHeight = ($bitmaps | Measure-Object -Property Height -Maximum).Maximum

    $combined = [System.Drawing.Bitmap]::new($totalWidth, $totalHeight)
    $graphics  = [System.Drawing.Graphics]::FromImage($combined)
    $graphics.Clear([System.Drawing.Color]::Black)

    $x = 0
    foreach ($bmp in $bitmaps) {
        $graphics.DrawImage($bmp, $x, 0, $bmp.Width, $bmp.Height)
        $x += $bmp.Width
        $bmp.Dispose()
    }
    $graphics.Dispose()

    $tempFile = Join-Path $env:TEMP "v3rtech-wallpaper.jpg"
    $combined.Save($tempFile, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $combined.Dispose()

    [Wallpaper]::Set($tempFile)
}

$monitorCount = Get-MonitorCount
Log-Step "Iniciando rotação de wallpaper — $monitorCount monitor(es), intervalo: ${IntervalMinutes}min"
Log-Info "Pasta: $Path | Ctrl+C para parar"

while ($true) {
    $images = Get-RandomImages -Folder $Path -Count $monitorCount

    if ($images.Count -eq 0) {
        Log-Warn "Nenhuma imagem encontrada em: $Path"
        Start-Sleep -Seconds ($IntervalMinutes * 60)
        continue
    }

    $names = ($images | ForEach-Object { $_.Name }) -join ", "
    Log-Info "Aplicando: $names"

    if ($isDry) {
        Log-Info "[DRY-RUN] Aplicaria: $names (intervalo: ${IntervalMinutes}min)"
        break
    }

    try {
        Set-CombinedWallpaper -ImagePaths ($images | ForEach-Object { $_.FullName })
        Log-Success "Wallpaper atualizado."
    } catch {
        Log-Error "Falha ao aplicar wallpaper: $_"
    }

    Start-Sleep -Seconds ($IntervalMinutes * 60)
}
