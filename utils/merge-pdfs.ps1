#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/merge-pdfs.ps1
# Versão: 1.2.0
# Data: 2026-05-08
# Objetivo: Mescla todos os PDFs de uma pasta em um único arquivo
# Uso: .\utils\merge-pdfs.ps1 -Path "C:\Docs" -Output "merged.pdf"
# Requer: pdftk (choco install pdftk)
# ==============================================================================

param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Output,
    [switch]$DryRun
)

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")

$isDry = $DryRun -or $global:DRY_RUN

if (-not (Test-Path $Path)) { Die "Pasta não encontrada: $Path" }

$pdftk = Get-Command pdftk -ErrorAction SilentlyContinue
if (-not $pdftk) { Die "pdftk não encontrado. Instale com: choco install pdftk" }

$pdfs = Get-ChildItem -Path $Path -Filter "*.pdf" | Sort-Object Name

if ($pdfs.Count -eq 0) { Die "Nenhum PDF encontrado em: $Path" }

$outputPath = if ([System.IO.Path]::IsPathRooted($Output)) {
    $Output
} else {
    Join-Path $Path $Output
}

Log-Step "Mesclando $($pdfs.Count) PDFs → $([System.IO.Path]::GetFileName($outputPath))"
$pdfs | ForEach-Object { Log-Info "  + $($_.Name)" }

if ($isDry) {
    $list = ($pdfs | ForEach-Object { "`"$($_.FullName)`"" }) -join " "
    Log-Info "[DRY-RUN] pdftk $list cat output `"$outputPath`""
    exit 0
}

$pdftkArgs = ($pdfs | ForEach-Object { $_.FullName }) + @("cat", "output", $outputPath)
& pdftk @pdftkArgs

if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
    Log-Success "PDF mesclado: $outputPath"
} else {
    Die "Falha ao mesclar PDFs (exit $LASTEXITCODE)."
}
