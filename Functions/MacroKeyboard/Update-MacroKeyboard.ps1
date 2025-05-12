<#
.SYNOPSIS
Valida e envia a configuração para o teclado macro utilizando ch57x-keyboard-tool (https://github.com/kriomant/ch57x-keyboard-tool).

.DESCRIPTION
Executa a validação do arquivo de configuração YAML do teclado macro e, se válido, envia para o dispositivo. Permite edição caso inválido.

.PARAMETER Path
Caminho do executável ch57x-keyboard-tool.exe.

.PARAMETER ConfigFile
Caminho do arquivo YAML de configuração.

.EXAMPLE
Update-MacroKeyboard -Path "ch57x-keyboard-tool.exe" -ConfigFile "mapping.yaml"
#>
function Update-MacroKeyboard {
    [CmdletBinding()]
    param(
        [string]$Path = "ch57x-keyboard-tool.exe",
        [string]$ConfigFile = "mapping.yaml"
    )

    if (-not (Test-Path $Path)) {
        Write-Host "Erro: Executável não encontrado em $Path" -ForegroundColor Red
        return 1
    }

    if (-not (Test-Path $ConfigFile)) {
        Write-Host "Erro: Configuração não encontrada em $ConfigFile" -ForegroundColor Red
        $answer = Read-Host "Deseja abrir o diretório da configuração? (S/n)"
        if ($answer.ToUpper() -ne "N") {
            Start-Process explorer.exe -ArgumentList (Split-Path -Path $ConfigFile -Parent)
        }
        return 1
    }

    $env:MacroKeyboardPath = $Path
    [Environment]::SetEnvironmentVariable("MacroKeyboardPath", $Path, "User")

    $result = Invoke-MacroKeyboardToolCommand -Tool $Path -ConfigFile $ConfigFile -Command "validate"
    if ($result -eq 0) {
        Write-Host "✔ Configuração válida. Enviando..." -ForegroundColor Green
        $result = Invoke-MacroKeyboardToolCommand -Tool $Path -ConfigFile $ConfigFile -Command "upload"
        if ($result -eq 0) {
            Write-Host "✔ Upload realizado." -ForegroundColor Green
            $answer = Read-Host "Deseja testar o teclado? (S/n)"
            if ($answer.ToUpper() -ne "N") {
                try { & python -m keyboard } catch { Write-Host "Erro: python não encontrado." -ForegroundColor Red }
            }
        } else {
            Write-Host "✖ Falha no upload. Código: $result" -ForegroundColor Red
            Edit-MacroKeyboardConfig -Path $Path -ConfigFile $ConfigFile
        }
    } else {
        Write-Host "✖ Configuração inválida. Código: $result" -ForegroundColor Red
        Edit-MacroKeyboardConfig -Path $Path -ConfigFile $ConfigFile
    }
    return $result
}
