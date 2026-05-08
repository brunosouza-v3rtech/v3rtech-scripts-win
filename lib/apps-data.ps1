#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/apps-data.ps1
# Versão: 1.0.0
# Objetivo: Banco de dados centralizado de aplicativos
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

$global:APP_MAP           = [ordered]@{}
$global:APP_NAMES_ORDERED = [System.Collections.Generic.List[string]]::new()

function Add-App {
    param(
        [bool]  $Active,
        [string]$Category,
        [string]$Name,
        [string]$Desc,
        [string]$WingetId = "",
        [string]$ChocoId  = "",
        [string]$ScoopId  = "",
        [string]$Method   = "winget"
    )

    $global:APP_MAP[$Name] = @{
        Active    = $Active
        Category  = $Category
        Name      = $Name
        Desc      = $Desc
        WingetId  = $WingetId
        ChocoId   = $ChocoId
        ScoopId   = $ScoopId
        Method    = $Method
    }
    $global:APP_NAMES_ORDERED.Add($Name)
}

function Get-AppsByCategory {
    param([string]$Category)
    return @(
        $global:APP_NAMES_ORDERED |
            Where-Object { $global:APP_MAP[$_].Category -eq $Category -and $global:APP_MAP[$_].Active }
    )
}

# =============================================================================
# INTERNET
# =============================================================================
Add-App -Active $true  -Category "internet" -Name "Google Chrome"   -Desc "Navegador Google Chrome"     -WingetId "Google.Chrome"                      -ChocoId "googlechrome"               -Method "winget"
Add-App -Active $true  -Category "internet" -Name "Mozilla Firefox"  -Desc "Navegador Mozilla Firefox"   -WingetId "Mozilla.Firefox"                    -ChocoId "firefox"                    -Method "winget"
Add-App -Active $true  -Category "internet" -Name "Brave Browser"    -Desc "Navegador Brave"              -WingetId "Brave.Brave"                        -ChocoId "brave"                      -Method "winget"
Add-App -Active $true  -Category "internet" -Name "Telegram"         -Desc "Mensageiro Telegram"          -WingetId "Telegram.TelegramDesktop"           -ChocoId "telegram"                   -Method "winget"
Add-App -Active $true  -Category "internet" -Name "Discord"          -Desc "Comunicação Discord"          -WingetId "Discord.Discord"                   -ChocoId "discord"                    -Method "winget"
Add-App -Active $true  -Category "internet" -Name "Zoom"             -Desc "Videoconferência Zoom"        -WingetId "Zoom.Zoom"                          -ChocoId "zoom"                       -Method "winget"

# =============================================================================
# DEV
# =============================================================================
Add-App -Active $true  -Category "dev"      -Name "VS Code"          -Desc "Editor Visual Studio Code"   -WingetId "Microsoft.VisualStudioCode"         -ChocoId "vscode"                     -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Git"              -Desc "Controle de versão Git"       -WingetId "Git.Git"                           -ChocoId "git"                        -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Node.js"          -Desc "Runtime Node.js LTS"          -WingetId "OpenJS.NodeJS.LTS"                 -ChocoId "nodejs-lts"                 -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Python"           -Desc "Python 3"                     -WingetId "Python.Python.3"                   -ChocoId "python3"                    -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Docker Desktop"   -Desc "Docker Desktop para Windows"  -WingetId "Docker.DockerDesktop"              -ChocoId "docker-desktop"             -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Windows Terminal" -Desc "Terminal moderno do Windows"  -WingetId "Microsoft.WindowsTerminal"         -ChocoId "microsoft-windows-terminal"  -Method "winget"
