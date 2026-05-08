BeforeAll {
    $env:DRY_RUN = "0"; $env:VERBOSE = "0"
    $script:root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:root "core" "env.ps1")
    . (Join-Path $script:root "core" "logging.ps1")
}

Describe "Log-Info" {
    It "escreve [INFO] no terminal" {
        Mock Write-Host {}
        Mock Add-Content {}
        Log-Info "mensagem teste"
        Should -Invoke Write-Host -Times 1 -ParameterFilter { $Object -match "\[INFO\]" }
    }
    It "escreve no arquivo de log" {
        Mock Write-Host {}
        Mock Add-Content {}
        Log-Info "log file test"
        Should -Invoke Add-Content -Times 1 -ParameterFilter { $Path -eq $global:LOG_FILE }
    }
}

Describe "Log-Warn" {
    It "usa cor Yellow" {
        Mock Write-Host {}
        Mock Add-Content {}
        Log-Warn "aviso"
        Should -Invoke Write-Host -Times 1 -ParameterFilter {
            $Object -match "\[WARN\]" -and $ForegroundColor -eq "Yellow"
        }
    }
}

Describe "Log-Debug" {
    It "não escreve quando VERBOSE_MODE=false" {
        $global:VERBOSE_MODE = $false
        Mock Write-Host {}
        Log-Debug "debug msg"
        Should -Not -Invoke Write-Host
    }
    It "escreve quando VERBOSE_MODE=true" {
        $global:VERBOSE_MODE = $true
        Mock Write-Host {}
        Mock Add-Content {}
        Log-Debug "debug msg"
        Should -Invoke Write-Host -Times 1
        $global:VERBOSE_MODE = $false
    }
}

Describe "Log-Step" {
    It "usa cor Cyan" {
        Mock Write-Host {}
        Mock Add-Content {}
        Log-Step "passo"
        Should -Invoke Write-Host -Times 1 -ParameterFilter {
            $Object -match "\[STEP\]" -and $ForegroundColor -eq "Cyan"
        }
    }
}

Describe "Log-Error" {
    It "usa cor Red" {
        Mock Write-Host {}
        Mock Add-Content {}
        Log-Error "erro"
        Should -Invoke Write-Host -Times 1 -ParameterFilter {
            $Object -match "\[ERROR\]" -and $ForegroundColor -eq "Red"
        }
    }
}

Describe "Log-Success" {
    It "usa cor Green" {
        Mock Write-Host {}
        Mock Add-Content {}
        Log-Success "sucesso"
        Should -Invoke Write-Host -Times 1 -ParameterFilter {
            $Object -match "\[SUCCESS\]" -and $ForegroundColor -eq "Green"
        }
    }
}

Describe "Die" {
    It "lança exceção com a mensagem" {
        Mock Write-Log {}
        { Die "erro fatal" } | Should -Throw "erro fatal"
    }
    It "chama Log-Error antes de lançar a exceção" {
        Mock Write-Log {}
        try { Die "mensagem de erro" } catch {}
        Should -Invoke Write-Log -Times 1 -ParameterFilter { $Level -eq "ERROR" }
    }
}
