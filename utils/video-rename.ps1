#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/video-rename.ps1
# Versão: 1.2.0
# Data: 2026-05-08
# Objetivo: Renomeia vídeos com FileBot (filmes, séries, anime, documentários)
# Uso: .\utils\video-rename.ps1 -Path "C:\Videos" -Type movies
#      Tipos: movies | series | anime | documentary | kids
# Requer: FileBot com licença (filebot.net)
# ==============================================================================

param(
    [Parameter(Mandatory)][string]$Path,
    [ValidateSet("movies","series","anime","documentary","kids")]
    [string]$Type = "movies",
    [string]$Language = "pt",
    [switch]$DryRun
)

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")

$isDry = $DryRun -or $global:DRY_RUN

if (-not (Test-Path $Path)) { Die "Caminho não encontrado: $Path" }

$filebot = Get-Command filebot -ErrorAction SilentlyContinue
if (-not $filebot) { Die "FileBot não encontrado. Instale de: https://www.filebot.net/" }

$config = @{
    movies      = @{ DB = "TheMovieDB"; Format = "{n} ({y})\{n} ({y}) [{vf}]"; Label = "Filmes" }
    series      = @{ DB = "TheTVDB";    Format = "{n}\Season {s.pad(2)}\{n}.s{s.pad(2)}e{e.pad(2)}.{t}.[{airdate}]"; Label = "Séries" }
    anime       = @{ DB = "TheMovieDB"; Format = "{n} ({y})\{n} ({y}) [{vf}]"; Label = "Anime" }
    documentary = @{ DB = "TheMovieDB"; Format = "{n} ({y})\{n} ({y}) [{vf}]"; Label = "Documentários" }
    kids        = @{ DB = "TheMovieDB"; Format = "{n} ({y})\{n} ({y}) [{vf}]"; Label = "Infantil" }
}

$cfg = $config[$Type]

Log-Step "Renomeando $($cfg.Label) em: $Path"
Log-Info "Banco de dados: $($cfg.DB) | Formato: $($cfg.Format)"

$filebotArgs = @(
    "-rename", $Path,
    "--db", $cfg.DB,
    "--format", $cfg.Format,
    "--lang", $Language,
    "-non-strict",
    "--conflict", "skip"
)
if ($isDry) { $filebotArgs += "--action", "test" }

Log-Info "filebot $($filebotArgs -join ' ')"

& filebot @filebotArgs

if ($LASTEXITCODE -eq 0) {
    Log-Success "Renomeação concluída."

    $srts = Get-ChildItem -Path $Path -Filter "*.srt" -Recurse |
            Where-Object { $_.Name -notmatch '\.pt-br\.srt$' }

    if ($srts.Count -gt 0) {
        Log-Info "Renomeando $($srts.Count) legenda(s) para .pt-br.srt"
        foreach ($srt in $srts) {
            $newName = $srt.BaseName + ".pt-br.srt"
            if ($isDry) {
                Log-Info "[DRY-RUN] Rename: $($srt.Name) → $newName"
            } else {
                Rename-Item -Path $srt.FullName -NewName $newName
            }
        }
    }
} else {
    Log-Warn "FileBot concluiu com exit $LASTEXITCODE. Verifique a saída acima."
}
