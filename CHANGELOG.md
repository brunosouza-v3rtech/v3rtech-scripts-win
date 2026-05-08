# Changelog

All notable changes to this project will be documented in this file.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) | Versioning: [SemVer](https://semver.org/)

## [Unreleased]

### Added
- core/env.ps1: variáveis globais, config JSON persistente, flags de execução (DRY_RUN, VERBOSE, AUTO_CONFIRM)
- core/logging.ps1: logging colorizado (STEP/INFO/WARN/ERROR/SUCCESS/DEBUG) com saída simultânea para terminal e arquivo
- core/package-mgr.ps1: abstração winget/choco/scoop com Install-App, Get-InstallOrder, Bootstrap automático
- lib/detect-system.ps1: detecção de Windows version, GPU, arquitetura, sessão, privilégios de administrador
- lib/apps-data.ps1: banco de dados de apps com Add-App/Get-AppsByCategory (categorias: internet, dev)
- Project scaffold: estrutura de diretórios completa
- `.gitkeep` em diretórios vazios para preservar estrutura no git clone
- `.gitignore` com padrões para logs, temporários, IDEs e Windows
- README.md com pré-requisitos e instruções de instalação
- CLAUDE.md com guias de desenvolvimento e arquitetura
