#!/usr/bin/env pwsh
# ==============================================================================
# Script: core/logging.ps1
# Versão: 1.0.0
# Data: 2026-05-08
# Objetivo: Logging colorizado para terminal e arquivo
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

function Write-Log {
    param(
        [string]$Level,
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Level] $Message" -ForegroundColor $Color
    if ($global:LOG_FILE) {
        Add-Content -Path $global:LOG_FILE -Value "[$timestamp] [$Level] $Message" -Encoding UTF8
    }
}

function Log-Step    { param([string]$M) Write-Log "STEP"    $M Cyan    }
function Log-Info    { param([string]$M) Write-Log "INFO"    $M White   }
function Log-Warn    { param([string]$M) Write-Log "WARN"    $M Yellow  }
function Log-Error   { param([string]$M) Write-Log "ERROR"   $M Red     }
function Log-Success { param([string]$M) Write-Log "SUCCESS" $M Green   }
function Log-Debug   {
    param([string]$M)
    if ($global:VERBOSE_MODE) { Write-Log "DEBUG" $M Gray }
}

function Die {
    param([string]$Message)
    Log-Error $Message
    throw $Message
}
