#!/usr/bin/env pwsh
# ==============================================================================
# Script: tests/Run-Tests.ps1
# Versão: 1.0.0
# Objetivo: Runner central de testes — equivalente a `npm test`
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Uso: pwsh -NonInteractive -Command "& './tests/Run-Tests.ps1'"
# ==============================================================================

$env:DRY_RUN = "1"
$env:VERBOSE  = "0"

$config = New-PesterConfiguration
$config.Run.Path          = $PSScriptRoot
$config.Output.Verbosity  = "Detailed"
$config.TestResult.Enabled       = $true
$config.TestResult.OutputPath    = (Join-Path $PSScriptRoot "TestResults.xml")
$config.TestResult.OutputFormat  = "NUnitXml"

$result = Invoke-Pester -Configuration $config

if ($result.FailedCount -gt 0) {
    Write-Host "FALHOU: $($result.FailedCount) teste(s) falharam." -ForegroundColor Red
    exit 1
}
Write-Host "OK: $($result.PassedCount) testes passaram." -ForegroundColor Green
