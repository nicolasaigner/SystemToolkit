<#
.SYNOPSIS
Executa o comando ch57x-keyboard-tool para o teclado macro.

.DESCRIPTION
Executa o binário ch57x-keyboard-tool com os argumentos de comando e arquivo de configuração.

.PARAMETER Tool
Caminho completo para o ch57x-keyboard-tool.exe.

.PARAMETER ConfigFile
Caminho do arquivo YAML de configuração.

.PARAMETER Command
Comando a ser executado (ex: upload, validate).

.EXAMPLE
Invoke-MacroKeyboardToolCommand -Tool "ch57x-keyboard-tool.exe" -ConfigFile "mapping.yaml" -Command "upload"
#>
function Invoke-MacroKeyboardToolCommand {
    [CmdletBinding()]
    param(
        [string]$Tool,
        [string]$ConfigFile,
        [string]$Command = "upload"
    )

    if (-not (Test-Path $Tool)) {
        Write-Host "Erro: Executável não encontrado em $Tool" -ForegroundColor Red
        return 1
    }
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "Erro: Configuração não encontrada em $ConfigFile" -ForegroundColor Red
        return 1
    }

    try {
        & $Tool $Command $ConfigFile
        return $LASTEXITCODE
    } catch {
        Write-Host "Erro ao executar comando." -ForegroundColor Red
        return 1
    }
}
