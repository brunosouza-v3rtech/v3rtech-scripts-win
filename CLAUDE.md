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
$BASE_DIR = Split-Path -Parent $PSScriptRoot
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
- Scripts: nomeação `action-target.ps1` (ex: `install-essentials.ps1`)

## Arquitetura esperada (paralela ao Linux)

```
v3rtech-install.ps1 (Orchestrator)
    ↓
lib/ (Installation & Configuration Scripts)
    ↓
core/ (Base Infrastructure: env.ps1, logging.ps1, package-mgr.ps1)
    ↓
Windows 11 Operating System
```

## Estrutura de diretórios

- **core/** - Infraestrutura base (variáveis, logging, gerenciamento pacotes)
- **lib/** - Scripts de instalação e configuração
- **profiles/** - Perfis de instalação pré-configurados
- **configs/** - Arquivos de configuração estáticos
- **utils/** - Scripts utilitários especializados
- **tests/** - Testes Pester (tests/core/ e tests/lib/)
- **dev-history/** - Documentação de desenvolvimento
- **docs/** - Documentação do projeto

## Princípios de design

1. **Idempotência**: Scripts podem ser re-executados sem efeitos colaterais
2. **Abstração de gerenciador pacotes**: Função `Install-Package` abstrai Winget/Chocolatey
3. **Configuração compartilhada**: `~/.config/v3rtech-scripts-win/config.json` para estado persistente
4. **Logging padronizado**: Sempre usar `Log-*`, com arquivo + console colorido
5. **Tratamento de erros**: Críticos com `Die`, não-críticos com `Log-Error` e continuação
