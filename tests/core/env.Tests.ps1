BeforeAll {
    $env:DRY_RUN      = "0"
    $env:VERBOSE      = "0"
    $env:AUTO_CONFIRM = "0"

    # PSScriptRoot = tests/core/ → go up twice to reach project root
    $script:root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:root "core" "env.ps1")
}

Describe "env.ps1 — variáveis globais" {
    It "define BASE_DIR como raiz do projeto" {
        $global:BASE_DIR | Should -Not -BeNullOrEmpty
        Test-Path $global:BASE_DIR | Should -Be $true
    }

    It "define CONFIG_DIR dentro do perfil do usuário" {
        # Resolve home cross-platform (Windows: USERPROFILE, Linux/macOS: HOME)
        $homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
        $escapedHome = [regex]::Escape($homeDir)
        $global:CONFIG_DIR | Should -Match $escapedHome
    }

    It "define LOG_FILE dentro de CONFIG_DIR" {
        $escapedConfigDir = [regex]::Escape($global:CONFIG_DIR)
        $global:LOG_FILE | Should -Match $escapedConfigDir
    }

    It "DRY_RUN é false quando env:DRY_RUN=0" {
        $global:DRY_RUN | Should -Be $false
    }

    It "DRY_RUN é true quando env:DRY_RUN=1" {
        $env:DRY_RUN = "1"
        . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "core" "env.ps1")
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
