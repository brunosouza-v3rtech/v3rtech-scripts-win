BeforeAll {
    $env:DRY_RUN = "1"
    $script:root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:root "core" "env.ps1")
    . (Join-Path $script:root "core" "logging.ps1")
    . (Join-Path $script:root "core" "package-mgr.ps1")
    . (Join-Path $script:root "lib" "apps-data.ps1")
}

Describe "Add-App / APP_MAP" {
    It "registra app no APP_MAP" {
        $global:APP_MAP.Contains("Google Chrome") | Should -Be $true
    }
    It "app tem WingetId preenchido" {
        $global:APP_MAP["Google Chrome"].WingetId | Should -Not -BeNullOrEmpty
    }
    It "app tem Category preenchida" {
        $global:APP_MAP["Google Chrome"].Category | Should -Be "internet"
    }
    It "app tem todos os campos obrigatórios" {
        $app = $global:APP_MAP["Google Chrome"]
        $app.Active   | Should -Not -BeNullOrEmpty
        $app.Name     | Should -Be "Google Chrome"
        $app.Desc     | Should -Not -BeNullOrEmpty
        $app.Method   | Should -Be "winget"
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
    It "retorna apps da categoria dev" {
        $apps = Get-AppsByCategory -Category "dev"
        $apps.Count | Should -BeGreaterThan 0
    }
}

Describe "APP_NAMES_ORDERED" {
    It "mantém ordem de inserção" {
        $global:APP_NAMES_ORDERED.Count | Should -BeGreaterThan 0
    }
    It "primeiro app é Google Chrome" {
        $global:APP_NAMES_ORDERED[0] | Should -Be "Google Chrome"
    }
    It "todos os apps no APP_MAP estão na lista ordenada" {
        foreach ($name in $global:APP_MAP.Keys) {
            $global:APP_NAMES_ORDERED | Should -Contain $name
        }
    }
}
