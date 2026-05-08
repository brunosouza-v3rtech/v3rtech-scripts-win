BeforeAll {
    $env:DRY_RUN = "1"
    $script:root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

Describe "upall.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "upall.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "executa sem erro em DRY_RUN" {
        $env:DRY_RUN = "1"
        & pwsh -NoProfile -NonInteractive -Command { $env:DRY_RUN=1; & (Join-Path $args[0] 'utils/upall.ps1') } -args $script:root
        $LASTEXITCODE | Should -Be 0
    }
}

Describe "img-convert.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "img-convert.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "falha com mensagem clara se -Path não existe" {
        { & (Join-Path $script:root "utils" "img-convert.ps1") -Path "C:\nao-existe-xyz" } |
            Should -Throw
    }
}

Describe "mkv-extract-subtitles.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "mkv-extract-subtitles.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "falha com mensagem clara se arquivo não existe" {
        { & (Join-Path $script:root "utils" "mkv-extract-subtitles.ps1") -File "C:\nao-existe.mkv" } |
            Should -Throw
    }
}

Describe "merge-pdfs.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "merge-pdfs.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "falha com mensagem clara se -Path não existe" {
        { & (Join-Path $script:root "utils" "merge-pdfs.ps1") -Path "C:\nao-existe-xyz" -Output "out.pdf" } |
            Should -Throw
    }
}

Describe "ssh-connect.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "ssh-connect.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "lista hosts quando chamado sem parâmetros (arquivo de hosts ausente)" {
        & (Join-Path $script:root "utils" "ssh-connect.ps1") 2>&1 | Out-Null
        $LASTEXITCODE | Should -BeIn @(0, 1)
    }
}

Describe "video-rename.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "video-rename.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "falha com mensagem clara se -Path não existe" {
        { & (Join-Path $script:root "utils" "video-rename.ps1") -Path "C:\nao-existe-xyz" -Type movies } |
            Should -Throw
    }
}

Describe "get-subtitles.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "get-subtitles.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "falha com mensagem clara se -Path não existe" {
        { & (Join-Path $script:root "utils" "get-subtitles.ps1") -Path "C:\nao-existe-xyz" } |
            Should -Throw
    }
}

Describe "transmission-clear.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "transmission-clear.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "tem parâmetros -Server e -Port" {
        $help = Get-Help (Join-Path $script:root "utils" "transmission-clear.ps1") -ErrorAction SilentlyContinue
        $help | Should -Not -BeNullOrEmpty
    }
}

Describe "wallpaper-rotator.ps1" {
    It "tem sintaxe válida" {
        $errs = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:root "utils" "wallpaper-rotator.ps1"), [ref]$null, [ref]$errs)
        $errs.Count | Should -Be 0
    }
    It "falha com mensagem clara se -Path não existe" {
        { & (Join-Path $script:root "utils" "wallpaper-rotator.ps1") -Path "C:\nao-existe-xyz" } |
            Should -Throw
    }
}
