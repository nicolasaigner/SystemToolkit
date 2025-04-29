
function Export-RegistrySelection {
<#
.SYNOPSIS
    Exporta entradas do Registro cujo Nome, Valor ou Dados contenham texto específico.

.PARAMETER TargetRoots
    Raízes a varrer (HKLM, HKCU, ...)

.PARAMETER Filters
    Texto ou array de textos a localizar.

.PARAMETER MatchFields
    Qual campo verificar: Key, Value ou Data.

.PARAMETER OutputDir
    Pasta onde salvar o .reg.

.PARAMETER Prefix / Suffix
    Prefixo/sufixo para o nome do arquivo.

.EXAMPLE
    Export-RegistrySelection -Filters "Open with" -MatchFields Value
#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('HKEY_LOCAL_MACHINE','HKEY_CURRENT_USER','HKEY_CLASSES_ROOT','HKEY_USERS','HKEY_CURRENT_CONFIG')]
        [string[]]$TargetRoots = @('HKEY_LOCAL_MACHINE','HKEY_CURRENT_USER'),
        [string[]]$Filters = @('Open with','Edit with'),
        [ValidateSet('Key','Value','Data')][string]$MatchFields = 'Data',
        [string]$OutputDir = (Join-Path $PWD 'RegistryExport'),
        [string]$Prefix,
        [string]$Suffix
    )

    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $parts = @()
    if ($Prefix) { $parts += $Prefix }
    if ($Suffix) { $parts += $Suffix }
    $parts += $timestamp
    $filePath = Join-Path $OutputDir (($parts -join '_') + '.reg')

    foreach ($root in $TargetRoots) {
        $lines = reg query $root /s 2>$null
        foreach ($line in $lines) {
            $isMatch = switch ($MatchFields) {
                'Key'   { $Filters | Where-Object { $line -like "*$_*" } }
                default { $Filters | Where-Object { $line -like "*$_*" } }
            }
            if ($isMatch) { $line | Out-File -Append $filePath -Encoding Unicode }
        }
    }
    Write-Output $filePath
}
