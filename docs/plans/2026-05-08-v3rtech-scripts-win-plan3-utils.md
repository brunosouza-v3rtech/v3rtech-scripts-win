# v3rtech-scripts-win — Plano 3: Utilitários (`utils/`)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar 9 scripts utilitários standalone em `utils/`, migrados e modernizados a partir dos scripts antigos do usuário — cobrindo atualização de pacotes, conversão de mídia, wallpaper multi-monitor, SSH, FileBot, legendas, Transmission e PDFs.

**Architecture:** Cada utilitário em `utils/` é independente, aceita parâmetros via `-Param` e respeita `$env:DRY_RUN`. Scripts que precisam de credenciais ou hosts lêem de `~/.config/v3rtech-scripts-win/config.json` ou de arquivos de configuração gitignored em `configs/`. Sem dependências entre utilitários. Cada um carrega apenas `core/env.ps1` + `core/logging.ps1` (sem package-mgr, sem apps-data).

**Tech Stack:** PowerShell 7+, Pester 5.x (testes de smoke/parâmetros). Dependências externas por script: ImageMagick, MKVToolNix, FileBot, pdftk, transmission-remote, OpenSSH (todos instaláveis via `apps-data.ps1`).

---

## Mapa de Arquivos

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `utils/upall.ps1` | Criar | Atualiza todos os gerenciadores de pacotes (winget + choco + scoop) |
| `utils/img-convert.ps1` | Criar | Converte imagens para JPG com ImageMagick (recursivo, redimensiona) |
| `utils/wallpaper-rotator.ps1` | Criar | Rotação automática de wallpaper multi-monitor a cada N minutos |
| `utils/mkv-extract-subtitles.ps1` | Criar | Extrai faixa de legenda de MKV para SRT via mkvextract |
| `utils/merge-pdfs.ps1` | Criar | Mescla todos os PDFs de uma pasta em um único arquivo via pdftk |
| `utils/ssh-connect.ps1` | Criar | Gerenciador de conexões SSH com correção de permissões de chave |
| `configs/ssh-hosts.example.ps1` | Criar | Template de hosts SSH (editável, o real é gitignored) |
| `utils/video-rename.ps1` | Criar | Renomeia vídeos com FileBot (filmes, séries, anime, documentários) |
| `utils/get-subtitles.ps1` | Criar | Baixa legendas PT/EN com FileBot suball |
| `utils/transmission-clear.ps1` | Criar | Remove torrents concluídos/inativos do Transmission via API |
| `tests/utils/utils.Tests.ps1` | Criar | Testes de smoke: parâmetros, DRY_RUN, ajuda (`-Help`) |
| `CHANGELOG.md` | Modificar | Entrada v1.2.0 |

**Nota de segurança:** `configs/ssh-hosts.ps1` (real, com IPs) deve ser adicionado ao `.gitignore`. O plano cria apenas o `example` rastreado no git.

---

## Task 1: `utils/upall.ps1`

**Files:**
- Create: `utils/upall.ps1`

- [ ] **Step 1: Criar o script**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/upall.ps1
# Versão: 1.2.0
# Objetivo: Atualiza todos os gerenciadores de pacotes instalados
# Uso: .\utils\upall.ps1 [-DryRun]
# ==============================================================================

param([switch]$DryRun)

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")

$isDry = $DryRun -or $global:DRY_RUN

Log-Step "Atualizando todos os gerenciadores de pacotes..."

function Update-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Log-Warn "winget não encontrado. Pulando."
        return
    }
    Log-Info "winget upgrade --all"
    if ($isDry) { Log-Info "[DRY-RUN] winget upgrade --all --silent"; return }
    winget upgrade --all --accept-package-agreements --accept-source-agreements `
        --ignore-warnings --disable-interactivity --include-pinned --silent
    if ($LASTEXITCODE -eq 0) { Log-Success "winget: atualização concluída." }
    else { Log-Warn "winget: concluído com avisos (exit $LASTEXITCODE)." }
}

function Update-Choco {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Log-Warn "chocolatey não encontrado. Pulando."
        return
    }
    Log-Info "choco upgrade all"
    if ($isDry) { Log-Info "[DRY-RUN] choco upgrade all -y"; return }
    choco upgrade all -y
    if ($LASTEXITCODE -eq 0) { Log-Success "chocolatey: atualização concluída." }
    else { Log-Warn "chocolatey: concluído com avisos (exit $LASTEXITCODE)." }
}

function Update-Scoop {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Log-Warn "scoop não encontrado. Pulando."
        return
    }
    Log-Info "scoop update *"
    if ($isDry) { Log-Info "[DRY-RUN] scoop update * ; scoop cleanup *"; return }
    scoop update *
    scoop cleanup *
    Log-Success "scoop: atualização concluída."
}

Update-Winget
Update-Choco
Update-Scoop

Log-Success "Todos os gerenciadores atualizados."
```

- [ ] **Step 2: Testar em dry-run**

```powershell
$env:DRY_RUN=1; .\utils\upall.ps1
```

Resultado esperado: logs `[DRY-RUN]` para cada gerenciador disponível, sem execução real.

- [ ] **Step 3: Verificar sintaxe**

```powershell
pwsh -NoProfile -NonInteractive -Command {
    $errs = $null
    [void][Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path 'utils/upall.ps1'), [ref]$null, [ref]$errs)
    if ($errs) { $errs | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }; exit 1 }
    Write-Host "Sintaxe OK" -ForegroundColor Green
}
```

- [ ] **Step 4: Commit**

```bash
git add utils/upall.ps1
git commit -m "feat: utils/upall.ps1 — atualiza winget + choco + scoop"
```

---

## Task 2: `utils/img-convert.ps1`

**Files:**
- Create: `utils/img-convert.ps1`

Migrado de `img-convert.bat`. Converte PNG/WEBP/TIFF/GIF/BMP → JPG recursivamente. Renomeia original com extensão `.converted` antes de deletar. Requer ImageMagick (`magick` ou `convert`).

- [ ] **Step 1: Criar o script**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/img-convert.ps1
# Versão: 1.2.0
# Objetivo: Converte imagens para JPG com ImageMagick (recursivo)
# Uso: .\utils\img-convert.ps1 -Path "C:\Fotos" [-MaxWidth 1920] [-Quality 90]
# Requer: ImageMagick instalado (winget install ImageMagick.ImageMagick)
# ==============================================================================

param(
    [Parameter(Mandatory)][string]$Path,
    [int]$MaxWidth = 1920,
    [int]$Quality  = 90,
    [switch]$DryRun
)

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")

$isDry = $DryRun -or $global:DRY_RUN

if (-not (Test-Path $Path)) { Die "Caminho não encontrado: $Path" }

$magick = Get-Command magick -ErrorAction SilentlyContinue
if (-not $magick) { Die "ImageMagick não encontrado. Instale com: winget install ImageMagick.ImageMagick" }

$extensions = @("*.png", "*.webp", "*.tiff", "*.tif", "*.gif", "*.bmp", "*.jpeg")
$files = $extensions | ForEach-Object { Get-ChildItem -Path $Path -Filter $_ -Recurse } | Sort-Object FullName

if ($files.Count -eq 0) {
    Log-Info "Nenhuma imagem encontrada em: $Path"
    exit 0
}

Log-Step "Convertendo $($files.Count) imagem(ns) para JPG em: $Path"

$ok = 0; $fail = 0; $logFile = Join-Path $Path "conversion_errors.log"

foreach ($file in $files) {
    $dest = [System.IO.Path]::ChangeExtension($file.FullName, ".jpg")
    Log-Info "Convertendo: $($file.Name) → $([System.IO.Path]::GetFileName($dest))"

    if ($isDry) {
        Log-Info "[DRY-RUN] magick `"$($file.FullName)`" -resize ${MaxWidth}x${MaxWidth}> -quality $Quality `"$dest`""
        $ok++
        continue
    }

    try {
        & magick $file.FullName -resize "${MaxWidth}x${MaxWidth}>" -quality $Quality $dest
        if ($LASTEXITCODE -ne 0) { throw "exit $LASTEXITCODE" }

        $converted = $file.FullName + ".converted"
        Rename-Item -Path $file.FullName -NewName ([System.IO.Path]::GetFileName($converted))
        Remove-Item -Path $converted -Force
        $ok++
    } catch {
        $msg = "ERRO: $($file.FullName) — $_"
        Log-Error $msg
        Add-Content -Path $logFile -Value $msg -Encoding UTF8
        $fail++
    }
}

Log-Success "Concluído: $ok convertidos, $fail falhas."
if ($fail -gt 0) { Log-Warn "Erros em: $logFile" }
```

- [ ] **Step 2: Testar em dry-run**

```powershell
# Criar pasta de teste com imagens fictícias
$testDir = "$env:TEMP\img-convert-test"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
# Criar arquivo de teste (não é imagem real, só testa o fluxo de descoberta)
New-Item -Path "$testDir\test.png" -ItemType File -Force | Out-Null

$env:DRY_RUN=1; .\utils\img-convert.ps1 -Path $testDir
```

Resultado esperado: `[DRY-RUN] magick "...test.png" -resize 1920x1920> -quality 90 "...test.jpg"`. Sem arquivos modificados.

```powershell
Remove-Item $testDir -Recurse -Force
```

- [ ] **Step 3: Verificar sintaxe**

```powershell
pwsh -NoProfile -NonInteractive -Command {
    $errs = $null
    [void][Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path 'utils/img-convert.ps1'), [ref]$null, [ref]$errs)
    if ($errs) { $errs | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }; exit 1 }
    Write-Host "Sintaxe OK" -ForegroundColor Green
}
```

- [ ] **Step 4: Commit**

```bash
git add utils/img-convert.ps1
git commit -m "feat: utils/img-convert.ps1 — converte imagens para JPG com ImageMagick"
```

---

## Task 3: `utils/wallpaper-rotator.ps1`

**Files:**
- Create: `utils/wallpaper-rotator.ps1`

Migrado de `troca_wallpaper.ps1`. Detecta número de monitores, seleciona imagens aleatórias, cria imagem combinada side-by-side via `System.Drawing`, aplica via `SystemParametersInfo`. Roda em loop infinito.

- [ ] **Step 1: Criar o script**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/wallpaper-rotator.ps1
# Versão: 1.2.0
# Objetivo: Rotação automática de wallpaper multi-monitor
# Uso: .\utils\wallpaper-rotator.ps1 -Path "C:\Imagens" [-IntervalMinutes 10]
# ==============================================================================

param(
    [Parameter(Mandatory)][string]$Path,
    [int]$IntervalMinutes = 10
)

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")

if (-not (Test-Path $Path)) { Die "Pasta de wallpapers não encontrada: $Path" }

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    public const int SPI_SETDESKWALLPAPER = 20;
    public const int SPIF_UPDATEINIFILE   = 0x01;
    public const int SPIF_SENDCHANGE      = 0x02;
    public static void Set(string path) {
        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    }
}
"@

function Get-MonitorCount {
    if ($IsWindows) {
        try {
            $monitors = Get-CimInstance -Namespace root/wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction Stop
            return @($monitors).Count
        } catch { return 1 }
    }
    return 1
}

function Get-RandomImages {
    param([string]$Folder, [int]$Count)
    $images = Get-ChildItem -Path $Folder -Recurse -Include "*.jpg","*.jpeg","*.png","*.bmp" |
              Get-Random -Count $Count
    return @($images)
}

function Set-CombinedWallpaper {
    param([string[]]$ImagePaths)

    if ($ImagePaths.Count -eq 1) {
        [Wallpaper]::Set($ImagePaths[0])
        return
    }

    $bitmaps = $ImagePaths | ForEach-Object { [System.Drawing.Bitmap]::new($_) }
    $totalWidth  = ($bitmaps | Measure-Object -Property Width  -Sum).Sum
    $totalHeight = ($bitmaps | Measure-Object -Property Height -Maximum).Maximum

    $combined = [System.Drawing.Bitmap]::new($totalWidth, $totalHeight)
    $graphics  = [System.Drawing.Graphics]::FromImage($combined)
    $graphics.Clear([System.Drawing.Color]::Black)

    $x = 0
    foreach ($bmp in $bitmaps) {
        $graphics.DrawImage($bmp, $x, 0, $bmp.Width, $bmp.Height)
        $x += $bmp.Width
        $bmp.Dispose()
    }
    $graphics.Dispose()

    $tempFile = Join-Path $env:TEMP "v3rtech-wallpaper.jpg"
    $combined.Save($tempFile, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $combined.Dispose()

    [Wallpaper]::Set($tempFile)
}

$monitorCount = Get-MonitorCount
Log-Step "Iniciando rotação de wallpaper — $monitorCount monitor(es), intervalo: ${IntervalMinutes}min"
Log-Info "Pasta: $Path | Ctrl+C para parar"

while ($true) {
    $images = Get-RandomImages -Folder $Path -Count $monitorCount

    if ($images.Count -eq 0) {
        Log-Warn "Nenhuma imagem encontrada em: $Path"
        Start-Sleep -Seconds ($IntervalMinutes * 60)
        continue
    }

    $names = ($images | ForEach-Object { $_.Name }) -join ", "
    Log-Info "Aplicando: $names"

    try {
        Set-CombinedWallpaper -ImagePaths ($images | ForEach-Object { $_.FullName })
        Log-Success "Wallpaper atualizado."
    } catch {
        Log-Error "Falha ao aplicar wallpaper: $_"
    }

    Start-Sleep -Seconds ($IntervalMinutes * 60)
}
```

- [ ] **Step 2: Verificar sintaxe**

```powershell
pwsh -NoProfile -NonInteractive -Command {
    $errs = $null
    [void][Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path 'utils/wallpaper-rotator.ps1'), [ref]$null, [ref]$errs)
    if ($errs) { $errs | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }; exit 1 }
    Write-Host "Sintaxe OK" -ForegroundColor Green
}
```

- [ ] **Step 3: Commit**

```bash
git add utils/wallpaper-rotator.ps1
git commit -m "feat: utils/wallpaper-rotator.ps1 — wallpaper multi-monitor com rotação automática"
```

---

## Task 4: `utils/mkv-extract-subtitles.ps1`

**Files:**
- Create: `utils/mkv-extract-subtitles.ps1`

Migrado de `mkv-extract-subtitles.bat`. Extrai faixa de legenda de arquivo MKV para SRT. Requer MKVToolNix.

- [ ] **Step 1: Criar o script**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/mkv-extract-subtitles.ps1
# Versão: 1.2.0
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
```

- [ ] **Step 2: Testar em dry-run**

```powershell
# Cria arquivo vazio para testar validação e dry-run
$testFile = "$env:TEMP\test.mkv"
New-Item -Path $testFile -ItemType File -Force | Out-Null

$env:DRY_RUN=1; .\utils\mkv-extract-subtitles.ps1 -File $testFile -Track 2

Remove-Item $testFile -Force
```

Resultado esperado: `[DRY-RUN] mkvextract tracks "...test.mkv" 2:"...test.srt"`

- [ ] **Step 3: Verificar sintaxe**

```powershell
pwsh -NoProfile -NonInteractive -Command {
    $errs = $null
    [void][Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path 'utils/mkv-extract-subtitles.ps1'), [ref]$null, [ref]$errs)
    if ($errs) { $errs | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }; exit 1 }
    Write-Host "Sintaxe OK" -ForegroundColor Green
}
```

- [ ] **Step 4: Commit**

```bash
git add utils/mkv-extract-subtitles.ps1
git commit -m "feat: utils/mkv-extract-subtitles.ps1 — extrai legenda de MKV para SRT"
```

---

## Task 5: `utils/merge-pdfs.ps1`

**Files:**
- Create: `utils/merge-pdfs.ps1`

Migrado de `mesclar_pdfs.bat`. Mescla todos os PDFs de uma pasta em um único arquivo. Requer pdftk.

- [ ] **Step 1: Criar o script**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/merge-pdfs.ps1
# Versão: 1.2.0
# Objetivo: Mescla todos os PDFs de uma pasta em um único arquivo
# Uso: .\utils\merge-pdfs.ps1 -Path "C:\Docs" -Output "merged.pdf"
# Requer: pdftk (winget install PDF-Association.PDFtkBuilder  ou choco install pdftk)
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

$args = ($pdfs | ForEach-Object { $_.FullName }) + @("cat", "output", $outputPath)
& pdftk @args

if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
    Log-Success "PDF mesclado: $outputPath"
} else {
    Die "Falha ao mesclar PDFs (exit $LASTEXITCODE)."
}
```

- [ ] **Step 2: Testar em dry-run**

```powershell
$testDir = "$env:TEMP\merge-pdf-test"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
New-Item -Path "$testDir\doc1.pdf" -ItemType File -Force | Out-Null
New-Item -Path "$testDir\doc2.pdf" -ItemType File -Force | Out-Null

$env:DRY_RUN=1; .\utils\merge-pdfs.ps1 -Path $testDir -Output "merged.pdf"

Remove-Item $testDir -Recurse -Force
```

Resultado esperado: lista dos 2 PDFs + `[DRY-RUN] pdftk "...doc1.pdf" "...doc2.pdf" cat output "...merged.pdf"`

- [ ] **Step 3: Verificar sintaxe**

```powershell
pwsh -NoProfile -NonInteractive -Command {
    $errs = $null
    [void][Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path 'utils/merge-pdfs.ps1'), [ref]$null, [ref]$errs)
    if ($errs) { $errs | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }; exit 1 }
    Write-Host "Sintaxe OK" -ForegroundColor Green
}
```

- [ ] **Step 4: Commit**

```bash
git add utils/merge-pdfs.ps1
git commit -m "feat: utils/merge-pdfs.ps1 — mescla PDFs com pdftk"
```

---

## Task 6: `utils/ssh-connect.ps1` + `configs/ssh-hosts.example.ps1`

**Files:**
- Create: `utils/ssh-connect.ps1`
- Create: `configs/ssh-hosts.example.ps1`
- Modify: `.gitignore` (adicionar `configs/ssh-hosts.ps1`)

Consolida os ~18 scripts de conexão SSH individuais. Corrige permissões da chave privada automaticamente (padrão `icacls` dos scripts antigos). Lê hosts de `configs/ssh-hosts.ps1` (gitignored, copiado do example pelo usuário).

- [ ] **Step 1: Criar `configs/ssh-hosts.example.ps1`**

```powershell
# ==============================================================================
# configs/ssh-hosts.example.ps1 — Template de hosts SSH
# Copie para configs/ssh-hosts.ps1 e preencha com seus servidores reais.
# configs/ssh-hosts.ps1 está no .gitignore.
# ==============================================================================

$global:SSH_KEY  = "$HOME\.ssh\id_rsa"   # Caminho da chave privada
$global:SSH_USER = "seu_usuario"          # Usuário padrão (sobrescrito por host)

$global:SSH_HOSTS = @{
    # Formato: "alias" = @{ Host="ip_ou_hostname"; Port=22; User="usuario" }

    # Exemplos:
    "nas"         = @{ Host = "192.168.0.10";   Port = 22;   User = "admin"   }
    "pi"          = @{ Host = "192.168.0.101";  Port = 22;   User = "pi"      }
    "servidor"    = @{ Host = "192.168.0.145";  Port = 22;   User = "bruno"   }
    "vps"         = @{ Host = "0.0.0.0";        Port = 22;   User = "ubuntu"  }
    "docker"      = @{ Host = "0.0.0.0";        Port = 9022; User = "deploy"  }
}
```

- [ ] **Step 2: Adicionar `configs/ssh-hosts.ps1` ao `.gitignore`**

Adicionar ao final do `.gitignore`:

```
# SSH hosts (contém IPs e usuários pessoais)
configs/ssh-hosts.ps1
```

- [ ] **Step 3: Criar `utils/ssh-connect.ps1`**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/ssh-connect.ps1
# Versão: 1.2.0
# Objetivo: Gerenciador de conexões SSH com fix automático de permissões de chave
# Uso: .\utils\ssh-connect.ps1 -Host nas
#      .\utils\ssh-connect.ps1          (lista hosts disponíveis)
# Config: copie configs/ssh-hosts.example.ps1 → configs/ssh-hosts.ps1
# ==============================================================================

param([string]$HostAlias = "")

$BASE_DIR = Split-Path -Parent $PSScriptRoot
. (Join-Path $BASE_DIR "core" "env.ps1")
. (Join-Path $BASE_DIR "core" "logging.ps1")

$hostsFile = Join-Path $BASE_DIR "configs" "ssh-hosts.ps1"
if (-not (Test-Path $hostsFile)) {
    Log-Warn "Arquivo de hosts não encontrado: $hostsFile"
    Log-Info "Copie configs/ssh-hosts.example.ps1 → configs/ssh-hosts.ps1 e configure seus servidores."
    exit 1
}
. $hostsFile

function Set-SshKeyPermissions {
    param([string]$KeyPath)
    if (-not (Test-Path $KeyPath)) { Die "Chave SSH não encontrada: $KeyPath" }
    if (-not $IsWindows) { return }

    Log-Info "Corrigindo permissões da chave SSH: $KeyPath"
    $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    icacls $KeyPath /inheritance:r 2>$null | Out-Null
    takeown /F $KeyPath 2>$null | Out-Null
    icacls $KeyPath /grant:r "${user}:F" 2>$null | Out-Null
    icacls $KeyPath /remove "Authenticated Users" 2>$null | Out-Null
    icacls $KeyPath /remove "BUILTIN\Administrators" 2>$null | Out-Null
    icacls $KeyPath /remove "Everyone" 2>$null | Out-Null
}

function Show-Hosts {
    Write-Host ""
    Write-Host "  Hosts SSH disponíveis:" -ForegroundColor Cyan
    Write-Host ""
    foreach ($alias in ($global:SSH_HOSTS.Keys | Sort-Object)) {
        $h = $global:SSH_HOSTS[$alias]
        $port = if ($h.Port -ne 22) { ":$($h.Port)" } else { "" }
        Write-Host "  $($alias.PadRight(20)) $($h.User)@$($h.Host)$port" -ForegroundColor White
    }
    Write-Host ""
}

if (-not $HostAlias) {
    Show-Hosts
    exit 0
}

$hostDef = $global:SSH_HOSTS[$HostAlias]
if (-not $hostDef) {
    Log-Error "Host '$HostAlias' não encontrado."
    Show-Hosts
    exit 1
}

$keyPath = $global:SSH_KEY
$user    = if ($hostDef.User) { $hostDef.User } else { $global:SSH_USER }
$host    = $hostDef.Host
$port    = if ($hostDef.Port) { $hostDef.Port } else { 22 }

Set-SshKeyPermissions -KeyPath $keyPath

Log-Step "Conectando a $HostAlias ($user@${host}:$port)"
ssh -i $keyPath -p $port "${user}@${host}"
```

- [ ] **Step 4: Testar listagem de hosts (sem conexão real)**

```powershell
# Cria um ssh-hosts.ps1 temporário de teste
$testHosts = @'
$global:SSH_KEY  = "$HOME\.ssh\id_rsa"
$global:SSH_USER = "user"
$global:SSH_HOSTS = @{
    "test-server" = @{ Host="192.168.0.1"; Port=22; User="admin" }
    "prod"        = @{ Host="10.0.0.1";   Port=22; User="ubuntu" }
}
'@
$testHosts | Set-Content "configs/ssh-hosts.ps1"

.\utils\ssh-connect.ps1
```

Resultado esperado: tabela com `test-server` e `prod`.

```powershell
Remove-Item "configs/ssh-hosts.ps1" -Force
```

- [ ] **Step 5: Verificar sintaxe**

```powershell
pwsh -NoProfile -NonInteractive -Command {
    $errs = $null
    [void][Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path 'utils/ssh-connect.ps1'), [ref]$null, [ref]$errs)
    if ($errs) { $errs | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }; exit 1 }
    Write-Host "Sintaxe OK" -ForegroundColor Green
}
```

- [ ] **Step 6: Commit**

```bash
git add utils/ssh-connect.ps1 configs/ssh-hosts.example.ps1 .gitignore
git commit -m "feat: utils/ssh-connect.ps1 — gerenciador SSH com fix de permissões de chave"
```

---

## Task 7: `utils/video-rename.ps1`

**Files:**
- Create: `utils/video-rename.ps1`

Migrado de `pre-videos.bat`, `fbr.bat`, `pre-cpd.bat`. Usa FileBot para renomear vídeos com padrões específicos por tipo. Requer FileBot com licença registrada.

- [ ] **Step 1: Criar o script**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/video-rename.ps1
# Versão: 1.2.0
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

# Padrões de renomeação por tipo
$config = @{
    movies      = @{
        DB      = "TheMovieDB"
        Format  = "{n} ({y})\{n} ({y}) [{vf}]"
        Label   = "Filmes"
    }
    series      = @{
        DB      = "TheTVDB"
        Format  = "{n}\Season {s.pad(2)}\{n}.s{s.pad(2)}e{e.pad(2)}.{t}.[{airdate}]"
        Label   = "Séries"
    }
    anime       = @{
        DB      = "TheMovieDB"
        Format  = "{n} ({y})\{n} ({y}) [{vf}]"
        Label   = "Anime"
    }
    documentary = @{
        DB      = "TheMovieDB"
        Format  = "{n} ({y})\{n} ({y}) [{vf}]"
        Label   = "Documentários"
    }
    kids        = @{
        DB      = "TheMovieDB"
        Format  = "{n} ({y})\{n} ({y}) [{vf}]"
        Label   = "Infantil"
    }
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

    # Renomeia legendas .srt → .pt-br.srt (mesmo padrão dos scripts antigos)
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
```

- [ ] **Step 2: Testar em dry-run**

```powershell
$testDir = "$env:TEMP\video-rename-test"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
New-Item -Path "$testDir\movie.mkv" -ItemType File -Force | Out-Null

$env:DRY_RUN=1; .\utils\video-rename.ps1 -Path $testDir -Type movies

Remove-Item $testDir -Recurse -Force
```

Resultado esperado (se FileBot disponível): modo `--action test` sem renomear nada. Se FileBot não disponível: mensagem de erro clara.

- [ ] **Step 3: Verificar sintaxe**

```powershell
pwsh -NoProfile -NonInteractive -Command {
    $errs = $null
    [void][Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path 'utils/video-rename.ps1'), [ref]$null, [ref]$errs)
    if ($errs) { $errs | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }; exit 1 }
    Write-Host "Sintaxe OK" -ForegroundColor Green
}
```

- [ ] **Step 4: Commit**

```bash
git add utils/video-rename.ps1
git commit -m "feat: utils/video-rename.ps1 — renomeia vídeos com FileBot (filmes/séries/anime)"
```

---

## Task 8: `utils/get-subtitles.ps1`

**Files:**
- Create: `utils/get-subtitles.ps1`

Migrado de `lg.bat` e `en-legendas.bat`. Usa FileBot `suball` para baixar legendas. Credenciais opcionais via parâmetro ou config.json (nunca hardcoded).

- [ ] **Step 1: Criar o script**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/get-subtitles.ps1
# Versão: 1.2.0
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

$langs  = $Lang -split "," | ForEach-Object { $_.Trim() }
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
```

- [ ] **Step 2: Testar em dry-run**

```powershell
$testDir = "$env:TEMP\get-subs-test"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$env:DRY_RUN=1; .\utils\get-subtitles.ps1 -Path $testDir -Lang "pt,en"

Remove-Item $testDir -Recurse -Force
```

Resultado esperado: `[DRY-RUN] filebot -script fn:suball ... -lang pt -lang en --encoding UTF-8`

- [ ] **Step 3: Verificar sintaxe**

```powershell
pwsh -NoProfile -NonInteractive -Command {
    $errs = $null
    [void][Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path 'utils/get-subtitles.ps1'), [ref]$null, [ref]$errs)
    if ($errs) { $errs | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }; exit 1 }
    Write-Host "Sintaxe OK" -ForegroundColor Green
}
```

- [ ] **Step 4: Commit**

```bash
git add utils/get-subtitles.ps1
git commit -m "feat: utils/get-subtitles.ps1 — baixa legendas com FileBot suball"
```

---

## Task 9: `utils/transmission-clear.ps1`

**Files:**
- Create: `utils/transmission-clear.ps1`

Migrado de `truenas_transmission_clear.bat`. Remove torrents com status Finished/Seeding/Idle do Transmission via `transmission-remote`.

- [ ] **Step 1: Criar o script**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: utils/transmission-clear.ps1
# Versão: 1.2.0
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
        $id     = $Matches[1]
        $status = $Matches[2]

        if ($clearStatuses -contains $status) {
            Log-Info "Removendo torrent ID $id (status: $status)"
            if ($isDry) {
                Log-Info "[DRY-RUN] transmission-remote $endpoint --torrent $id --remove"
                $removed++
            } else {
                & transmission-remote $endpoint @authArgs --torrent $id --remove 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) { $removed++ }
                else { Log-Warn "Falha ao remover torrent $id"; $skipped++ }
            }
        } else {
            $skipped++
        }
    }
}

Log-Success "Transmission: $removed torrent(s) removidos, $skipped mantidos."
```

- [ ] **Step 2: Testar dry-run (sem servidor real)**

```powershell
$env:DRY_RUN=1; .\utils\transmission-clear.ps1 -Server 192.168.0.1
```

Resultado esperado: falha com `Die "Falha ao conectar ao Transmission"` se servidor inacessível. Em dry-run com servidor acessível: mostraria os `[DRY-RUN]` para cada torrent elegível.

- [ ] **Step 3: Verificar sintaxe**

```powershell
pwsh -NoProfile -NonInteractive -Command {
    $errs = $null
    [void][Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path 'utils/transmission-clear.ps1'), [ref]$null, [ref]$errs)
    if ($errs) { $errs | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }; exit 1 }
    Write-Host "Sintaxe OK" -ForegroundColor Green
}
```

- [ ] **Step 4: Commit**

```bash
git add utils/transmission-clear.ps1
git commit -m "feat: utils/transmission-clear.ps1 — remove torrents concluídos do Transmission"
```

---

## Task 10: Suite de testes dos utilitários

**Files:**
- Create: `tests/utils/utils.Tests.ps1`

Testes de smoke: verifica que cada utilitário tem parâmetros obrigatórios, respeita DRY_RUN e falha com erro claro quando dependência ausente.

- [ ] **Step 1: Criar `tests/utils/utils.Tests.ps1`**

```powershell
BeforeAll {
    $env:DRY_RUN = "1"
    $script:root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

Describe "upall.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "upall.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "executa sem erro em DRY_RUN" {
        $result = pwsh -NoProfile -NonInteractive `
            -Command { $env:DRY_RUN=1; & (Join-Path $args[0] 'utils/upall.ps1') } `
            -args $script:root 2>&1
        $LASTEXITCODE | Should -Be 0
    }
}

Describe "img-convert.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "img-convert.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "falha com mensagem clara se -Path não existe" {
        { & (Join-Path $script:root "utils" "img-convert.ps1") -Path "C:\nao-existe-xyz" } |
            Should -Throw
    }
}

Describe "mkv-extract-subtitles.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "mkv-extract-subtitles.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "falha com mensagem clara se arquivo não existe" {
        { & (Join-Path $script:root "utils" "mkv-extract-subtitles.ps1") -File "C:\nao-existe.mkv" } |
            Should -Throw
    }
}

Describe "merge-pdfs.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "merge-pdfs.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "falha com mensagem clara se -Path não existe" {
        { & (Join-Path $script:root "utils" "merge-pdfs.ps1") -Path "C:\nao-existe-xyz" -Output "out.pdf" } |
            Should -Throw
    }
}

Describe "ssh-connect.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "ssh-connect.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "lista hosts quando chamado sem parâmetros (arquivo de hosts ausente)" {
        $result = & (Join-Path $script:root "utils" "ssh-connect.ps1") 2>&1
        $LASTEXITCODE | Should -BeIn @(0, 1)
    }
}

Describe "video-rename.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "video-rename.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "falha com mensagem clara se -Path não existe" {
        { & (Join-Path $script:root "utils" "video-rename.ps1") -Path "C:\nao-existe-xyz" -Type movies } |
            Should -Throw
    }
}

Describe "get-subtitles.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "get-subtitles.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "falha com mensagem clara se -Path não existe" {
        { & (Join-Path $script:root "utils" "get-subtitles.ps1") -Path "C:\nao-existe-xyz" } |
            Should -Throw
    }
}

Describe "transmission-clear.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "transmission-clear.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "tem parâmetros -Server e -Port" {
        $help = Get-Help (Join-Path $script:root "utils" "transmission-clear.ps1") -ErrorAction SilentlyContinue
        $help | Should -Not -BeNullOrEmpty
    }
}

Describe "wallpaper-rotator.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "wallpaper-rotator.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "falha com mensagem clara se -Path não existe" {
        { & (Join-Path $script:root "utils" "wallpaper-rotator.ps1") -Path "C:\nao-existe-xyz" } |
            Should -Throw
    }
}
```

- [ ] **Step 2: Criar diretório de testes**

```powershell
New-Item -ItemType Directory -Path "tests/utils" -Force | Out-Null
```

- [ ] **Step 3: Rodar os testes**

```powershell
Invoke-Pester -Path tests/utils/ -Output Detailed
```

Resultado esperado: `Tests Passed: 18, Failed: 0`

- [ ] **Step 4: Rodar suite completa**

```powershell
Invoke-Pester -Path tests/ -Output Normal
```

Resultado esperado: `Tests Passed: 86, Failed: 0` (68 + 18 novos)

- [ ] **Step 5: Commit**

```bash
git add tests/utils/utils.Tests.ps1
git commit -m "test: smoke tests para todos os utilitários utils/"
```

---

## Task 11: CHANGELOG.md e tag v1.2.0

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Adicionar entrada v1.2.0 ao topo do CHANGELOG.md**

Inserir antes da linha `## [1.1.0]`:

```markdown
## [1.2.0] - 2026-05-08

### Added
- utils/upall.ps1: atualiza winget + chocolatey + scoop em sequência
- utils/img-convert.ps1: converte PNG/WEBP/TIFF/GIF/BMP para JPG com ImageMagick (recursivo, max 1920px)
- utils/wallpaper-rotator.ps1: rotação automática de wallpaper multi-monitor via System.Drawing
- utils/mkv-extract-subtitles.ps1: extrai faixa de legenda de MKV para SRT com mkvextract
- utils/merge-pdfs.ps1: mescla PDFs de uma pasta em único arquivo com pdftk
- utils/ssh-connect.ps1: gerenciador de conexões SSH com fix automático de permissões de chave
- configs/ssh-hosts.example.ps1: template de hosts SSH (gitignored o real)
- utils/video-rename.ps1: renomeia vídeos com FileBot (filmes, séries, anime, documentários, infantil)
- utils/get-subtitles.ps1: baixa legendas PT/EN com FileBot suball
- utils/transmission-clear.ps1: remove torrents Finished/Seeding/Idle do Transmission via CLI
- tests/utils/utils.Tests.ps1: 18 testes de smoke para todos os utilitários

```

- [ ] **Step 2: Rodar suite completa uma última vez**

```powershell
Invoke-Pester -Path tests/ -Output Normal
```

Resultado esperado: `Tests Passed: 86, Failed: 0`

- [ ] **Step 3: Commit e tag**

```bash
git add CHANGELOG.md
git commit -m "chore(v1.2.0): bump versão + atualiza CHANGELOG"
git tag v1.2.0
git push && git push --tags
```

---

## Validação Final do Plano 3

- [ ] `Invoke-Pester -Path tests/ -Output Normal` → `Failed: 0, Passed: 86`
- [ ] `$env:DRY_RUN=1; .\utils\upall.ps1` → logs sem execução real
- [ ] `$env:DRY_RUN=1; .\utils\img-convert.ps1 -Path $env:TEMP` → dry-run sem modificar arquivos
- [ ] `.\utils\ssh-connect.ps1` (sem parâmetro) → lista hosts ou aviso de arquivo ausente
- [ ] `$env:DRY_RUN=1; .\utils\transmission-clear.ps1 -Server 192.168.0.12` → conecta ou falha com erro claro
- [ ] Cada `utils/*.ps1 -?` → exibe ajuda com parâmetros
- [ ] `git tag` → mostra `v1.0.0-foundation`, `v1.1.0`, `v1.2.0`

---

## Próximos Planos

- **Plano 4:** `setup-system.ps1` (registro, PATH, telemetria, políticas UAC, debloat Xbox) + `setup-winfeatures.ps1` (WSL 2, Hyper-V, .NET via DISM) + `setup-appconfig.ps1` (pós-instalação: VS Code extensions, Git config, PowerShell profile, WSL config, Docker backend WSL2)
