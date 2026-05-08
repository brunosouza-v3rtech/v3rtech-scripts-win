# v3rtech-scripts-win — Plano 2: App Categories & Full Wizard

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar as 6 categorias restantes de apps (dev, office, multimedia, design, system, games), 14 apps extras migrados dos scripts antigos, os 2 perfis faltantes (criador-conteudo, domestico), e atualizar o wizard com menu completo de categorias e submenus.

**Architecture:** Cada `lib/install-apps-CATEGORIA.ps1` é standalone e segue o mesmo padrão de `install-apps-internet.ps1`. `apps-data.ps1` recebe os novos apps. O wizard `v3rtech-install.ps1` ganha submenu de categorias com opção de instalar individualmente ou por perfil. Testes validam os dados de cada categoria num arquivo combinado.

**Tech Stack:** PowerShell 7+, Pester 5.x, winget (primário), chocolatey (fallback).

---

## Mapa de Arquivos

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `lib/apps-data.ps1` | Modificar | Adicionar apps: office, multimedia, design, system, games + 14 apps extras |
| `lib/install-apps-dev.ps1` | Criar | Categoria dev standalone |
| `lib/install-apps-office.ps1` | Criar | Categoria office standalone |
| `lib/install-apps-multimedia.ps1` | Criar | Categoria multimedia standalone |
| `lib/install-apps-design.ps1` | Criar | Categoria design standalone |
| `lib/install-apps-system.ps1` | Criar | Categoria system standalone |
| `lib/install-apps-games.ps1` | Criar | Categoria games standalone |
| `tests/lib/install-apps-categories.Tests.ps1` | Criar | Testes de dados de todas as categorias |
| `profiles/criador-conteudo.json` | Criar | Perfil criador de conteúdo |
| `profiles/domestico.json` | Criar | Perfil doméstico |
| `v3rtech-install.ps1` | Modificar | Wizard completo com submenu de categorias |
| `CHANGELOG.md` | Modificar | Entrada v1.1.0 |

---

## Task 1: Expandir `apps-data.ps1` com 5 categorias

**Files:**
- Modify: `lib/apps-data.ps1`

- [ ] **Step 1: Escrever o teste antes de modificar**

Arquivo `tests/lib/install-apps-categories.Tests.ps1`:

```powershell
BeforeAll {
    $env:DRY_RUN = "1"
    $script:root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:root "core" "env.ps1")
    . (Join-Path $script:root "core" "logging.ps1")
    . (Join-Path $script:root "core" "package-mgr.ps1")
    $global:APP_MAP           = $null
    $global:APP_NAMES_ORDERED = $null
    . (Join-Path $script:root "lib" "apps-data.ps1")
}

Describe "Categoria dev" {
    It "tem apps registrados" {
        (Get-AppsByCategory "dev").Count | Should -BeGreaterThan 0
    }
    It "todos têm WingetId preenchido" {
        Get-AppsByCategory "dev" | ForEach-Object {
            $global:APP_MAP[$_].WingetId | Should -Not -BeNullOrEmpty
        }
    }
    It "primeiro app é VS Code" {
        (Get-AppsByCategory "dev")[0] | Should -Be "VS Code"
    }
}

Describe "Categoria office" {
    It "tem apps registrados" {
        (Get-AppsByCategory "office").Count | Should -BeGreaterThan 0
    }
    It "todos têm WingetId preenchido" {
        Get-AppsByCategory "office" | ForEach-Object {
            $global:APP_MAP[$_].WingetId | Should -Not -BeNullOrEmpty
        }
    }
    It "primeiro app é LibreOffice" {
        (Get-AppsByCategory "office")[0] | Should -Be "LibreOffice"
    }
}

Describe "Categoria multimedia" {
    It "tem apps registrados" {
        (Get-AppsByCategory "multimedia").Count | Should -BeGreaterThan 0
    }
    It "todos têm WingetId preenchido" {
        Get-AppsByCategory "multimedia" | ForEach-Object {
            $global:APP_MAP[$_].WingetId | Should -Not -BeNullOrEmpty
        }
    }
    It "primeiro app é VLC" {
        (Get-AppsByCategory "multimedia")[0] | Should -Be "VLC"
    }
}

Describe "Categoria design" {
    It "tem apps registrados" {
        (Get-AppsByCategory "design").Count | Should -BeGreaterThan 0
    }
    It "todos têm WingetId preenchido" {
        Get-AppsByCategory "design" | ForEach-Object {
            $global:APP_MAP[$_].WingetId | Should -Not -BeNullOrEmpty
        }
    }
    It "primeiro app é Figma" {
        (Get-AppsByCategory "design")[0] | Should -Be "Figma"
    }
}

Describe "Categoria system" {
    It "tem apps registrados" {
        (Get-AppsByCategory "system").Count | Should -BeGreaterThan 0
    }
    It "todos têm WingetId preenchido" {
        Get-AppsByCategory "system" | ForEach-Object {
            $global:APP_MAP[$_].WingetId | Should -Not -BeNullOrEmpty
        }
    }
    It "primeiro app é 7-Zip" {
        (Get-AppsByCategory "system")[0] | Should -Be "7-Zip"
    }
}

Describe "Categoria games" {
    It "tem apps registrados" {
        (Get-AppsByCategory "games").Count | Should -BeGreaterThan 0
    }
    It "todos têm WingetId preenchido" {
        Get-AppsByCategory "games" | ForEach-Object {
            $global:APP_MAP[$_].WingetId | Should -Not -BeNullOrEmpty
        }
    }
    It "primeiro app é Steam" {
        (Get-AppsByCategory "games")[0] | Should -Be "Steam"
    }
}

Describe "APP_MAP total" {
    It "tem pelo menos 50 apps registrados" {
        $global:APP_MAP.Count | Should -BeGreaterOrEqual 50
    }
    It "nenhum app com WingetId definido tem valor vazio" {
        foreach ($name in $global:APP_MAP.Keys) {
            $app = $global:APP_MAP[$name]
            if ($app.Method -eq "winget") {
                $app.WingetId | Should -Not -BeNullOrEmpty -Because "$name usa winget mas tem WingetId vazio"
            }
        }
    }
}
```

- [ ] **Step 2: Rodar o teste — confirmar falha**

```powershell
Invoke-Pester -Path tests/lib/install-apps-categories.Tests.ps1 -Output Detailed
```

Resultado esperado: `Failed: 18` — categorias office/multimedia/design/system/games não têm apps ainda.

- [ ] **Step 3: Adicionar os apps em `lib/apps-data.ps1`**

Localizar o bloco `# INTERNET` existente e adicionar 3 apps ao final dele (antes do bloco `# DEV`):

```powershell
Add-App -Active $true  -Category "internet"    -Name "WhatsApp"               -Desc "WhatsApp Desktop"                         -WingetId "9NKSQGP7F2NH"                          -ChocoId "whatsapp"                     -Method "winget"
Add-App -Active $true  -Category "internet"    -Name "qBittorrent"            -Desc "Cliente torrent qBittorrent"              -WingetId "qBittorrent.qBittorrent"               -ChocoId "qbittorrent"                  -Method "winget"
Add-App -Active $true  -Category "internet"    -Name "Stremio"                -Desc "Streaming Stremio"                        -WingetId "Stremio.Stremio"                       -ChocoId "stremio"                      -Method "winget"
```

Localizar o bloco `# DEV` existente (última linha de Add-App) e adicionar após ele:

```powershell
# =============================================================================
# OFFICE
# =============================================================================
Add-App -Active $true  -Category "office"      -Name "LibreOffice"            -Desc "Suite de escritório LibreOffice"          -WingetId "TheDocumentFoundation.LibreOffice"     -ChocoId "libreoffice"                  -Method "winget"
Add-App -Active $true  -Category "office"      -Name "Notion"                 -Desc "Workspace Notion"                         -WingetId "Notion.Notion"                         -ChocoId "notion"                       -Method "winget"
Add-App -Active $true  -Category "office"      -Name "PDF24 Creator"          -Desc "Ferramenta PDF gratuita"                  -WingetId "geek-soft.PDF24"                       -ChocoId "pdf24"                        -Method "winget"
Add-App -Active $true  -Category "office"      -Name "OnlyOffice"             -Desc "Suite OnlyOffice Desktop"                 -WingetId "ONLYOFFICE.DesktopEditors"             -ChocoId "onlyoffice-desktopeditors"    -Method "winget"
Add-App -Active $true  -Category "office"      -Name "Adobe Acrobat Reader"   -Desc "Leitor PDF Adobe"                         -WingetId "Adobe.Acrobat.Reader.64-bit"           -ChocoId "adobereader"                  -Method "winget"
Add-App -Active $true  -Category "office"      -Name "Calibre"                -Desc "Gerenciador de e-books Calibre"           -WingetId "calibre.calibre"                       -ChocoId "calibre"                      -Method "winget"

# =============================================================================
# MULTIMEDIA
# =============================================================================
Add-App -Active $true  -Category "multimedia"  -Name "VLC"                    -Desc "Player de mídia VLC"                      -WingetId "VideoLAN.VLC"                          -ChocoId "vlc"                          -Method "winget"
Add-App -Active $true  -Category "multimedia"  -Name "Spotify"                -Desc "Streaming de música Spotify"              -WingetId "Spotify.Spotify"                       -ChocoId "spotify"                      -Method "winget"
Add-App -Active $true  -Category "multimedia"  -Name "OBS Studio"             -Desc "Gravação e streaming OBS"                 -WingetId "OBSProject.OBSStudio"                  -ChocoId "obs-studio"                   -Method "winget"
Add-App -Active $true  -Category "multimedia"  -Name "Audacity"               -Desc "Editor de áudio Audacity"                 -WingetId "Audacity.Audacity"                     -ChocoId "audacity"                     -Method "winget"
Add-App -Active $true  -Category "multimedia"  -Name "HandBrake"              -Desc "Conversor de vídeo HandBrake"             -WingetId "HandBrake.HandBrake"                   -ChocoId "handbrake"                    -Method "winget"
Add-App -Active $true  -Category "multimedia"  -Name "MPC-HC"                 -Desc "Media Player Classic Home Cinema"         -WingetId "clsid2.mpc-hc"                         -ChocoId "mpc-hc"                       -Method "winget"
Add-App -Active $true  -Category "multimedia"  -Name "MKVToolNix"             -Desc "Ferramentas para arquivos MKV"            -WingetId "MKVToolNix.MKVToolNix"                 -ChocoId "mkvtoolnix"                   -Method "winget"
Add-App -Active $true  -Category "multimedia"  -Name "Subtitle Edit"          -Desc "Editor de legendas Subtitle Edit"         -WingetId "Nikse.SubtitleEdit"                    -ChocoId "subtitleedit"                 -Method "winget"

# =============================================================================
# DESIGN
# =============================================================================
Add-App -Active $true  -Category "design"      -Name "Figma"                  -Desc "Design colaborativo Figma"                -WingetId "Figma.Figma"                           -ChocoId "figma"                        -Method "winget"
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
Add-App -Active $true  -Category "system"      -Name "PuTTY"                  -Desc "Cliente SSH/Telnet PuTTY"                 -WingetId "PuTTY.PuTTY"                           -ChocoId "putty"                        -Method "winget"
Add-App -Active $true  -Category "system"      -Name "WinSCP"                 -Desc "Cliente SFTP/FTP WinSCP"                  -WingetId "WinSCP.WinSCP"                         -ChocoId "winscp"                       -Method "winget"
Add-App -Active $true  -Category "system"      -Name "KeePassXC"              -Desc "Gerenciador de senhas KeePassXC"          -WingetId "KeePassXCTeam.KeePassXC"               -ChocoId "keepassxc"                    -Method "winget"
Add-App -Active $true  -Category "system"      -Name "Bitwarden"              -Desc "Gerenciador de senhas Bitwarden"          -WingetId "Bitwarden.Bitwarden"                   -ChocoId "bitwarden"                    -Method "winget"
Add-App -Active $true  -Category "system"      -Name "AutoHotkey"             -Desc "Automação de teclado/mouse AutoHotkey"   -WingetId "AutoHotkey.AutoHotkey"                 -ChocoId "autohotkey"                   -Method "winget"
Add-App -Active $true  -Category "system"      -Name "WizTree"                -Desc "Análise de uso de disco WizTree"          -WingetId "AntibodySoftware.WizTree"              -ChocoId "wiztree"                      -Method "winget"
Add-App -Active $true  -Category "system"      -Name "Recuva"                 -Desc "Recuperação de arquivos Recuva"           -WingetId "Piriform.Recuva"                       -ChocoId "recuva"                       -Method "winget"

# =============================================================================
# GAMES
# =============================================================================
Add-App -Active $true  -Category "games"       -Name "Steam"                  -Desc "Plataforma Steam"                         -WingetId "Valve.Steam"                           -ChocoId "steam"                        -Method "winget"
Add-App -Active $true  -Category "games"       -Name "Epic Games Launcher"    -Desc "Launcher Epic Games"                      -WingetId "EpicGames.EpicGamesLauncher"           -ChocoId "epicgameslauncher"            -Method "winget"
Add-App -Active $true  -Category "games"       -Name "GOG Galaxy"             -Desc "Plataforma GOG Galaxy"                    -WingetId "GOG.Galaxy"                            -ChocoId "goggalaxy"                    -Method "winget"
Add-App -Active $true  -Category "games"       -Name "Battle.net"             -Desc "Launcher Blizzard Battle.net"             -WingetId "Blizzard.BattleNet"                    -ChocoId "battle.net"                   -Method "winget"
```

- [ ] **Step 4: Rodar o teste — confirmar que passa**

```powershell
Invoke-Pester -Path tests/lib/install-apps-categories.Tests.ps1 -Output Detailed
```

Resultado esperado: `Tests Passed: 24, Failed: 0`

- [ ] **Step 5: Rodar suite completa para confirmar sem regressão**

```powershell
Invoke-Pester -Path tests/ -Output Normal
```

Resultado esperado: `Tests Passed: 68, Failed: 0` (44 anteriores + 24 novos)

- [ ] **Step 6: Commit**

```bash
git add lib/apps-data.ps1 tests/lib/install-apps-categories.Tests.ps1
git commit -m "feat: adiciona categorias office/multimedia/design/system/games ao apps-data"
```

---

## Task 2: `lib/install-apps-dev.ps1`

**Files:**
- Create: `lib/install-apps-dev.ps1`

- [ ] **Step 1: Criar o script**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/install-apps-dev.ps1
# Versão: 1.1.0
# Objetivo: Instalar apps de Desenvolvimento (IDE, linguagens, containers)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# Execução standalone: $env:DRY_RUN=1; .\lib\install-apps-dev.ps1
# ==============================================================================

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")
. (Join-Path $BASE_DIR "core" "package-mgr.ps1")
. (Join-Path $BASE_DIR "lib" "apps-data.ps1")

if ($global:DRY_RUN) { Log-Warn "Modo DRY-RUN ativado — nenhuma instalação será realizada." }

function Install-Apps-Dev {
    Log-Step "Instalando apps de Desenvolvimento..."

    $apps = Get-AppsByCategory -Category "dev"

    if ($apps.Count -eq 0) {
        Log-Warn "Nenhum app ativo na categoria 'dev'."
        return
    }

    $ok = 0; $fail = 0
    foreach ($appName in $apps) {
        if (Install-App -AppName $appName) { $ok++ } else { $fail++ }
    }

    Log-Success "Dev: $ok instalados, $fail falhas."
}

Install-Apps-Dev
```

- [ ] **Step 2: Validar execução standalone em dry-run**

```powershell
$env:DRY_RUN=1; .\lib\install-apps-dev.ps1
```

Resultado esperado: 6 linhas `[DRY-RUN] winget install --id ...` para VS Code, Git, Node.js, Python, Docker Desktop, Windows Terminal. Linha final `[SUCCESS] Dev: 6 instalados, 0 falhas.`

- [ ] **Step 3: Commit**

```bash
git add lib/install-apps-dev.ps1
git commit -m "feat: implementa lib/install-apps-dev.ps1 (standalone, dry-run)"
```

---

## Task 3: `lib/install-apps-office.ps1`

**Files:**
- Create: `lib/install-apps-office.ps1`

- [ ] **Step 1: Criar o script**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/install-apps-office.ps1
# Versão: 1.1.0
# Objetivo: Instalar apps de Escritório (suites, PDF, notes)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# Execução standalone: $env:DRY_RUN=1; .\lib\install-apps-office.ps1
# ==============================================================================

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")
. (Join-Path $BASE_DIR "core" "package-mgr.ps1")
. (Join-Path $BASE_DIR "lib" "apps-data.ps1")

if ($global:DRY_RUN) { Log-Warn "Modo DRY-RUN ativado — nenhuma instalação será realizada." }

function Install-Apps-Office {
    Log-Step "Instalando apps de Escritório..."

    $apps = Get-AppsByCategory -Category "office"

    if ($apps.Count -eq 0) {
        Log-Warn "Nenhum app ativo na categoria 'office'."
        return
    }

    $ok = 0; $fail = 0
    foreach ($appName in $apps) {
        if (Install-App -AppName $appName) { $ok++ } else { $fail++ }
    }

    Log-Success "Office: $ok instalados, $fail falhas."
}

Install-Apps-Office
```

- [ ] **Step 2: Validar execução standalone em dry-run**

```powershell
$env:DRY_RUN=1; .\lib\install-apps-office.ps1
```

Resultado esperado: 6 linhas `[DRY-RUN] winget install ...` para LibreOffice, Notion, PDF24 Creator, OnlyOffice, Adobe Acrobat Reader, Calibre. Linha final `[SUCCESS] Office: 6 instalados, 0 falhas.`

- [ ] **Step 3: Commit**

```bash
git add lib/install-apps-office.ps1
git commit -m "feat: implementa lib/install-apps-office.ps1 (standalone, dry-run)"
```

---

## Task 4: `lib/install-apps-multimedia.ps1`

**Files:**
- Create: `lib/install-apps-multimedia.ps1`

- [ ] **Step 1: Criar o script**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/install-apps-multimedia.ps1
# Versão: 1.1.0
# Objetivo: Instalar apps de Multimídia (players, streaming, gravação)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# Execução standalone: $env:DRY_RUN=1; .\lib\install-apps-multimedia.ps1
# ==============================================================================

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")
. (Join-Path $BASE_DIR "core" "package-mgr.ps1")
. (Join-Path $BASE_DIR "lib" "apps-data.ps1")

if ($global:DRY_RUN) { Log-Warn "Modo DRY-RUN ativado — nenhuma instalação será realizada." }

function Install-Apps-Multimedia {
    Log-Step "Instalando apps de Multimídia..."

    $apps = Get-AppsByCategory -Category "multimedia"

    if ($apps.Count -eq 0) {
        Log-Warn "Nenhum app ativo na categoria 'multimedia'."
        return
    }

    $ok = 0; $fail = 0
    foreach ($appName in $apps) {
        if (Install-App -AppName $appName) { $ok++ } else { $fail++ }
    }

    Log-Success "Multimedia: $ok instalados, $fail falhas."
}

Install-Apps-Multimedia
```

- [ ] **Step 2: Validar execução standalone em dry-run**

```powershell
$env:DRY_RUN=1; .\lib\install-apps-multimedia.ps1
```

Resultado esperado: 6 linhas `[DRY-RUN] winget install ...` para VLC, Spotify, OBS Studio, Audacity, HandBrake, MPC-HC. Linha final `[SUCCESS] Multimedia: 6 instalados, 0 falhas.`

- [ ] **Step 3: Commit**

```bash
git add lib/install-apps-multimedia.ps1
git commit -m "feat: implementa lib/install-apps-multimedia.ps1 (standalone, dry-run)"
```

---

## Task 5: `lib/install-apps-design.ps1`

**Files:**
- Create: `lib/install-apps-design.ps1`

- [ ] **Step 1: Criar o script**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/install-apps-design.ps1
# Versão: 1.1.0
# Objetivo: Instalar apps de Design (vetorial, raster, 3D)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# Execução standalone: $env:DRY_RUN=1; .\lib\install-apps-design.ps1
# ==============================================================================

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")
. (Join-Path $BASE_DIR "core" "package-mgr.ps1")
. (Join-Path $BASE_DIR "lib" "apps-data.ps1")

if ($global:DRY_RUN) { Log-Warn "Modo DRY-RUN ativado — nenhuma instalação será realizada." }

function Install-Apps-Design {
    Log-Step "Instalando apps de Design..."

    $apps = Get-AppsByCategory -Category "design"

    if ($apps.Count -eq 0) {
        Log-Warn "Nenhum app ativo na categoria 'design'."
        return
    }

    $ok = 0; $fail = 0
    foreach ($appName in $apps) {
        if (Install-App -AppName $appName) { $ok++ } else { $fail++ }
    }

    Log-Success "Design: $ok instalados, $fail falhas."
}

Install-Apps-Design
```

- [ ] **Step 2: Validar execução standalone em dry-run**

```powershell
$env:DRY_RUN=1; .\lib\install-apps-design.ps1
```

Resultado esperado: 6 linhas `[DRY-RUN] winget install ...` para Figma, GIMP, Inkscape, Blender, Krita, Canva. Linha final `[SUCCESS] Design: 6 instalados, 0 falhas.`

- [ ] **Step 3: Commit**

```bash
git add lib/install-apps-design.ps1
git commit -m "feat: implementa lib/install-apps-design.ps1 (standalone, dry-run)"
```

---

## Task 6: `lib/install-apps-system.ps1`

**Files:**
- Create: `lib/install-apps-system.ps1`

- [ ] **Step 1: Criar o script**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/install-apps-system.ps1
# Versão: 1.1.0
# Objetivo: Instalar utilitários de sistema (compactador, busca, tweaks)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# Execução standalone: $env:DRY_RUN=1; .\lib\install-apps-system.ps1
# ==============================================================================

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")
. (Join-Path $BASE_DIR "core" "package-mgr.ps1")
. (Join-Path $BASE_DIR "lib" "apps-data.ps1")

if ($global:DRY_RUN) { Log-Warn "Modo DRY-RUN ativado — nenhuma instalação será realizada." }

function Install-Apps-System {
    Log-Step "Instalando utilitários de sistema..."

    $apps = Get-AppsByCategory -Category "system"

    if ($apps.Count -eq 0) {
        Log-Warn "Nenhum app ativo na categoria 'system'."
        return
    }

    $ok = 0; $fail = 0
    foreach ($appName in $apps) {
        if (Install-App -AppName $appName) { $ok++ } else { $fail++ }
    }

    Log-Success "System: $ok instalados, $fail falhas."
}

Install-Apps-System
```

- [ ] **Step 2: Validar execução standalone em dry-run**

```powershell
$env:DRY_RUN=1; .\lib\install-apps-system.ps1
```

Resultado esperado: 6 linhas `[DRY-RUN] winget install ...` para 7-Zip, Everything, PowerToys, Ventoy, CrystalDiskInfo, HWiNFO. Linha final `[SUCCESS] System: 6 instalados, 0 falhas.`

- [ ] **Step 3: Commit**

```bash
git add lib/install-apps-system.ps1
git commit -m "feat: implementa lib/install-apps-system.ps1 (standalone, dry-run)"
```

---

## Task 7: `lib/install-apps-games.ps1`

**Files:**
- Create: `lib/install-apps-games.ps1`

- [ ] **Step 1: Criar o script**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/install-apps-games.ps1
# Versão: 1.1.0
# Objetivo: Instalar launchers e plataformas de games
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# Execução standalone: $env:DRY_RUN=1; .\lib\install-apps-games.ps1
# ==============================================================================

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")
. (Join-Path $BASE_DIR "core" "package-mgr.ps1")
. (Join-Path $BASE_DIR "lib" "apps-data.ps1")

if ($global:DRY_RUN) { Log-Warn "Modo DRY-RUN ativado — nenhuma instalação será realizada." }

function Install-Apps-Games {
    Log-Step "Instalando plataformas de games..."

    $apps = Get-AppsByCategory -Category "games"

    if ($apps.Count -eq 0) {
        Log-Warn "Nenhum app ativo na categoria 'games'."
        return
    }

    $ok = 0; $fail = 0
    foreach ($appName in $apps) {
        if (Install-App -AppName $appName) { $ok++ } else { $fail++ }
    }

    Log-Success "Games: $ok instalados, $fail falhas."
}

Install-Apps-Games
```

- [ ] **Step 2: Validar execução standalone em dry-run**

```powershell
$env:DRY_RUN=1; .\lib\install-apps-games.ps1
```

Resultado esperado: 4 linhas `[DRY-RUN] winget install ...` para Steam, Epic Games Launcher, GOG Galaxy, Battle.net. Linha final `[SUCCESS] Games: 4 instalados, 0 falhas.`

- [ ] **Step 3: Rodar suite completa**

```powershell
Invoke-Pester -Path tests/ -Output Normal
```

Resultado esperado: `Tests Passed: 68, Failed: 0`

- [ ] **Step 4: Commit**

```bash
git add lib/install-apps-games.ps1
git commit -m "feat: implementa lib/install-apps-games.ps1 (standalone, dry-run)"
```

---

## Task 8: Perfis completos

**Files:**
- Create: `profiles/criador-conteudo.json`
- Create: `profiles/domestico.json`

- [ ] **Step 1: Criar `profiles/criador-conteudo.json`**

```json
{
  "name": "criador-conteudo",
  "description": "Setup para criação de conteúdo (vídeo, design, streaming)",
  "categories": ["internet", "multimedia", "design", "system"],
  "apps_extra": ["OBS Studio", "Audacity", "HandBrake"],
  "winfeatures": [],
  "system_tweaks": []
}
```

- [ ] **Step 2: Criar `profiles/domestico.json`**

```json
{
  "name": "domestico",
  "description": "Setup para uso doméstico e entretenimento",
  "categories": ["internet", "multimedia", "games", "system"],
  "apps_extra": [],
  "winfeatures": [],
  "system_tweaks": []
}
```

- [ ] **Step 3: Commit**

```bash
git add profiles/criador-conteudo.json profiles/domestico.json
git commit -m "feat: adiciona perfis criador-conteudo e domestico"
```

---

## Task 9: Wizard completo em `v3rtech-install.ps1`

**Files:**
- Modify: `v3rtech-install.ps1`

O wizard atual tem 3 opções hardcoded (internet, dev, perfil). O novo wizard tem:
- Menu principal: instalar por categoria | instalar por perfil | sair
- Submenu de categorias com todas as 7 categorias + opção "Todas"

- [ ] **Step 1: Substituir `v3rtech-install.ps1` pelo conteúdo completo**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: v3rtech-install.ps1
# Versão: 1.1.0
# Objetivo: Orquestrador principal — wizard CLI de instalação Windows 11
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Website: https://v3rtech.com.br/
# ==============================================================================

$BASE_DIR = Split-Path -Parent $PSCommandPath
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")
. (Join-Path $BASE_DIR "core" "package-mgr.ps1")
. (Join-Path $BASE_DIR "lib" "apps-data.ps1")

trap { Log-Error $_.Exception.Message; exit 1 }

if ($global:DRY_RUN) {
    Write-Host ""
    Write-Host "  [DRY-RUN] Modo simulacao ativado - nenhuma alteracao sera feita." -ForegroundColor Yellow
    Write-Host ""
}

# ── Helpers ──────────────────────────────────────────────────────────────────

function Show-Header {
    Write-Host ""
    Write-Host "  ██╗   ██╗██████╗ ██████╗ ████████╗███████╗ ██████╗██╗  ██╗" -ForegroundColor Cyan
    Write-Host "  ██║   ██║╚════██╗██╔══██╗╚══██╔══╝██╔════╝██╔════╝██║  ██║" -ForegroundColor Cyan
    Write-Host "  ██║   ██║ █████╔╝██████╔╝   ██║   █████╗  ██║     ███████║" -ForegroundColor Cyan
    Write-Host "  ╚██╗ ██╔╝ ╚═══██╗██╔══██╗   ██║   ██╔══╝  ██║     ██╔══██║" -ForegroundColor Cyan
    Write-Host "   ╚████╔╝ ██████╔╝██║  ██║   ██║   ███████╗╚██████╗██║  ██║" -ForegroundColor Cyan
    Write-Host "    ╚═══╝  ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  v3rtech-scripts-win — Automacao Windows 11" -ForegroundColor White
    Write-Host "  Versao 1.1.0 | PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray
    Write-Host ""
}

function Invoke-Category {
    param([string]$Category)
    $script = Join-Path $BASE_DIR "lib" "install-apps-$Category.ps1"
    if (Test-Path $script) {
        & $script
    } else {
        Log-Warn "Script para categoria '$Category' nao encontrado: $script"
    }
}

function Show-CategoryMenu {
    $categories = @(
        @{ Key="1"; Name="internet";    Label="Internet    (Chrome, Firefox, Telegram, Zoom)" }
        @{ Key="2"; Name="dev";         Label="Dev         (VS Code, Git, Node.js, Docker)" }
        @{ Key="3"; Name="office";      Label="Escritorio  (LibreOffice, Notion, PDF24)" }
        @{ Key="4"; Name="multimedia";  Label="Multimidia  (VLC, Spotify, OBS, Audacity)" }
        @{ Key="5"; Name="design";      Label="Design      (Figma, GIMP, Inkscape, Blender)" }
        @{ Key="6"; Name="system";      Label="Sistema     (7-Zip, PowerToys, Everything)" }
        @{ Key="7"; Name="games";       Label="Games       (Steam, Epic, GOG Galaxy)" }
    )

    do {
        Write-Host ""
        Write-Host "  Instalar por categoria:" -ForegroundColor White
        Write-Host ""
        foreach ($c in $categories) {
            Write-Host "  [$($c.Key)] $($c.Label)" -ForegroundColor Cyan
        }
        Write-Host "  [A] Todas as categorias" -ForegroundColor Yellow
        Write-Host "  [0] Voltar" -ForegroundColor DarkGray
        Write-Host ""

        $opt = if ($global:AUTO_CONFIRM) { "A" } else { Read-Host "  > " }

        switch ($opt.ToUpper()) {
            "1" { Invoke-Category "internet" }
            "2" { Invoke-Category "dev" }
            "3" { Invoke-Category "office" }
            "4" { Invoke-Category "multimedia" }
            "5" { Invoke-Category "design" }
            "6" { Invoke-Category "system" }
            "7" { Invoke-Category "games" }
            "A" {
                foreach ($c in $categories) { Invoke-Category $c.Name }
                Log-Success "Todas as categorias concluidas."
            }
            "0" { return }
            default { Log-Warn "Opcao invalida." }
        }
    } while ($opt -notin @("0"))
}

function Show-ProfileMenu {
    $profilesDir = Join-Path $BASE_DIR "profiles"
    $profileFiles = Get-ChildItem $profilesDir -Filter "*.json" | Sort-Object Name

    do {
        Write-Host ""
        Write-Host "  Instalar por perfil:" -ForegroundColor White
        Write-Host ""
        $i = 1
        $profiles = @()
        foreach ($f in $profileFiles) {
            $p = Get-Content $f.FullName -Raw | ConvertFrom-Json
            Write-Host "  [$i] $($p.name) — $($p.description)" -ForegroundColor Cyan
            $profiles += $p
            $i++
        }
        Write-Host "  [0] Voltar" -ForegroundColor DarkGray
        Write-Host ""

        $opt = if ($global:AUTO_CONFIRM) { "1" } else { Read-Host "  > " }

        if ($opt -eq "0") { return }

        $idx = [int]$opt - 1
        if ($idx -lt 0 -or $idx -ge $profiles.Count) {
            Log-Warn "Opcao invalida."
            continue
        }

        $selectedProfile = $profiles[$idx]
        Log-Step "Aplicando perfil: $($selectedProfile.name)"

        foreach ($category in $selectedProfile.categories) {
            Invoke-Category $category
        }

        if ($selectedProfile.apps_extra -and $selectedProfile.apps_extra.Count -gt 0) {
            Log-Step "Instalando apps extras do perfil..."
            foreach ($appName in $selectedProfile.apps_extra) {
                Install-App -AppName $appName
            }
        }

        Log-Success "Perfil '$($selectedProfile.name)' aplicado."
        return

    } while ($true)
}

function Show-MainMenu {
    Write-Host "  O que deseja fazer?" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Instalar apps por categoria" -ForegroundColor Cyan
    Write-Host "  [2] Instalar por perfil"         -ForegroundColor Cyan
    Write-Host "  [0] Sair"                        -ForegroundColor DarkGray
    Write-Host ""
}

# ── MAIN ─────────────────────────────────────────────────────────────────────

Show-Header

if (-not $global:CONFIG["windows_build"]) {
    . (Join-Path $BASE_DIR "lib" "detect-system.ps1")
}

do {
    Show-MainMenu
    $opt = if ($global:AUTO_CONFIRM) { "0" } else { Read-Host "  > " }

    switch ($opt) {
        "1" { Show-CategoryMenu }
        "2" { Show-ProfileMenu }
        "0" { Log-Info "Saindo."; break }
        default { Log-Warn "Opcao invalida." }
    }
} while ($opt -ne "0")
```

- [ ] **Step 2: Testar wizard em dry-run — navegação de categorias**

```powershell
$env:DRY_RUN=1; .\v3rtech-install.ps1
```

Resultado esperado: banner ASCII, menu com opções 1/2/0. Selecionar `1` → submenu com 7 categorias + A + 0. Selecionar `2` → lista 4 perfis. Selecionar `0` → sai sem erro.

- [ ] **Step 3: Testar AUTO_CONFIRM (sai imediatamente)**

```powershell
$env:DRY_RUN=1; $env:AUTO_CONFIRM=1; .\v3rtech-install.ps1
```

Resultado esperado: executa sem input manual, sai normalmente (AUTO_CONFIRM no menu principal seleciona "0").

- [ ] **Step 4: Commit**

```bash
git add v3rtech-install.ps1
git commit -m "feat: wizard completo com submenu de categorias e perfis"
```

---

## Task 10: CHANGELOG.md e tag v1.1.0

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Atualizar CHANGELOG.md**

Substituir o conteúdo atual por:

```markdown
# Changelog

All notable changes to this project will be documented in this file.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) | Versioning: [SemVer](https://semver.org/)

## [1.1.0] - 2026-05-08

### Added
- lib/install-apps-dev.ps1: instalação de ferramentas de desenvolvimento (VS Code, Git, Node.js, Python, Docker Desktop, Windows Terminal)
- lib/install-apps-office.ps1: instalação de apps de escritório (LibreOffice, Notion, PDF24, OnlyOffice, Adobe Reader, Calibre)
- lib/install-apps-multimedia.ps1: instalação de apps de multimídia (VLC, Spotify, OBS Studio, Audacity, HandBrake, MPC-HC)
- lib/install-apps-design.ps1: instalação de apps de design (Figma, GIMP, Inkscape, Blender, Krita, Canva)
- lib/install-apps-system.ps1: instalação de utilitários de sistema (7-Zip, Everything, PowerToys, Ventoy, CrystalDiskInfo, HWiNFO)
- lib/install-apps-games.ps1: instalação de plataformas de games (Steam, Epic Games, GOG Galaxy, Battle.net)
- apps-data.ps1: 28 novos apps em 5 categorias (office, multimedia, design, system, games)
- profiles/criador-conteudo.json: perfil para criadores de conteúdo
- profiles/domestico.json: perfil para uso doméstico
- v3rtech-install.ps1: wizard completo com submenu de categorias e seleção por perfil
- tests/lib/install-apps-categories.Tests.ps1: 24 testes de dados para todas as categorias

## [1.0.0] - 2026-05-08

### Added
- core/env.ps1: variáveis globais, config JSON persistente, flags de execução (DRY_RUN, VERBOSE, AUTO_CONFIRM)
- core/logging.ps1: logging colorizado (STEP/INFO/WARN/ERROR/SUCCESS/DEBUG) com saída simultânea para terminal e arquivo
- core/package-mgr.ps1: abstração winget/choco/scoop com Install-App, Get-InstallOrder, Bootstrap automático
- lib/detect-system.ps1: detecção de Windows version, GPU, arquitetura, sessão, privilégios de administrador
- lib/apps-data.ps1: banco de dados de apps com Add-App/Get-AppsByCategory (categorias: internet, dev)
- lib/install-apps-internet.ps1: instalação de apps de internet (Chrome, Firefox, Brave, Telegram, Discord, Zoom)
- Project scaffold: estrutura de diretórios completa
- profiles/desenvolvedor.json e profiles/escritorio.json
- v3rtech-install.ps1: wizard CLI skeleton com menu e suporte a perfis JSON
- tests/: 44 testes Pester cobrindo core e apps-data
```

- [ ] **Step 2: Rodar suite completa uma última vez**

```powershell
Invoke-Pester -Path tests/ -Output Normal
```

Resultado esperado: `Tests Passed: 68, Failed: 0`

- [ ] **Step 3: Commit e tag**

```bash
git add CHANGELOG.md
git commit -m "chore(v1.1.0): bump versão + atualiza CHANGELOG"
git tag v1.1.0
git push && git push --tags
```

---

## Validação Final do Plano 2

- [ ] `Invoke-Pester -Path tests/ -Output Normal` → `Failed: 0, Passed: 68`
- [ ] `$env:DRY_RUN=1; .\v3rtech-install.ps1` → banner + menu principal
- [ ] Opção `1` → submenu com 7 categorias + A
- [ ] Opção `A` no submenu → loga dry-run para todas as categorias (internet + dev + office + multimedia + design + system + games)
- [ ] Opção `2` no menu principal → lista 4 perfis (desenvolvedor, escritorio, criador-conteudo, domestico)
- [ ] Selecionar perfil `desenvolvedor` → roda internet + dev + system em dry-run
- [ ] `$env:DRY_RUN=1; .\lib\install-apps-office.ps1` → standalone funciona
- [ ] `$env:DRY_RUN=1; .\lib\install-apps-games.ps1` → standalone funciona
- [ ] `git tag` → mostra `v1.0.0-foundation` e `v1.1.0`

---

## Próximos Planos

- **Plano 3:** `setup-system.ps1` (registro, PATH, telemetria, políticas UAC) + `setup-winfeatures.ps1` (WSL 2, Hyper-V, .NET via DISM) + `setup-appconfig.ps1` (pós-instalação: VS Code extensions, Git config, PowerShell profile, WSL config)
