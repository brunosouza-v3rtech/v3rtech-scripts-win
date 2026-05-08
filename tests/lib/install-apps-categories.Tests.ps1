BeforeAll {
    $env:DRY_RUN = "1"
    $script:root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:root "core" "env.ps1")
    . (Join-Path $script:root "core" "logging.ps1")
    . (Join-Path $script:root "core" "package-mgr.ps1")
    $global:APP_MAP           = $null
    $global:APP_NAMES_ORDERED = $null
    . (Join-Path $script:root "lib" "apps-data.ps1")
}

Describe "Categoria dev" {
    It "tem apps registrados" {
        (Get-AppsByCategory "dev").Count | Should -BeGreaterThan 0
    }
    It "todos têm WingetId preenchido" {
        Get-AppsByCategory "dev" | ForEach-Object {
            $global:APP_MAP[$_].WingetId | Should -Not -BeNullOrEmpty
        }
    }
    It "primeiro app é VS Code" {
        (Get-AppsByCategory "dev")[0] | Should -Be "VS Code"
    }
}

Describe "Categoria office" {
    It "tem apps registrados" {
        (Get-AppsByCategory "office").Count | Should -BeGreaterThan 0
    }
    It "todos têm WingetId preenchido" {
        Get-AppsByCategory "office" | ForEach-Object {
            $global:APP_MAP[$_].WingetId | Should -Not -BeNullOrEmpty
        }
    }
    It "primeiro app é LibreOffice" {
        (Get-AppsByCategory "office")[0] | Should -Be "LibreOffice"
    }
}

Describe "Categoria multimedia" {
    It "tem apps registrados" {
        (Get-AppsByCategory "multimedia").Count | Should -BeGreaterThan 0
    }
    It "todos têm WingetId preenchido" {
        Get-AppsByCategory "multimedia" | ForEach-Object {
            $global:APP_MAP[$_].WingetId | Should -Not -BeNullOrEmpty
        }
    }
    It "primeiro app é VLC" {
        (Get-AppsByCategory "multimedia")[0] | Should -Be "VLC"
    }
}

Describe "Categoria design" {
    It "tem apps registrados" {
        (Get-AppsByCategory "design").Count | Should -BeGreaterThan 0
    }
    It "todos têm WingetId preenchido" {
        Get-AppsByCategory "design" | ForEach-Object {
            $global:APP_MAP[$_].WingetId | Should -Not -BeNullOrEmpty
        }
    }
    It "primeiro app é Figma" {
        (Get-AppsByCategory "design")[0] | Should -Be "Figma"
    }
}

Describe "Categoria system" {
    It "tem apps registrados" {
        (Get-AppsByCategory "system").Count | Should -BeGreaterThan 0
    }
    It "todos têm WingetId preenchido" {
        Get-AppsByCategory "system" | ForEach-Object {
            $global:APP_MAP[$_].WingetId | Should -Not -BeNullOrEmpty
        }
    }
    It "primeiro app é 7-Zip" {
        (Get-AppsByCategory "system")[0] | Should -Be "7-Zip"
    }
}

Describe "Categoria games" {
    It "tem apps registrados" {
        (Get-AppsByCategory "games").Count | Should -BeGreaterThan 0
    }
    It "todos têm WingetId preenchido" {
        Get-AppsByCategory "games" | ForEach-Object {
            $global:APP_MAP[$_].WingetId | Should -Not -BeNullOrEmpty
        }
    }
    It "primeiro app é Steam" {
        (Get-AppsByCategory "games")[0] | Should -Be "Steam"
    }
}

Describe "APP_MAP total" {
    It "tem pelo menos 50 apps registrados" {
        $global:APP_MAP.Count | Should -BeGreaterOrEqual 50
    }
    It "nenhum app com WingetId definido tem valor vazio" {
        foreach ($name in $global:APP_MAP.Keys) {
            $app = $global:APP_MAP[$name]
            if ($app.Method -eq "winget") {
                $app.WingetId | Should -Not -BeNullOrEmpty -Because "$name usa winget mas tem WingetId vazio"
            }
        }
    }
}
