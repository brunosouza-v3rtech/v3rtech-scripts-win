#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/img-convert.ps1
# Versão: 1.2.0
# Data: 2026-05-08
# Objetivo: Converte imagens para JPG com ImageMagick (recursivo)
# Uso: .\utils\img-convert.ps1 -Path "C:\Fotos" [-MaxWidth 1920] [-Quality 90]
# Requer: ImageMagick instalado (winget install ImageMagick.ImageMagick)
# ==============================================================================

param(
    [Parameter(Mandatory)][string]$Path,
    [int]$MaxWidth = 1920,
    [int]$Quality  = 90,
    [switch]$DryRun
)

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")

$isDry = $DryRun -or $global:DRY_RUN

if (-not (Test-Path $Path)) { Die "Caminho não encontrado: $Path" }

$magick = Get-Command magick -ErrorAction SilentlyContinue
if (-not $magick) { Die "ImageMagick não encontrado. Instale com: winget install ImageMagick.ImageMagick" }

$extensions = @("*.png", "*.webp", "*.tiff", "*.tif", "*.gif", "*.bmp", "*.jpeg")
$files = $extensions | ForEach-Object { Get-ChildItem -Path $Path -Filter $_ -Recurse } | Sort-Object FullName

if ($files.Count -eq 0) {
    Log-Info "Nenhuma imagem encontrada em: $Path"
    exit 0
}

Log-Step "Convertendo $($files.Count) imagem(ns) para JPG em: $Path"

$ok = 0; $fail = 0; $logFile = Join-Path $Path "conversion_errors.log"

foreach ($file in $files) {
    $dest = [System.IO.Path]::ChangeExtension($file.FullName, ".jpg")
    Log-Info "Convertendo: $($file.Name) → $([System.IO.Path]::GetFileName($dest))"

    if ($isDry) {
        Log-Info "[DRY-RUN] magick `"$($file.FullName)`" -resize ${MaxWidth}x${MaxWidth}> -quality $Quality `"$dest`""
        $ok++
        continue
    }

    try {
        & magick $file.FullName -resize "${MaxWidth}x${MaxWidth}>" -quality $Quality $dest
        if ($LASTEXITCODE -ne 0) { throw "exit $LASTEXITCODE" }

        $converted = $file.FullName + ".converted"
        Rename-Item -Path $file.FullName -NewName ([System.IO.Path]::GetFileName($converted))
        Remove-Item -Path $converted -Force
        $ok++
    } catch {
        $msg = "ERRO: $($file.FullName) — $_"
        Log-Error $msg
        Add-Content -Path $logFile -Value $msg -Encoding UTF8
        $fail++
    }
}

Log-Success "Concluído: $ok convertidos, $fail falhas."
if ($fail -gt 0) { Log-Warn "Erros em: $logFile" }
