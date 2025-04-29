
Describe 'Export-EnvBackup' {
    It 'Gera pasta e arquivos' {
        $tmp = Join-Path $env:TEMP ([Guid]::NewGuid())
        Export-EnvBackup -OutDir $tmp | Out-Null
        (Test-Path $tmp) | Should -BeTrue
        (Get-ChildItem $tmp | Measure-Object).Count | Should -BeGreaterThan 0
        Remove-Item $tmp -Recurse -Force
    }
}
