<#
.SYNOPSIS
Abre o arquivo de configuração do teclado macro para edição.

.DESCRIPTION
Permite ao usuário abrir e editar o arquivo de configuração YAML no Visual Studio Code ou Notepad.

.PARAMETER Path
Caminho do executável ch57x-keyboard-tool.exe.

.PARAMETER ConfigFile
Caminho do arquivo YAML de configuração.

.EXAMPLE
Edit-MacroKeyboardConfig -Path "ch57x-keyboard-tool.exe" -ConfigFile "mapping.yaml"
#>
function Edit-MacroKeyboardConfig {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$ConfigFile
    )

    $answer = Read-Host "Deseja editar o arquivo $ConfigFile? (S/n)"
    if ($answer.ToUpper() -eq "N") { return }

    $editor = if (Get-Command code -ErrorAction SilentlyContinue) { "code" } else { "notepad" }
    & $editor $ConfigFile

    Start-Sleep -Seconds 1
    $processName = if ($editor -eq "notepad") { "notepad" } else { "Code" }
    Wait-Process -Name $processName

    $result = Invoke-MacroKeyboardToolCommand -Tool $Path -ConfigFile $ConfigFile -Command "validate"
    if ($result -eq 0) {
        Write-Host "✔ Configuração corrigida. Enviando..." -ForegroundColor Green
        Invoke-MacroKeyboardToolCommand -Tool $Path -ConfigFile $ConfigFile -Command "upload"
    } else {
        Write-Host "✖ Ainda inválida. Código: $result" -ForegroundColor Red
    }
}
