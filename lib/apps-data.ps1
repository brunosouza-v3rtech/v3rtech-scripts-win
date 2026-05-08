#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/apps-data.ps1
# Versão: 1.2.0
# Objetivo: Banco de dados centralizado de aplicativos
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

if (-not $global:APP_MAP -or $global:APP_MAP.Count -eq 0) {
    $global:APP_MAP           = [ordered]@{}
    $global:APP_NAMES_ORDERED = [System.Collections.Generic.List[string]]::new()
}

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
Add-App -Active $true  -Category "internet" -Name "WhatsApp"        -Desc "Mensageiro WhatsApp"           -WingetId "9NKSQGP7F2NH"                -ChocoId "whatsapp"    -Method "winget"
Add-App -Active $true  -Category "internet" -Name "qBittorrent"    -Desc "Cliente torrent qBittorrent"  -WingetId "qBittorrent.qBittorrent"     -ChocoId "qbittorrent" -Method "winget"
Add-App -Active $false -Category "internet" -Name "Stremio"        -Desc "Streaming Stremio"            -WingetId "Stremio.Stremio"             -ChocoId "stremio"     -Method "winget"
Add-App -Active $true  -Category "internet" -Name "Wavebox"        -Desc "Navegador produtivo Wavebox"  -WingetId "Wavebox.Wavebox"             -ChocoId "wavebox"     -Method "winget"
Add-App -Active $true  -Category "internet" -Name "Commet Browser" -Desc "Navegador Commet"             -WingetId "Cometbrowser.Cometbrowser"   -ChocoId ""            -Method "winget"
Add-App -Active $true  -Category "internet" -Name "Zen Browser"    -Desc "Navegador Zen (Mozilla)"      -WingetId "Zen-Team.Zen-Browser"        -ChocoId ""            -Method "winget"

# =============================================================================
# DEV
# =============================================================================
Add-App -Active $true  -Category "dev"      -Name "VS Code"          -Desc "Editor Visual Studio Code"   -WingetId "Microsoft.VisualStudioCode"         -ChocoId "vscode"                     -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Git"              -Desc "Controle de versão Git"       -WingetId "Git.Git"                           -ChocoId "git"                        -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Node.js"          -Desc "Runtime Node.js LTS"          -WingetId "OpenJS.NodeJS.LTS"                 -ChocoId "nodejs-lts"                 -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Python"           -Desc "Python 3"                     -WingetId "Python.Python.3"                   -ChocoId "python3"                    -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Docker Desktop"   -Desc "Docker Desktop para Windows"  -WingetId "Docker.DockerDesktop"              -ChocoId "docker-desktop"              -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Windows Terminal" -Desc "Terminal moderno do Windows"  -WingetId "Microsoft.WindowsTerminal"         -ChocoId "microsoft-windows-terminal"  -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Antigravity"      -Desc "IDE com IA do Google"         -WingetId "Google.Antigravity"                -ChocoId ""                            -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Kiro"             -Desc "IDE com IA da AWS"            -WingetId "Amazon.Kiro"                       -ChocoId ""                            -Method "winget"

# =============================================================================
# OFFICE
# =============================================================================
Add-App -Active $true  -Category "office"      -Name "LibreOffice"            -Desc "Suite de escritório LibreOffice"          -WingetId "TheDocumentFoundation.LibreOffice"     -ChocoId "libreoffice"                  -Method "winget"
Add-App -Active $true  -Category "office"      -Name "Notion"                 -Desc "Workspace Notion"                         -WingetId "Notion.Notion"                         -ChocoId "notion"                       -Method "winget"
Add-App -Active $false -Category "office"      -Name "PDF24 Creator"          -Desc "Ferramenta PDF gratuita"                  -WingetId "geek-soft.PDF24"                       -ChocoId "pdf24"                        -Method "winget"
Add-App -Active $false -Category "office"      -Name "OnlyOffice"             -Desc "Suite OnlyOffice Desktop"                 -WingetId "ONLYOFFICE.DesktopEditors"             -ChocoId "onlyoffice-desktopeditors"    -Method "winget"
Add-App -Active $true  -Category "office"      -Name "Adobe Acrobat Reader"   -Desc "Leitor PDF Adobe"                         -WingetId "Adobe.Acrobat.Reader.64-bit"           -ChocoId "adobereader"                  -Method "winget"
Add-App -Active $true  -Category "office"      -Name "Sejda PDF"              -Desc "Editor PDF Sejda"                         -WingetId "Sejda.SejdaPDF"                        -ChocoId "sejda-pdf"                    -Method "winget"
Add-App -Active $true  -Category "office"      -Name "Calibre"                -Desc "Gerenciador de e-books Calibre"           -WingetId "calibre.calibre"                       -ChocoId "calibre"                      -Method "winget"

# =============================================================================
# MULTIMEDIA
# =============================================================================
Add-App -Active $true  -Category "multimedia"  -Name "VLC"                    -Desc "Player de mídia VLC"                      -WingetId "VideoLAN.VLC"                          -ChocoId "vlc"                          -Method "winget"
Add-App -Active $false -Category "multimedia"  -Name "Spotify"                -Desc "Streaming de música Spotify"              -WingetId "Spotify.Spotify"                       -ChocoId "spotify"                      -Method "winget"
Add-App -Active $true  -Category "multimedia"  -Name "OBS Studio"             -Desc "Gravação e streaming OBS"                 -WingetId "OBSProject.OBSStudio"                  -ChocoId "obs-studio"                   -Method "winget"
Add-App -Active $true  -Category "multimedia"  -Name "Audacity"               -Desc "Editor de áudio Audacity"                 -WingetId "Audacity.Audacity"                     -ChocoId "audacity"                     -Method "winget"
Add-App -Active $true  -Category "multimedia"  -Name "HandBrake"              -Desc "Conversor de vídeo HandBrake"             -WingetId "HandBrake.HandBrake"                   -ChocoId "handbrake"                    -Method "winget"
Add-App -Active $false -Category "multimedia"  -Name "MPC-HC"                 -Desc "Media Player Classic Home Cinema"         -WingetId "clsid2.mpc-hc"                         -ChocoId "mpc-hc"                       -Method "winget"
Add-App -Active $true  -Category "multimedia"  -Name "FileBot"                -Desc "Organizador de arquivos de mídia"         -WingetId "PointPlanete.FileBot"                  -ChocoId "filebot"                      -Method "winget"
Add-App -Active $true  -Category "multimedia"  -Name "MKVToolNix"             -Desc "Ferramentas para arquivos MKV"            -WingetId "MKVToolNix.MKVToolNix"                 -ChocoId "mkvtoolnix"                   -Method "winget"
Add-App -Active $true  -Category "multimedia"  -Name "Subtitle Edit"          -Desc "Editor de legendas Subtitle Edit"         -WingetId "Nikse.SubtitleEdit"                    -ChocoId "subtitleedit"                 -Method "winget"

# =============================================================================
# DESIGN
# =============================================================================
Add-App -Active $false -Category "design"      -Name "Figma"                  -Desc "Design colaborativo Figma"                -WingetId "Figma.Figma"                           -ChocoId "figma"                        -Method "winget"
Add-App -Active $true  -Category "design"      -Name "Scribus"                -Desc "Diagramação profissional Scribus"          -WingetId "Scribus.Scribus"                       -ChocoId "scribus"                      -Method "winget"
Add-App -Active $true  -Category "design"      -Name "GIMP"                   -Desc "Editor de imagens GIMP"                   -WingetId "GIMP.GIMP"                             -ChocoId "gimp"                         -Method "winget"
Add-App -Active $true  -Category "design"      -Name "Inkscape"               -Desc "Editor vetorial Inkscape"                 -WingetId "Inkscape.Inkscape"                     -ChocoId "inkscape"                     -Method "winget"
Add-App -Active $true  -Category "design"      -Name "Blender"                -Desc "Modelagem 3D Blender"                     -WingetId "BlenderFoundation.Blender"             -ChocoId "blender"                      -Method "winget"
Add-App -Active $true  -Category "design"      -Name "Krita"                  -Desc "Pintura digital Krita"                    -WingetId "KDE.Krita"                             -ChocoId "krita"                        -Method "winget"
Add-App -Active $true  -Category "design"      -Name "Canva"                  -Desc "Design gráfico Canva (desktop)"           -WingetId "Canva.Canva"                           -ChocoId ""                             -Method "winget"

# =============================================================================
# SYSTEM
# =============================================================================
Add-App -Active $true  -Category "system"      -Name "7-Zip"                  -Desc "Compactador de arquivos 7-Zip"            -WingetId "7zip.7zip"                             -ChocoId "7zip"                         -Method "winget"
Add-App -Active $true  -Category "system"      -Name "Everything"             -Desc "Busca instantânea de arquivos"            -WingetId "voidtools.Everything"                  -ChocoId "everything"                   -Method "winget"
Add-App -Active $true  -Category "system"      -Name "PowerToys"              -Desc "Utilitários Microsoft PowerToys"          -WingetId "Microsoft.PowerToys"                   -ChocoId "powertoys"                    -Method "winget"
Add-App -Active $true  -Category "system"      -Name "Ventoy"                 -Desc "Criador de USB bootável Ventoy"           -WingetId "Ventoy.Ventoy"                         -ChocoId "ventoy"                       -Method "winget"
Add-App -Active $true  -Category "system"      -Name "CrystalDiskInfo"        -Desc "Monitor de saúde de disco"                -WingetId "CrystalDewWorld.CrystalDiskInfo"       -ChocoId "crystaldiskinfo"              -Method "winget"
Add-App -Active $true  -Category "system"      -Name "HWiNFO"                 -Desc "Informações de hardware HWiNFO"           -WingetId "REALiX.HWiNFO"                         -ChocoId "hwinfo"                       -Method "winget"
Add-App -Active $true  -Category "system"      -Name "SyncThing"              -Desc "Sincronização de arquivos SyncThing"      -WingetId "Syncthing.Syncthing"                   -ChocoId "syncthing"                    -Method "winget"
Add-App -Active $true  -Category "system"      -Name "VirtualBox"             -Desc "Virtualização Oracle VirtualBox"          -WingetId "Oracle.VirtualBox"                     -ChocoId "virtualbox"                   -Method "winget"
Add-App -Active $false -Category "system"      -Name "PuTTY"                  -Desc "Cliente SSH/Telnet PuTTY"                 -WingetId "PuTTY.PuTTY"                           -ChocoId "putty"                        -Method "winget"
Add-App -Active $true  -Category "system"      -Name "WinSCP"                 -Desc "Cliente SFTP/FTP WinSCP"                  -WingetId "WinSCP.WinSCP"                         -ChocoId "winscp"                       -Method "winget"
Add-App -Active $false -Category "system"      -Name "KeePassXC"              -Desc "Gerenciador de senhas KeePassXC"          -WingetId "KeePassXCTeam.KeePassXC"               -ChocoId "keepassxc"                    -Method "winget"
Add-App -Active $true  -Category "system"      -Name "Bitwarden"              -Desc "Gerenciador de senhas Bitwarden"          -WingetId "Bitwarden.Bitwarden"                   -ChocoId "bitwarden"                    -Method "winget"
Add-App -Active $false -Category "system"      -Name "AutoHotkey"             -Desc "Automação de teclado/mouse AutoHotkey"   -WingetId "AutoHotkey.AutoHotkey"                 -ChocoId "autohotkey"                   -Method "winget"
Add-App -Active $false -Category "system"      -Name "WizTree"                -Desc "Análise de uso de disco WizTree"          -WingetId "AntibodySoftware.WizTree"              -ChocoId "wiztree"                      -Method "winget"
Add-App -Active $false -Category "system"      -Name "Recuva"                 -Desc "Recuperação de arquivos Recuva"           -WingetId "Piriform.Recuva"                       -ChocoId "recuva"                       -Method "winget"
Add-App -Active $true  -Category "system"      -Name "SyncBackPro"            -Desc "Backup e sincronização SyncBackPro"       -WingetId "2BrightSparks.SyncBackPro"             -ChocoId "syncbackpro"                  -Method "winget"

# =============================================================================
# IA
# =============================================================================
Add-App -Active $true  -Category "ia"         -Name "Claude Desktop"  -Desc "App desktop do Claude (Anthropic)"     -WingetId "Anthropic.Claude"          -ChocoId ""               -Method "winget"
Add-App -Active $true  -Category "ia"         -Name "Claude Code"     -Desc "CLI de IA para desenvolvimento"        -WingetId "Anthropic.ClaudeCode"      -ChocoId ""               -Method "winget"
Add-App -Active $true  -Category "ia"         -Name "Open Design"     -Desc "Ferramenta de design com IA"           -WingetId "OpenDesign.OpenDesign"     -ChocoId ""               -Method "winget"
Add-App -Active $true  -Category "ia"         -Name "Whisper"         -Desc "Transcrição de áudio OpenAI Whisper"   -WingetId "Const-me.Whisper"          -ChocoId ""               -Method "winget"
Add-App -Active $true  -Category "ia"         -Name "Codex"           -Desc "CLI de codificação OpenAI Codex"       -WingetId "OpenAI.Codex"              -ChocoId ""               -Method "winget"

# =============================================================================
# GAMES
# =============================================================================
Add-App -Active $true  -Category "games"       -Name "Steam"                  -Desc "Plataforma Steam"                         -WingetId "Valve.Steam"                           -ChocoId "steam"                        -Method "winget"
Add-App -Active $true  -Category "games"       -Name "Epic Games Launcher"    -Desc "Launcher Epic Games"                      -WingetId "EpicGames.EpicGamesLauncher"           -ChocoId "epicgameslauncher"            -Method "winget"
Add-App -Active $true  -Category "games"       -Name "GOG Galaxy"             -Desc "Plataforma GOG Galaxy"                    -WingetId "GOG.Galaxy"                            -ChocoId "goggalaxy"                    -Method "winget"
Add-App -Active $true  -Category "games"       -Name "Battle.net"             -Desc "Launcher Blizzard Battle.net"             -WingetId "Blizzard.BattleNet"                    -ChocoId "battle.net"                   -Method "winget"
