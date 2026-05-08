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

## Verbose (saída detalhada)

```powershell
$env:VERBOSE=1; .\v3rtech-install.ps1
```

## Auto-confirm (sem prompts)

```powershell
$env:AUTO_CONFIRM=1; .\v3rtech-install.ps1
```
