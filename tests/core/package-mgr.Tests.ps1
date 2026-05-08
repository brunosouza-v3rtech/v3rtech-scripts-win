BeforeAll {
    $env:DRY_RUN = "1"   # todos os testes rodam em dry-run
    $script:root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:root "core" "env.ps1")
    . (Join-Path $script:root "core" "logging.ps1")
    . (Join-Path $script:root "core" "package-mgr.ps1")
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
        # Minimal stub — apps-data.ps1 não implementado ainda (Task 6)
        $global:APP_MAP = @{
            "Google Chrome" = @{
                Active   = $true
                Category = "internet"
                Name     = "Google Chrome"
                WingetId = "Google.Chrome"
                ChocoId  = "googlechrome"
                ScoopId  = ""
                Method   = "winget"
            }
        }
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
