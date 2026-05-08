# v3rtech-scripts-win

Automação e configuração de sistema Windows 11.
Versão: 1.0.0 | PowerShell 7+

## Pré-requisitos

- **Windows 11** (22H2 ou superior)
- **PowerShell 7+** — o Windows 11 vem com PS 5.1 por padrão; instale o PS 7+ via winget:
  ```powershell
  winget install Microsoft.PowerShell
  ```
- **Política de execução** (uma vez por máquina):
  ```powershell
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

## Instalação rápida (sem clonar)

```powershell
irm https://raw.githubusercontent.com/v3rtech/v3rtech-scripts-win/main/v3rtech-install.ps1 | iex
```

## Uso rápido (clone local)

```powershell
.\v3rtech-install.ps1
```

## Dry-run (simula sem executar)

```powershell
$env:DRY_RUN=1; .\v3rtech-install.ps1
```

## Verbose (saída detalhada)

```powershell
$env:VERBOSE=1; .\v3rtech-install.ps1
```

## Auto-confirm (sem prompts)

```powershell
$env:AUTO_CONFIRM=1; .\v3rtech-install.ps1
```
