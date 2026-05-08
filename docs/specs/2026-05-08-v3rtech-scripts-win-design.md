# Design Spec — v3rtech-scripts-win

**Data:** 2026-05-08
**Status:** Aprovado
**Autor:** Bruno Souza (V3RTECH) + Claude

---

## Visão Geral

Novo projeto independente (`v3rtech-scripts-win`) com a mesma filosofia do
`v3rtech-scripts` Linux, desenhado nativamente para Windows 11. Não é uma
porta direta — é um projeto paralelo que espelha a arquitetura e os padrões
do projeto Linux, usando as ferramentas nativas do Windows.

**Tecnologia:** PowerShell 7+
**Repositório:** `v3rtech-scripts-win` (GitHub, separado do projeto Linux)
**Versionamento:** Semver independente, começa em v1.0.0

---

## Escopo

### Inclui
- Instalação de apps por categoria e perfil (winget / choco / scoop)
- Configuração de sistema (PATH, registro, variáveis de ambiente, políticas UAC)
- Habilitação de Windows Features (WSL, Hyper-V, .NET, IIS via DISM)
- Configuração pós-instalação de apps (VS Code extensions, Git, terminal, WSL)
- Wizard interativo CLI com seleção de categorias e perfis
- Modo dry-run, verbose e auto-confirm (mesmas flags do Linux)
- Logging colorizado + arquivo de log

### Não inclui (sem equivalente no Windows)
- Plymouth / bootloader (GRUB, systemd-boot)
- sysctl / ajustes de kernel Linux
- Flatpak / Snap
- Desktop environments (KDE, GNOME, etc.)
- fstab (substituído por drives mapeados via PowerShell)

---

## Arquitetura

### Estrutura de diretórios

```
v3rtech-scripts-win/
├── v3rtech-install.ps1          # Orquestrador / ponto de entrada
├── core/
│   ├── env.ps1                  # Variáveis globais, detecção de ambiente, config
│   ├── logging.ps1              # Log colorizado + arquivo
│   └── package-mgr.ps1          # Abstração winget / choco / scoop
├── lib/
│   ├── detect-system.ps1        # Windows version, GPU, arquitetura, sessão
│   ├── apps-data.ps1            # Banco de dados central de apps
│   ├── install-apps-internet.ps1
│   ├── install-apps-dev.ps1
│   ├── install-apps-office.ps1
│   ├── install-apps-multimedia.ps1
│   ├── install-apps-design.ps1
│   ├── install-apps-system.ps1
│   ├── install-apps-games.ps1
│   ├── setup-system.ps1         # PATH, variáveis de ambiente, registro, políticas
│   ├── setup-winfeatures.ps1    # WSL, Hyper-V, .NET, IIS via DISM
│   ├── setup-appconfig.ps1      # Pós-instalação de apps
│   └── cleanup.ps1
├── profiles/
│   ├── desenvolvedor.json
│   ├── escritorio.json
│   ├── criador-conteudo.json
│   └── domestico.json
├── configs/                     # Configs estáticas (dotfiles Windows)
├── utils/                       # Scripts utilitários standalone
├── dev-history/
├── docs/
├── README.md
├── CHANGELOG.md
└── CLAUDE.md
```

### Camadas

```
v3rtech-install.ps1 (Orquestrador)
    ↓
lib/ (Scripts de instalação e configuração)
    ↓
core/ (Infraestrutura base: env.ps1, logging.ps1, package-mgr.ps1)
    ↓
Windows 11 (winget / choco / scoop / DISM / Registro)
```

---

## Sequência de Inicialização

Todo script segue esta ordem obrigatória:

```powershell
$BASE_DIR = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

. "$BASE_DIR\core\env.ps1"
. "$BASE_DIR\core\logging.ps1"
. "$BASE_DIR\core\package-mgr.ps1"

# Opcional, se o script precisar de informações do sistema
. "$BASE_DIR\lib\detect-system.ps1"
```

---

## Configuração Persistente

Arquivo: `~/.config/v3rtech-scripts-win/config.json`

```json
{
  "distro_name": "Windows 11",
  "windows_build": "26100",
  "gpu_vendor": "nvidia",
  "prefer_winget": true,
  "install_categories": ["internet", "dev", "office"],
  "last_update": "2026-05-08T14:00:00"
}
```

O `env.ps1` carrega e expõe as chaves como variáveis globais (`$global:PREFER_WINGET`,
etc.). A função `Save-Config` persiste alterações — equivalente ao `save_config()` do Linux.

---

## Flags de Execução

| Flag (variável de ambiente) | Comportamento |
|---|---|
| `$env:DRY_RUN=1` | Simula todas as operações sem executar |
| `$env:VERBOSE=1` | Saída detalhada (habilita Log-Debug) |
| `$env:AUTO_CONFIRM=1` | Responde "sim" a todos os prompts automaticamente |

Todos os scripts respeitam `$ErrorActionPreference = "Stop"` definido em `env.ps1`
(equivalente ao `set -euo pipefail` do bash).

---

## Camada de Package Manager (`package-mgr.ps1`)

### Prioridade de instalação

```
winget (padrão) → chocolatey → scoop → manual (URL)
```

Configurável via `prefer_winget` no config. Cada app pode ter um método
preferido explícito no banco de dados.

### Banco de dados de apps (`apps-data.ps1`)

```powershell
Add-App -Active $true `
        -Category "internet" `
        -Name "Google Chrome" `
        -Desc "Navegador Google Chrome" `
        -WingetId "Google.Chrome" `
        -ChocoId "googlechrome" `
        -ScoopId "" `
        -Method "winget"
```

Quando um ID está vazio, aquele método é automaticamente ignorado.

### Função central `Install-App`

```powershell
function Install-App {
    param([string]$AppName)
    # Verifica se já instalado (idempotência)
    # Tenta métodos em ordem de preferência
    # Loga sucesso ou falha por método
}
```

### Bootstrap automático

`package-mgr.ps1` verifica e instala winget/choco/scoop conforme necessário
antes de qualquer operação. Bootstrap é idempotente.

### Funções auxiliares

| Função | Equivalente Linux | Descrição |
|---|---|---|
| `Install-App "nome"` | `i "package"` | Instala pelo melhor método |
| `Test-AppInstalled "nome"` | `command -v` | Verifica se já está instalado |
| `Update-AllApps` | — | Atualiza tudo (winget/choco/scoop upgrade) |

---

## Camada de Instalação de Apps (`lib/install-apps-*.ps1`)

Cada script de categoria é **independente e executável standalone**:

```powershell
# Roda direto
.\lib\install-apps-dev.ps1

# Com dry-run
$env:DRY_RUN=1; .\lib\install-apps-dev.ps1
```

### Categorias

| Categoria | Exemplos de apps |
|---|---|
| internet | Chrome, Firefox, Brave, Telegram, Zoom |
| dev | VS Code, Git, Node.js, Python, Docker Desktop |
| office | LibreOffice, Notion, PDF24 |
| multimedia | VLC, Spotify, OBS, Audacity |
| design | Figma, GIMP, Inkscape |
| system | 7-Zip, Everything, PowerToys, Ventoy |
| games | Steam, Epic Games, GOG Galaxy |

---

## Perfis de Usuário

Perfis em JSON, espelho dos `.conf` do Linux:

```json
{
  "name": "desenvolvedor",
  "description": "Setup completo para desenvolvimento de software",
  "categories": ["internet", "dev", "system"],
  "apps_extra": ["Docker Desktop", "Windows Terminal", "WSL"],
  "winfeatures": ["Microsoft-Windows-Subsystem-Linux", "VirtualMachinePlatform"],
  "system_tweaks": ["dev-path", "git-config", "wsl-default"]
}
```

O orquestrador lê o perfil e executa apps + features + tweaks em sequência.

---

## Configuração de Sistema (`setup-system.ps1`)

Equivalências Linux → Windows:

| Linux | Windows |
|---|---|
| `/etc/bash.bashrc` PATH | Variável PATH em HKLM (sistema) ou HKCU (usuário) |
| `sysctl` tweaks | Registro: power plan, prefetch, paginação |
| Privacidade/telemetria | Registro HKLM/HKCU: telemetria, Cortana, anúncios |
| `sudoers` | Políticas UAC via registro |
| `fstab` mounts | `New-PSDrive` persistente para drives de rede |
| aliases globais | `$PROFILE` PowerShell com aliases e funções |
| grupos do usuário | `Add-LocalGroupMember` (ex: docker-users) |

Todos os blocos de registro usam verificação antes de escrita — só altera se o
valor atual for diferente do esperado (idempotência).

---

## Windows Features (`setup-winfeatures.ps1`)

Habilita/desabilita features via `Enable-WindowsOptionalFeature` (DISM):

- WSL 2 + distro padrão
- Hyper-V (com verificação de suporte de hardware)
- .NET Framework / .NET Runtime
- IIS (para perfil de desenvolvedor web)

`$RESTART_REQUIRED` global acumula flags de reboot. O orquestrador avisa ao
final se reinicialização é necessária.

---

## Configuração de Apps (`setup-appconfig.ps1`)

| App | Config aplicada |
|---|---|
| VS Code | Extensões via `code --install-extension`, copia `configs/vscode-settings.json` |
| Windows Terminal | Copia `configs/terminal-settings.json` com perfis pré-configurados |
| Git | `user.name`, `user.email`, `core.autocrlf`, `credential.helper` |
| PowerShell | Módulos PSReadLine, posh-git; configura `$PROFILE` |
| WSL | Distro padrão, `.wslconfig` com limites de memória/CPU |
| Docker Desktop | Backend WSL2, recursos de CPU/memória |

Cada bloco verifica se o app está instalado antes de rodar — pula sem erro se não estiver.

---

## Logging (`logging.ps1`)

```powershell
Log-Step   "Configurando PATH global..."
Log-Info   "Adicionando variável ao PATH..."
Log-Warn   "Winget não encontrado, tentando choco..."
Log-Error  "Falha ao instalar '$app'."
Log-Success "VS Code instalado com sucesso."
Log-Debug  "App map tem $n entradas."  # só se VERBOSE=1
```

Saída simultânea: terminal (colorizado via `Write-Host`) + arquivo
`~/.config/v3rtech-scripts-win/logs/v3rtech-install.log` com timestamp.

Erros críticos:

```powershell
function Die { param([string]$Msg) Log-Error $Msg; exit 1 }
```

---

## Elevação de Privilégios

O orquestrador detecta no início se está rodando como Administrador. Se não
estiver e a operação exigir, oferece auto-relaunch com UAC. Operações que não
precisam de elevação (instalação de apps via winget em userspace, config de
HKCU) rodam sem UAC.

---

## Testes

| Método | Como usar |
|---|---|
| Verificação de sintaxe | `powershell -NoProfile -NonInteractive -File script.ps1` |
| Dry-run | `$env:DRY_RUN=1` — todas as operações apenas logam |
| Windows Sandbox | Ambiente descartável nativo do Win 11 Pro |
| Idempotência | Rodar o script duas vezes sem erros nem duplicações |

---

## Distribuição

```powershell
# Execução direta sem clonar
irm https://raw.githubusercontent.com/v3rtech/v3rtech-scripts-win/main/v3rtech-install.ps1 | iex
```

**Pré-requisito:** PowerShell 7+ (já incluso no Windows 11 ou instalável via
winget). Nenhuma outra dependência antes da primeira execução.

**Política de execução** (uma vez por máquina):

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Decisões de Design

| Decisão | Alternativa descartada | Motivo |
|---|---|---|
| Projeto separado | Monorepo | Zero acoplamento, versionamento independente |
| PowerShell 7+ | Python, batch | Nativo, acesso total ao SO, mesma filosofia do bash |
| Config em JSON | `.conf` sourced | JSON é mais seguro (sem execução implícita), portável |
| winget como padrão | Chocolatey | Nativo Win 11, sem instalação prévia |
| Abstração 3 pkg managers | Só winget | Mesma filosofia do projeto Linux (apt/pacman/dnf) |
| Windows Sandbox para testes | Docker | Nativo, descartável, sem overhead de container |
