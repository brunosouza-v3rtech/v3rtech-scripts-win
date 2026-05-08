#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/transmission-clear.ps1
# Versão: 1.2.0
# Data: 2026-05-08
# Objetivo: Remove torrents concluídos/inativos do Transmission
# Uso: .\utils\transmission-clear.ps1 [-Server 192.168.0.12] [-Port 9091]
# Requer: transmission-remote no PATH
# ==============================================================================

param(
    [string]$Server = "192.168.0.12",
    [int]   $Port   = 9091,
    [string]$User   = "",
    [string]$Pass   = "",
    [switch]$DryRun
)

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")

$isDry = $DryRun -or $global:DRY_RUN

$trRemote = Get-Command transmission-remote -ErrorAction SilentlyContinue
if (-not $trRemote) { Die "transmission-remote não encontrado. Instale Transmission ou adicione ao PATH." }

$endpoint = "${Server}:${Port}"
$authArgs  = if ($User -and $Pass) { @("--auth", "${User}:${Pass}") } else { @() }

$clearStatuses = @("Finished", "Seeding", "Idle")

Log-Step "Conectando ao Transmission em $endpoint"

$listOutput = & transmission-remote $endpoint @authArgs --list 2>&1
if ($LASTEXITCODE -ne 0) { Die "Falha ao conectar ao Transmission em $endpoint" }

$removed = 0; $skipped = 0

foreach ($line in ($listOutput -split "`n")) {
    $line = $line.Trim()
    if ($line -match "^(\d+)\s+.*?\s+(\w+)\s") {
        $torrentId     = $Matches[1]
        $torrentStatus = $Matches[2]

        if ($clearStatuses -contains $torrentStatus) {
            Log-Info "Removendo torrent ID $torrentId (status: $torrentStatus)"
            if ($isDry) {
                Log-Info "[DRY-RUN] transmission-remote $endpoint --torrent $torrentId --remove"
                $removed++
            } else {
                & transmission-remote $endpoint @authArgs --torrent $torrentId --remove 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) { $removed++ }
                else { Log-Warn "Falha ao remover torrent $torrentId"; $skipped++ }
            }
        } else {
            $skipped++
        }
    }
}

Log-Success "Transmission: $removed torrent(s) removidos, $skipped mantidos."
