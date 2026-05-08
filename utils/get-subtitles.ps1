#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/get-subtitles.ps1
# Versão: 1.2.0
# Data: 2026-05-08
# Objetivo: Baixa legendas para vídeos com FileBot suball
# Uso: .\utils\get-subtitles.ps1 -Path "C:\Videos" [-Lang "pt,en"]
# Requer: FileBot com licença
# ==============================================================================

param(
    [Parameter(Mandatory)][string]$Path,
    [string]$Lang = "pt,en",
    [switch]$DryRun
)

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")

$isDry = $DryRun -or $global:DRY_RUN

if (-not (Test-Path $Path)) { Die "Caminho não encontrado: $Path" }

$filebot = Get-Command filebot -ErrorAction SilentlyContinue
if (-not $filebot) { Die "FileBot não encontrado. Instale de: https://www.filebot.net/" }

$langs    = $Lang -split "," | ForEach-Object { $_.Trim() }
$langArgs = $langs | ForEach-Object { @("-lang", $_) }

Log-Step "Baixando legendas ($Lang) para: $Path"

$filebotArgs = @("-script", "fn:suball", $Path, "--encoding", "UTF-8") + $langArgs

if ($isDry) {
    Log-Info "[DRY-RUN] filebot $($filebotArgs -join ' ')"
    exit 0
}

& filebot @filebotArgs

if ($LASTEXITCODE -eq 0) {
    Log-Success "Legendas baixadas com sucesso."
} else {
    Log-Warn "FileBot concluiu com exit $LASTEXITCODE. Verifique se há vídeos sem legenda disponível."
}
