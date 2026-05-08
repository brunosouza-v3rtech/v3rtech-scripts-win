# v3rtech-scripts-win — Plano 1: Foundation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar o repositório `v3rtech-scripts-win` com camada core funcional (env, logging, package-mgr), detecção de sistema, banco de dados de apps e categoria "internet" instalável via dry-run — provando a arquitetura end-to-end.

**Architecture:** Estrutura modular espelhando o projeto Linux: `core/` com infraestrutura base, `lib/` com scripts de instalação/configuração, `profiles/` em JSON. Cada script é independente e executável standalone. PowerShell 7+ com `$ErrorActionPreference = "Stop"` (equivalente a `set -euo pipefail`).

**Tech Stack:** PowerShell 7+, Pester 5.x (testes), winget (gerenciador principal), chocolatey + scoop (fallback).

**Milestone:** Ao final deste plano, `$env:DRY_RUN=1; .\v3rtech-install.ps1` executa o wizard, seleciona a categoria "internet" e loga o que instalaria. Pester passa em todos os testes do core.

---

## Mapa de Arquivos

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `.gitignore` | Criar | Ignorar logs, configs locais |
| `README.md` | Criar | Documentação de usuário (skeleton) |
| `CHANGELOG.md` | Criar | Histórico de versões |
| `CLAUDE.md` | Criar | Guia para Claude Code |
| `core/env.ps1` | Criar | Variáveis globais, config JSON, flags de execução |
| `core/logging.ps1` | Criar | Log colorizado + arquivo |
| `core/package-mgr.ps1` | Criar | Abstração winget/choco/scoop + bootstrap |
| `lib/detect-system.ps1` | Criar | Detecção de Windows version, GPU, arquitetura |
| `lib/apps-data.ps1` | Criar | Banco de dados central de apps (Add-App, Get-AppsByCategory) |
| `lib/install-apps-internet.ps1` | Criar | Categoria internet standalone |
| `profiles/desenvolvedor.json` | Criar | Perfil desenvolvedor |
| `v3rtech-install.ps1` | Criar | Orquestrador / wizard CLI skeleton |
| `tests/core/env.Tests.ps1` | Criar | Testes Pester para env.ps1 |
| `tests/core/logging.Tests.ps1` | Criar | Testes Pester para logging.ps1 |
| `tests/core/package-mgr.Tests.ps1` | Criar | Testes Pester para package-mgr.ps1 |
| `tests/lib/apps-data.Tests.ps1` | Criar | Testes Pester para apps-data.ps1 |

---

## Task 1: Scaffold do repositório

**Files:**
- Criar: `.gitignore`
- Criar: `README.md`
- Criar: `CHANGELOG.md`
- Criar: `CLAUDE.md`
- Criar: `core/`, `lib/`, `profiles/`, `configs/`, `utils/`, `tests/core/`, `tests/lib/`, `dev-history/`, `docs/`

- [ ] **Step 1: Criar diretório raiz e inicializar git**

```powershell
New-Item -ItemType Directory -Path "v3rtech-scripts-win" -Force
Set-Location "v3rtech-scripts-win"
git init
git branch -M main
```

- [ ] **Step 2: Criar estrutura de diretórios**

```powershell
@("core","lib","profiles","configs","utils","tests\core","tests\lib","dev-history","docs") |
    ForEach-Object { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
```

- [ ] **Step 3: Criar `.gitignore`**

```
# Logs e config local
.config/
*.log

# PowerShell
*.ps1xml

# Windows
Thumbs.db
Desktop.ini
$RECYCLE.BIN/
```

- [ ] **Step 4: Criar `README.md` (skeleton)**

```markdown
# v3rtech-scripts-win

Automação e configuração de sistema Windows 11.
Versão: 1.0.0 | PowerShell 7+

## Uso rápido

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\v3rtech-install.ps1
```

## Dry-run (simula sem executar)

```powershell
$env:DRY_RUN=1; .\v3rtech-install.ps1
```
```

- [ ] **Step 5: Criar `CHANGELOG.md`**

```markdown
# Changelog

## [Unreleased]

### Added
- Camada core: env, logging, package-mgr
- Detecção de sistema
- Banco de dados de apps
- Categoria internet
- Wizard CLI skeleton
```

- [ ] **Step 6: Criar `CLAUDE.md`**

```markdown
# CLAUDE.md

Projeto: v3rtech-scripts-win
Versão: 1.0.0
Linguagem: PowerShell 7+
Testes: Pester 5.x (`Invoke-Pester -Path tests/ -Output Detailed`)
Dry-run: `$env:DRY_RUN=1; .\script.ps1`
Verbose: `$env:VERBOSE=1; .\script.ps1`
Auto-confirm: `$env:AUTO_CONFIRM=1; .\script.ps1`

## Sequência de inicialização obrigatória em todo script

```powershell
$BASE_DIR = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
. "$BASE_DIR\core\env.ps1"
. "$BASE_DIR\core\logging.ps1"
. "$BASE_DIR\core\package-mgr.ps1"
```

## Convenções

- Funções: `Verb-Noun` (PascalCase, verbos aprovados pelo PowerShell)
- Variáveis globais: `$global:NOME_MAIUSCULO`
- Variáveis locais: `$camelCase`
- Logging: sempre `Log-*`, nunca `Write-Output` ou `Write-Host` direto
- Erros críticos: `Die "mensagem"`
```

- [ ] **Step 7: Commit inicial**

```bash
git add .
git commit -m "chore: scaffold inicial do repositório v3rtech-scripts-win"
```

---

## Task 2: `core/env.ps1`

**Files:**
- Criar: `core/env.ps1`
- Criar: `tests/core/env.Tests.ps1`

- [ ] **Step 1: Escrever teste antes da implementação**

Arquivo `tests/core/env.Tests.ps1`:

```powershell
BeforeAll {
    $env:DRY_RUN    = "0"
    $env:VERBOSE    = "0"
    $env:AUTO_CONFIRM = "0"

    $script:root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    . "$script:root\core\env.ps1"
}

Describe "env.ps1 — variáveis globais" {
    It "define BASE_DIR como raiz do projeto" {
        $global:BASE_DIR | Should -Not -BeNullOrEmpty
        Test-Path $global:BASE_DIR | Should -Be $true
    }

    It "define CONFIG_DIR dentro do perfil do usuário" {
        $global:CONFIG_DIR | Should -Match [regex]::Escape($env:USERPROFILE)
    }

    It "define LOG_FILE dentro de CONFIG_DIR" {
        $global:LOG_FILE | Should -Match [regex]::Escape($global:CONFIG_DIR)
    }

    It "DRY_RUN é false quando env:DRY_RUN=0" {
        $global:DRY_RUN | Should -Be $false
    }

    It "DRY_RUN é true quando env:DRY_RUN=1" {
        $env:DRY_RUN = "1"
        . "$script:root\core\env.ps1"
        $global:DRY_RUN | Should -Be $true
        $env:DRY_RUN = "0"
    }
}

Describe "env.ps1 — Save-Config / Load-Config" {
    It "Save-Config cria o arquivo de config" {
        $global:CONFIG["test_key"] = "test_value"
        Save-Config
        Test-Path $global:CONFIG_FILE | Should -Be $true
    }

    It "Load-Config carrega chave salva" {
        Load-Config
        $global:CONFIG["test_key"] | Should -Be "test_value"
    }

    AfterAll {
        if (Test-Path $global:CONFIG_FILE) { Remove-Item $global:CONFIG_FILE -Force }
    }
}
```

- [ ] **Step 2: Rodar o teste — confirmar que falha**

```powershell
Invoke-Pester -Path tests/core/env.Tests.ps1 -Output Detailed
```

Resultado esperado: erro `"Cannot dot-source 'core\env.ps1' — file not found"`

- [ ] **Step 3: Implementar `core/env.ps1`**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: core/env.ps1
# Versão: 1.0.0
# Objetivo: Variáveis globais, configuração persistente, flags de execução
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# ==============================================================================

$ErrorActionPreference = "Stop"

# Localização do projeto
$global:BASE_DIR    = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$global:CONFIG_DIR  = Join-Path $env:USERPROFILE ".config\v3rtech-scripts-win"
$global:CONFIG_FILE = Join-Path $global:CONFIG_DIR "config.json"
$global:LOG_DIR     = Join-Path $global:CONFIG_DIR "logs"
$global:LOG_FILE    = Join-Path $global:LOG_DIR   "v3rtech-install.log"

# Flags de execução (variáveis de ambiente têm prioridade)
$global:DRY_RUN      = ($env:DRY_RUN      -eq "1")
$global:VERBOSE_MODE = ($env:VERBOSE      -eq "1")
$global:AUTO_CONFIRM = ($env:AUTO_CONFIRM -eq "1")

# Configuração padrão
$global:CONFIG = [ordered]@{
    prefer_winget       = $true
    install_categories  = @()
    last_update         = ""
}

function Save-Config {
    if (-not (Test-Path $global:CONFIG_DIR)) {
        New-Item -ItemType Directory -Path $global:CONFIG_DIR -Force | Out-Null
    }
    $global:CONFIG | ConvertTo-Json -Depth 3 | Set-Content $global:CONFIG_FILE -Encoding UTF8
}

function Load-Config {
    if (-not (Test-Path $global:CONFIG_FILE)) { return }
    $json = Get-Content $global:CONFIG_FILE -Raw | ConvertFrom-Json
    foreach ($key in $json.PSObject.Properties.Name) {
        $global:CONFIG[$key] = $json.$key
    }
}

# Garantir diretórios de trabalho
foreach ($dir in @($global:CONFIG_DIR, $global:LOG_DIR)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Load-Config
```

- [ ] **Step 4: Rodar testes — confirmar que passam**

```powershell
Invoke-Pester -Path tests/core/env.Tests.ps1 -Output Detailed
```

Resultado esperado: `Tests Passed: 6, Failed: 0`

- [ ] **Step 5: Commit**

```bash
git add core/env.ps1 tests/core/env.Tests.ps1
git commit -m "feat: implementa core/env.ps1 com config persistente e flags de execução"
```

---

## Task 3: `core/logging.ps1`

**Files:**
- Criar: `core/logging.ps1`
- Criar: `tests/core/logging.Tests.ps1`

- [ ] **Step 1: Escrever teste**

Arquivo `tests/core/logging.Tests.ps1`:

```powershell
BeforeAll {
    $env:DRY_RUN = "0"; $env:VERBOSE = "0"
    $script:root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    . "$script:root\core\env.ps1"
    . "$script:root\core\logging.ps1"
}

Describe "Log-Info" {
    It "escreve [INFO] no terminal" {
        Mock Write-Host {}
        Mock Add-Content {}
        Log-Info "mensagem teste"
        Should -Invoke Write-Host -Times 1 -ParameterFilter { $Object -match "\[INFO\]" }
    }
    It "escreve no arquivo de log" {
        Mock Write-Host {}
        Mock Add-Content {}
        Log-Info "log file test"
        Should -Invoke Add-Content -Times 1 -ParameterFilter { $Path -eq $global:LOG_FILE }
    }
}

Describe "Log-Warn" {
    It "usa cor Yellow" {
        Mock Write-Host {}
        Mock Add-Content {}
        Log-Warn "aviso"
        Should -Invoke Write-Host -Times 1 -ParameterFilter {
            $Object -match "\[WARN\]" -and $ForegroundColor -eq "Yellow"
        }
    }
}

Describe "Log-Debug" {
    It "não escreve quando VERBOSE_MODE=false" {
        $global:VERBOSE_MODE = $false
        Mock Write-Host {}
        Log-Debug "debug msg"
        Should -Not -Invoke Write-Host
    }
    It "escreve quando VERBOSE_MODE=true" {
        $global:VERBOSE_MODE = $true
        Mock Write-Host {}
        Mock Add-Content {}
        Log-Debug "debug msg"
        Should -Invoke Write-Host -Times 1
        $global:VERBOSE_MODE = $false
    }
}

Describe "Die" {
    It "termina com exit code 1" {
        { Die "erro fatal" } | Should -Throw
    }
}
```

- [ ] **Step 2: Rodar — confirmar falha**

```powershell
Invoke-Pester -Path tests/core/logging.Tests.ps1 -Output Detailed
```

Resultado esperado: erro `"logging.ps1 not found"`

- [ ] **Step 3: Implementar `core/logging.ps1`**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: core/logging.ps1
# Versão: 1.0.0
# Objetivo: Logging colorizado para terminal e arquivo
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# ==============================================================================

function Write-Log {
    param(
        [string]$Level,
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Level] $Message" -ForegroundColor $Color
    Add-Content -Path $global:LOG_FILE -Value "[$timestamp] [$Level] $Message" -Encoding UTF8
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
```

> **Nota:** `Die` usa `throw` em vez de `exit 1` para permitir que Pester capture o erro nos testes. O orquestrador captura exceções não tratadas no nível superior e faz `exit 1`.

- [ ] **Step 4: Rodar — confirmar que passam**

```powershell
Invoke-Pester -Path tests/core/logging.Tests.ps1 -Output Detailed
```

Resultado esperado: `Tests Passed: 6, Failed: 0`

- [ ] **Step 5: Commit**

```bash
git add core/logging.ps1 tests/core/logging.Tests.ps1
git commit -m "feat: implementa core/logging.ps1 com níveis INFO/WARN/ERROR/SUCCESS/DEBUG"
```

---

## Task 4: `core/package-mgr.ps1`

**Files:**
- Criar: `core/package-mgr.ps1`
- Criar: `tests/core/package-mgr.Tests.ps1`

- [ ] **Step 1: Escrever testes**

Arquivo `tests/core/package-mgr.Tests.ps1`:

```powershell
BeforeAll {
    $env:DRY_RUN = "1"   # todos os testes rodam em dry-run
    $script:root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    . "$script:root\core\env.ps1"
    . "$script:root\core\logging.ps1"
    . "$script:root\core\package-mgr.ps1"
}

Describe "Test-Winget" {
    It "retorna bool" {
        Test-Winget | Should -BeOfType [bool]
    }
}

Describe "Install-ViaWinget — dry-run" {
    It "retorna true com WingetId válido em dry-run" {
        Mock Write-Host {}
        Mock Add-Content {}
        $result = Install-ViaWinget -WingetId "Google.Chrome"
        $result | Should -Be $true
    }
    It "retorna false com WingetId vazio" {
        $result = Install-ViaWinget -WingetId ""
        $result | Should -Be $false
    }
}

Describe "Install-ViaChoco — dry-run" {
    It "retorna true com ChocoId válido em dry-run" {
        Mock Write-Host {}
        Mock Add-Content {}
        $result = Install-ViaChoco -ChocoId "googlechrome"
        $result | Should -Be $true
    }
    It "retorna false com ChocoId vazio" {
        $result = Install-ViaChoco -ChocoId ""
        $result | Should -Be $false
    }
}

Describe "Install-ViaScoop — dry-run" {
    It "retorna true com ScoopId válido em dry-run" {
        Mock Write-Host {}
        Mock Add-Content {}
        $result = Install-ViaScoop -ScoopId "git"
        $result | Should -Be $true
    }
}

Describe "Get-InstallOrder" {
    It "winget é primeiro quando prefer_winget=true" {
        $global:CONFIG["prefer_winget"] = $true
        $app = @{ Method = "any"; WingetId = "x"; ChocoId = "x"; ScoopId = "x" }
        $order = Get-InstallOrder -App $app
        $order[0] | Should -Be "winget"
    }
    It "choco é primeiro quando prefer_winget=false" {
        $global:CONFIG["prefer_winget"] = $false
        $app = @{ Method = "any"; WingetId = "x"; ChocoId = "x"; ScoopId = "x" }
        $order = Get-InstallOrder -App $app
        $order[0] | Should -Be "choco"
        $global:CONFIG["prefer_winget"] = $true
    }
    It "método explícito do app é o primeiro na ordem" {
        $app = @{ Method = "scoop"; WingetId = "x"; ChocoId = "x"; ScoopId = "x" }
        $order = Get-InstallOrder -App $app
        $order[0] | Should -Be "scoop"
    }
}

Describe "Install-App — dry-run" {
    BeforeAll {
        . "$script:root\lib\apps-data.ps1"
    }
    It "instala app existente no banco de dados" {
        Mock Write-Host {}
        Mock Add-Content {}
        Mock Test-AppInstalled { return $false }
        $result = Install-App -AppName "Google Chrome"
        $result | Should -Be $true
    }
    It "retorna false para app inexistente" {
        Mock Write-Host {}
        Mock Add-Content {}
        $result = Install-App -AppName "AppQueNaoExiste"
        $result | Should -Be $false
    }
    It "pula app já instalado" {
        Mock Write-Host {}
        Mock Add-Content {}
        Mock Test-AppInstalled { return $true }
        $result = Install-App -AppName "Google Chrome"
        $result | Should -Be $true
    }
}
```

- [ ] **Step 2: Rodar — confirmar falha**

```powershell
Invoke-Pester -Path tests/core/package-mgr.Tests.ps1 -Output Detailed
```

Resultado esperado: erro `"package-mgr.ps1 not found"`

- [ ] **Step 3: Implementar `core/package-mgr.ps1`**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: core/package-mgr.ps1
# Versão: 1.0.0
# Objetivo: Abstração winget / chocolatey / scoop
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# ==============================================================================

function Test-Winget { return [bool](Get-Command winget -ErrorAction SilentlyContinue) }
function Test-Choco  { return [bool](Get-Command choco  -ErrorAction SilentlyContinue) }
function Test-Scoop  { return [bool](Get-Command scoop  -ErrorAction SilentlyContinue) }

function Bootstrap-Winget {
    if (Test-Winget) { return }
    Log-Warn "winget não encontrado. Tentando registrar Microsoft.DesktopAppInstaller..."
    if ($global:DRY_RUN) { Log-Info "[DRY-RUN] Registraria DesktopAppInstaller"; return }
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
}

function Bootstrap-Choco {
    if (Test-Choco) { return }
    Log-Info "Instalando Chocolatey..."
    if ($global:DRY_RUN) { Log-Info "[DRY-RUN] Instalaria Chocolatey"; return }
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

function Bootstrap-Scoop {
    if (Test-Scoop) { return }
    Log-Info "Instalando Scoop..."
    if ($global:DRY_RUN) { Log-Info "[DRY-RUN] Instalaria Scoop"; return }
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

function Test-AppInstalled {
    param([string]$AppName)
    if (-not (Test-Winget)) { return $false }
    $result = winget list --name $AppName --exact 2>$null
    return ($LASTEXITCODE -eq 0 -and $result -match [regex]::Escape($AppName))
}

function Install-ViaWinget {
    param([string]$WingetId)
    if (-not $WingetId) { return $false }
    Log-Info "winget: $WingetId"
    if ($global:DRY_RUN) { Log-Info "[DRY-RUN] winget install --id $WingetId -e --silent"; return $true }
    winget install --id $WingetId -e --silent --accept-package-agreements --accept-source-agreements
    return ($LASTEXITCODE -eq 0)
}

function Install-ViaChoco {
    param([string]$ChocoId)
    if (-not $ChocoId) { return $false }
    Log-Info "choco: $ChocoId"
    if ($global:DRY_RUN) { Log-Info "[DRY-RUN] choco install $ChocoId -y"; return $true }
    choco install $ChocoId -y
    return ($LASTEXITCODE -eq 0)
}

function Install-ViaScoop {
    param([string]$ScoopId, [string]$ScoopBucket = "")
    if (-not $ScoopId) { return $false }
    Log-Info "scoop: $ScoopId"
    if ($global:DRY_RUN) { Log-Info "[DRY-RUN] scoop install $ScoopId"; return $true }
    if ($ScoopBucket) { scoop bucket add $ScoopBucket 2>$null }
    scoop install $ScoopId
    return ($LASTEXITCODE -eq 0)
}

function Get-InstallOrder {
    param([hashtable]$App)
    $order = [System.Collections.Generic.List[string]]::new()

    $explicit = $App.Method
    if ($explicit -and $explicit -ne "any") { $order.Add($explicit) }

    $priority = if ($global:CONFIG["prefer_winget"]) { @("winget","choco","scoop") }
                else                                  { @("choco","winget","scoop") }

    foreach ($m in $priority) { if (-not $order.Contains($m)) { $order.Add($m) } }
    return $order.ToArray()
}

function Install-App {
    param([string]$AppName)

    $app = $global:APP_MAP[$AppName]
    if (-not $app) { Log-Warn "App '$AppName' não encontrado."; return $false }

    if (Test-AppInstalled -AppName $AppName) {
        Log-Info "'$AppName' já instalado. Pulando."
        return $true
    }

    Log-Step "Instalando $AppName..."
    $methods = Get-InstallOrder -App $app

    foreach ($method in $methods) {
        $ok = switch ($method) {
            "winget" { Install-ViaWinget -WingetId $app.WingetId }
            "choco"  { Install-ViaChoco  -ChocoId  $app.ChocoId  }
            "scoop"  { Install-ViaScoop  -ScoopId  $app.ScoopId  }
            default  { $false }
        }
        if ($ok) { Log-Success "$AppName instalado via $method."; return $true }
    }

    Log-Error "Falha ao instalar '$AppName' por todos os métodos."
    return $false
}

# Bootstrap winget no carregamento do módulo
Bootstrap-Winget
```

- [ ] **Step 4: Rodar testes — confirmar que passam**

```powershell
Invoke-Pester -Path tests/core/package-mgr.Tests.ps1 -Output Detailed
```

Resultado esperado: `Tests Passed: 10, Failed: 0`

- [ ] **Step 5: Commit**

```bash
git add core/package-mgr.ps1 tests/core/package-mgr.Tests.ps1
git commit -m "feat: implementa core/package-mgr.ps1 com abstração winget/choco/scoop"
```

---

## Task 5: `lib/detect-system.ps1`

**Files:**
- Criar: `lib/detect-system.ps1`

- [ ] **Step 1: Implementar `lib/detect-system.ps1`**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/detect-system.ps1
# Versão: 1.0.0
# Objetivo: Detecta Windows version, GPU, arquitetura, tipo de sessão
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# ==============================================================================

Log-Step "Detectando sistema..."

# Windows version
$osInfo = Get-CimInstance Win32_OperatingSystem
$global:CONFIG["windows_name"]    = $osInfo.Caption
$global:CONFIG["windows_build"]   = $osInfo.BuildNumber
$global:CONFIG["windows_version"] = [System.Environment]::OSVersion.Version.ToString()

# Arquitetura
$global:CONFIG["arch"] = $env:PROCESSOR_ARCHITECTURE  # AMD64, ARM64

# Sessão (local, RDP, etc.)
$sessionType = if ($env:SESSIONNAME -eq "Console") { "local" }
               elseif ($env:SESSIONNAME -match "RDP") { "rdp" }
               else { "unknown" }
$global:CONFIG["session_type"] = $sessionType

# GPU vendor
$gpuName = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
$gpuVendor = switch -Regex ($gpuName) {
    "NVIDIA" { "nvidia" }
    "AMD|Radeon" { "amd" }
    "Intel" { "intel" }
    default { "unknown" }
}
$global:CONFIG["gpu_vendor"] = $gpuVendor
$global:CONFIG["gpu_name"]   = $gpuName

# Admin check
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$global:IS_ADMIN = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Log-Info "Sistema: $($global:CONFIG['windows_name']) (build $($global:CONFIG['windows_build']))"
Log-Info "Arch: $($global:CONFIG['arch']) | GPU: $gpuVendor ($gpuName)"
Log-Info "Sessão: $sessionType | Admin: $($global:IS_ADMIN)"

Save-Config
```

- [ ] **Step 2: Verificar sintaxe**

```powershell
$errors = $null
$null = [Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path "lib/detect-system.ps1"),
    [ref]$null, [ref]$errors
)
if ($errors) { $errors | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }; exit 1 }
Write-Host "Sintaxe OK" -ForegroundColor Green
```

- [ ] **Step 3: Commit**

```bash
git add lib/detect-system.ps1
git commit -m "feat: implementa lib/detect-system.ps1 (Windows version, GPU, arch, admin)"
```

---

## Task 6: `lib/apps-data.ps1`

**Files:**
- Criar: `lib/apps-data.ps1`
- Criar: `tests/lib/apps-data.Tests.ps1`

- [ ] **Step 1: Escrever testes**

Arquivo `tests/lib/apps-data.Tests.ps1`:

```powershell
BeforeAll {
    $env:DRY_RUN = "1"
    $script:root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    . "$script:root\core\env.ps1"
    . "$script:root\core\logging.ps1"
    . "$script:root\core\package-mgr.ps1"
    . "$script:root\lib\apps-data.ps1"
}

Describe "Add-App / APP_MAP" {
    It "registra app no APP_MAP" {
        $global:APP_MAP.ContainsKey("Google Chrome") | Should -Be $true
    }
    It "app tem WingetId preenchido" {
        $global:APP_MAP["Google Chrome"].WingetId | Should -Not -BeNullOrEmpty
    }
    It "app tem Category preenchida" {
        $global:APP_MAP["Google Chrome"].Category | Should -Be "internet"
    }
}

Describe "Get-AppsByCategory" {
    It "retorna apps da categoria internet" {
        $apps = Get-AppsByCategory -Category "internet"
        $apps.Count | Should -BeGreaterThan 0
    }
    It "não retorna apps de outra categoria" {
        $apps = Get-AppsByCategory -Category "internet"
        $apps | ForEach-Object {
            $global:APP_MAP[$_].Category | Should -Be "internet"
        }
    }
    It "retorna apenas apps ativos" {
        $apps = Get-AppsByCategory -Category "internet"
        $apps | ForEach-Object {
            $global:APP_MAP[$_].Active | Should -Be $true
        }
    }
    It "retorna array vazio para categoria inexistente" {
        $apps = Get-AppsByCategory -Category "naoexiste"
        $apps.Count | Should -Be 0
    }
}

Describe "APP_NAMES_ORDERED" {
    It "mantém ordem de inserção" {
        $global:APP_NAMES_ORDERED.Count | Should -BeGreaterThan 0
    }
    It "primeiro app é Google Chrome" {
        $global:APP_NAMES_ORDERED[0] | Should -Be "Google Chrome"
    }
}
```

- [ ] **Step 2: Rodar — confirmar falha**

```powershell
Invoke-Pester -Path tests/lib/apps-data.Tests.ps1 -Output Detailed
```

Resultado esperado: erro `"apps-data.ps1 not found"`

- [ ] **Step 3: Implementar `lib/apps-data.ps1`**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/apps-data.ps1
# Versão: 1.0.0
# Objetivo: Banco de dados centralizado de aplicativos
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
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
Add-App -Active $true  -Category "internet" -Name "Google Chrome"   -Desc "Navegador Google Chrome"     -WingetId "Google.Chrome"                      -ChocoId "googlechrome"              -Method "winget"
Add-App -Active $true  -Category "internet" -Name "Mozilla Firefox"  -Desc "Navegador Mozilla Firefox"   -WingetId "Mozilla.Firefox"                    -ChocoId "firefox"                   -Method "winget"
Add-App -Active $true  -Category "internet" -Name "Brave Browser"    -Desc "Navegador Brave"              -WingetId "Brave.Brave"                        -ChocoId "brave"                     -Method "winget"
Add-App -Active $true  -Category "internet" -Name "Telegram"         -Desc "Mensageiro Telegram"          -WingetId "Telegram.TelegramDesktop"           -ChocoId "telegram"                  -Method "winget"
Add-App -Active $true  -Category "internet" -Name "Discord"          -Desc "Comunicação Discord"          -WingetId "Discord.Discord"                   -ChocoId "discord"                   -Method "winget"
Add-App -Active $true  -Category "internet" -Name "Zoom"             -Desc "Videoconferência Zoom"        -WingetId "Zoom.Zoom"                          -ChocoId "zoom"                      -Method "winget"

# =============================================================================
# DEV
# =============================================================================
Add-App -Active $true  -Category "dev"      -Name "VS Code"          -Desc "Editor Visual Studio Code"   -WingetId "Microsoft.VisualStudioCode"         -ChocoId "vscode"                    -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Git"              -Desc "Controle de versão Git"       -WingetId "Git.Git"                           -ChocoId "git"                       -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Node.js"          -Desc "Runtime Node.js LTS"          -WingetId "OpenJS.NodeJS.LTS"                 -ChocoId "nodejs-lts"                -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Python"           -Desc "Python 3"                     -WingetId "Python.Python.3"                   -ChocoId "python3"                   -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Docker Desktop"   -Desc "Docker Desktop para Windows"  -WingetId "Docker.DockerDesktop"              -ChocoId "docker-desktop"            -Method "winget"
Add-App -Active $true  -Category "dev"      -Name "Windows Terminal" -Desc "Terminal moderno do Windows"  -WingetId "Microsoft.WindowsTerminal"         -ChocoId "microsoft-windows-terminal" -Method "winget"
```

- [ ] **Step 4: Rodar testes — confirmar que passam**

```powershell
Invoke-Pester -Path tests/lib/apps-data.Tests.ps1 -Output Detailed
```

Resultado esperado: `Tests Passed: 8, Failed: 0`

- [ ] **Step 5: Commit**

```bash
git add lib/apps-data.ps1 tests/lib/apps-data.Tests.ps1
git commit -m "feat: implementa lib/apps-data.ps1 com banco de dados de apps (internet + dev)"
```

---

## Task 7: `lib/install-apps-internet.ps1`

**Files:**
- Criar: `lib/install-apps-internet.ps1`

- [ ] **Step 1: Implementar `lib/install-apps-internet.ps1`**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: lib/install-apps-internet.ps1
# Versão: 1.0.0
# Objetivo: Instalar apps de Internet (navegadores, comunicação, nuvem)
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# Execução standalone: $env:DRY_RUN=1; .\lib\install-apps-internet.ps1
# ==============================================================================

$BASE_DIR = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
. "$BASE_DIR\core\env.ps1"
. "$BASE_DIR\core\logging.ps1"
. "$BASE_DIR\core\package-mgr.ps1"
. "$BASE_DIR\lib\apps-data.ps1"

if ($global:DRY_RUN) { Log-Warn "Modo DRY-RUN ativado — nenhuma instalação será realizada." }

function Install-Apps-Internet {
    Log-Step "Instalando apps de Internet..."

    $apps = Get-AppsByCategory -Category "internet"

    if ($apps.Count -eq 0) {
        Log-Warn "Nenhum app ativo na categoria 'internet'."
        return
    }

    $ok = 0; $fail = 0
    foreach ($appName in $apps) {
        if (Install-App -AppName $appName) { $ok++ } else { $fail++ }
    }

    Log-Success "Internet: $ok instalados, $fail falhas."
}

Install-Apps-Internet
```

- [ ] **Step 2: Validar execução standalone em dry-run**

```powershell
$env:DRY_RUN=1; .\lib\install-apps-internet.ps1
```

Resultado esperado: linhas `[DRY-RUN] winget install --id Google.Chrome ...` para cada app, sem nenhuma instalação real.

- [ ] **Step 3: Verificar idempotência (rodar duas vezes)**

```powershell
$env:DRY_RUN=1; .\lib\install-apps-internet.ps1
$env:DRY_RUN=1; .\lib\install-apps-internet.ps1
```

Resultado esperado: segundo run sem erros.

- [ ] **Step 4: Commit**

```bash
git add lib/install-apps-internet.ps1
git commit -m "feat: implementa lib/install-apps-internet.ps1 (standalone, dry-run)"
```

---

## Task 8: `profiles/desenvolvedor.json` e `v3rtech-install.ps1` skeleton

**Files:**
- Criar: `profiles/desenvolvedor.json`
- Criar: `profiles/escritorio.json`
- Criar: `v3rtech-install.ps1`

- [ ] **Step 1: Criar perfis JSON**

Arquivo `profiles/desenvolvedor.json`:

```json
{
  "name": "desenvolvedor",
  "description": "Setup completo para desenvolvimento de software",
  "categories": ["internet", "dev", "system"],
  "apps_extra": ["Docker Desktop", "Windows Terminal"],
  "winfeatures": ["Microsoft-Windows-Subsystem-Linux", "VirtualMachinePlatform"],
  "system_tweaks": ["dev-path", "git-config"]
}
```

Arquivo `profiles/escritorio.json`:

```json
{
  "name": "escritorio",
  "description": "Setup para uso em escritório e produtividade",
  "categories": ["internet", "office", "system"],
  "apps_extra": [],
  "winfeatures": [],
  "system_tweaks": ["office-path"]
}
```

- [ ] **Step 2: Implementar `v3rtech-install.ps1` skeleton**

```powershell
#!/usr/bin/env pwsh
# ==============================================================================
# Script: v3rtech-install.ps1
# Versão: 1.0.0
# Objetivo: Orquestrador principal — wizard CLI de instalação
# Autor: V3RTECH Tecnologia, Consultoria e Inovação
# ==============================================================================

$BASE_DIR = Split-Path -Parent $PSCommandPath
. "$BASE_DIR\core\env.ps1"
. "$BASE_DIR\core\logging.ps1"
. "$BASE_DIR\core\package-mgr.ps1"
. "$BASE_DIR\lib\apps-data.ps1"

trap { Log-Error $_.Exception.Message; exit 1 }

if ($global:DRY_RUN) {
    Write-Host ""
    Write-Host "  [DRY-RUN] Modo simulação ativado — nenhuma alteração será feita." -ForegroundColor Yellow
    Write-Host ""
}

function Show-Header {
    Write-Host ""
    Write-Host "  ██╗   ██╗██████╗ ██████╗ ████████╗███████╗ ██████╗██╗  ██╗" -ForegroundColor Cyan
    Write-Host "  ██║   ██║╚════██╗██╔══██╗╚══██╔══╝██╔════╝██╔════╝██║  ██║" -ForegroundColor Cyan
    Write-Host "  ██║   ██║ █████╔╝██████╔╝   ██║   █████╗  ██║     ███████║" -ForegroundColor Cyan
    Write-Host "  ╚██╗ ██╔╝ ╚═══██╗██╔══██╗   ██║   ██╔══╝  ██║     ██╔══██║" -ForegroundColor Cyan
    Write-Host "   ╚████╔╝ ██████╔╝██║  ██║   ██║   ███████╗╚██████╗██║  ██║" -ForegroundColor Cyan
    Write-Host "    ╚═══╝  ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  v3rtech-scripts-win — Automação Windows 11" -ForegroundColor White
    Write-Host "  Versão 1.0.0 | PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Menu {
    Write-Host "  Selecione uma opção:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Instalar apps — Internet"   -ForegroundColor Cyan
    Write-Host "  [2] Instalar apps — Dev"         -ForegroundColor Cyan
    Write-Host "  [3] Instalar perfil completo"    -ForegroundColor Cyan
    Write-Host "  [0] Sair"                        -ForegroundColor DarkGray
    Write-Host ""
}

function Invoke-ProfileInstall {
    $profilesDir = Join-Path $BASE_DIR "profiles"
    $profileFiles = Get-ChildItem $profilesDir -Filter "*.json"

    Write-Host ""
    Write-Host "  Perfis disponíveis:" -ForegroundColor White
    $i = 1
    $profiles = @()
    foreach ($f in $profileFiles) {
        $p = Get-Content $f.FullName | ConvertFrom-Json
        Write-Host "  [$i] $($p.name) — $($p.description)" -ForegroundColor Cyan
        $profiles += $p
        $i++
    }
    Write-Host ""

    $choice = Read-Host "  Escolha o perfil"
    $idx = [int]$choice - 1
    if ($idx -lt 0 -or $idx -ge $profiles.Count) { Log-Warn "Opção inválida."; return }

    $selectedProfile = $profiles[$idx]
    Log-Step "Aplicando perfil: $($selectedProfile.name)"

    foreach ($category in $selectedProfile.categories) {
        $script = Join-Path $BASE_DIR "lib\install-apps-$category.ps1"
        if (Test-Path $script) {
            Log-Info "Categoria: $category"
            & $script
        } else {
            Log-Warn "Script para categoria '$category' não encontrado (será implementado no Plano 2)."
        }
    }
}

# ── MAIN ─────────────────────────────────────────────────────────────────────

Show-Header

# Detectar sistema na primeira execução
if (-not $global:CONFIG["windows_build"]) {
    . "$BASE_DIR\lib\detect-system.ps1"
}

do {
    Show-Menu
    $opt = Read-Host "  > "

    switch ($opt) {
        "1" { & "$BASE_DIR\lib\install-apps-internet.ps1" }
        "2" {
            Log-Warn "Categoria 'dev' será implementada no Plano 2."
        }
        "3" { Invoke-ProfileInstall }
        "0" { Log-Info "Saindo."; break }
        default { Log-Warn "Opção inválida." }
    }
} while ($opt -ne "0")
```

- [ ] **Step 3: Testar execução do wizard em dry-run**

```powershell
$env:DRY_RUN=1; .\v3rtech-install.ps1
```

Resultado esperado: banner ASCII aparece, menu é exibido, opção `1` mostra dry-run dos apps de internet, `0` sai sem erros.

- [ ] **Step 4: Commit**

```bash
git add profiles/ v3rtech-install.ps1
git commit -m "feat: wizard CLI skeleton com menu, perfis JSON e categoria internet end-to-end"
```

---

## Task 9: Suite de testes completa + instalação do Pester

**Files:**
- Criar: `tests/Run-Tests.ps1`

- [ ] **Step 1: Garantir que Pester 5.x está instalado**

```powershell
if (-not (Get-Module Pester -ListAvailable | Where-Object Version -ge "5.0")) {
    Install-Module Pester -Force -SkipPublisherCheck -Scope CurrentUser
}
```

Resultado esperado: Pester 5.x disponível em `Get-Module Pester -ListAvailable`

- [ ] **Step 2: Criar runner de testes**

Arquivo `tests/Run-Tests.ps1`:

```powershell
#!/usr/bin/env pwsh
# Runner central de testes — equivalente a `npm test`
$env:DRY_RUN = "1"
$env:VERBOSE  = "0"

$config = New-PesterConfiguration
$config.Run.Path          = "$PSScriptRoot"
$config.Output.Verbosity  = "Detailed"
$config.TestResult.Enabled       = $true
$config.TestResult.OutputPath    = "$PSScriptRoot\TestResults.xml"
$config.TestResult.OutputFormat  = "NUnitXml"

$result = Invoke-Pester -Configuration $config

if ($result.FailedCount -gt 0) {
    Write-Host "FALHOU: $($result.FailedCount) teste(s) falharam." -ForegroundColor Red
    exit 1
}
Write-Host "OK: $($result.PassedCount) testes passaram." -ForegroundColor Green
```

- [ ] **Step 3: Rodar suite completa**

```powershell
.\tests\Run-Tests.ps1
```

Resultado esperado:
```
Tests Passed: 24+, Failed: 0
OK: 24 testes passaram.
```

- [ ] **Step 4: Adicionar `TestResults.xml` ao `.gitignore`**

Adicionar ao `.gitignore`:
```
tests/TestResults.xml
```

- [ ] **Step 5: Commit final do Plano 1**

```bash
git add tests/Run-Tests.ps1 .gitignore
git commit -m "feat: suite de testes completa com runner central (Pester 5.x)"
git tag v1.0.0-foundation
```

---

## Validação Final do Plano 1

Após todos os tasks, executar esta checklist:

- [ ] `.\tests\Run-Tests.ps1` → `Failed: 0`
- [ ] `$env:DRY_RUN=1; .\v3rtech-install.ps1` → wizard exibe menu
- [ ] Selecionar opção `1` → loga dry-run para todos os apps de internet
- [ ] Selecionar opção `3` → lista perfis, selecionar `desenvolvedor` → roda internet (avisa que dev será no Plano 2)
- [ ] Selecionar opção `0` → sai sem erro
- [ ] `$env:DRY_RUN=1; .\lib\install-apps-internet.ps1` → standalone funciona
- [ ] Rodar wizard duas vezes → sem duplicações, sem erros

---

## Próximos Planos

- **Plano 2:** Todas as categorias de apps (dev, office, multimedia, design, system, games) + wizard completo com seleção múltipla + perfis completos
- **Plano 3:** `setup-system.ps1` (registro, PATH, políticas) + `setup-winfeatures.ps1` (WSL, Hyper-V) + `setup-appconfig.ps1` (pós-instalação de apps)
