#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/mkv-extract-subtitles.ps1
# Versão: 1.2.0
# Data: 2026-05-08
# Objetivo: Extrai faixa de legenda de MKV para SRT
# Uso: .\utils\mkv-extract-subtitles.ps1 -File "video.mkv" [-Track 0]
# Requer: MKVToolNix (winget install MKVToolNix.MKVToolNix)
# ==============================================================================

param(
    [Parameter(Mandatory)][string]$File,
    [int]$Track = 0,
    [switch]$DryRun
)

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")

$isDry = $DryRun -or $global:DRY_RUN

if (-not (Test-Path $File)) { Die "Arquivo não encontrado: $File" }

$mkvextract = Get-Command mkvextract -ErrorAction SilentlyContinue
if (-not $mkvextract) { Die "mkvextract não encontrado. Instale MKVToolNix: winget install MKVToolNix.MKVToolNix" }

$baseName = [System.IO.Path]::GetFileNameWithoutExtension($File)
$dir      = [System.IO.Path]::GetDirectoryName((Resolve-Path $File))
$output   = Join-Path $dir "$baseName.srt"

Log-Step "Extraindo legenda da faixa $Track de: $([System.IO.Path]::GetFileName($File))"
Log-Info "Saída: $output"

if ($isDry) {
    Log-Info "[DRY-RUN] mkvextract tracks `"$File`" ${Track}:`"$output`""
    exit 0
}

& mkvextract tracks $File "${Track}:${output}"

if ($LASTEXITCODE -eq 0 -and (Test-Path $output)) {
    Log-Success "Legenda extraída: $output"
} else {
    Die "Falha ao extrair legenda (exit $LASTEXITCODE). Verifique o número da faixa com: mkvinfo `"$File`""
}
