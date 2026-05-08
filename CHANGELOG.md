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
- apps-data.ps1: 40+ apps em 7 categorias (internet, dev, office, multimedia, design, system, games)
- profiles/criador-conteudo.json: perfil para criadores de conteúdo
- profiles/domestico.json: perfil para uso doméstico
- v3rtech-install.ps1: wizard completo com submenu de categorias e seleção por perfil
- tests/lib/install-apps-categories.Tests.ps1: 20 testes de dados para todas as categorias

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
