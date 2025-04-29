
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
        [ValidateSet('Key','Value','Data')]
        [string]$MatchFields = 'Data',
        [string]$OutputDir = (Join-Path $PWD 'RegistryExport'),
        [string]$Prefix,
        [string]$Suffix
    )

    if (!(Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $fileBase  = '{0}{1}{2}_{3}.reg' -f `
        ($Prefix ?? ''), ($Prefix? '_':''), ($Suffix? ($Suffix+'_'):'') , $timestamp
    $filePath  = Join-Path $OutputDir $fileBase

    foreach ($root in $TargetRoots) {
        # usa reg query com /s pra percorrer
        $lines = & reg.exe query $root /s 2>$null
        foreach ($line in $lines) {
            $match = switch ($MatchFields) {
                'Key'   { ($Filters | Where-Object { $line -like \"*$_*\" }).Count -gt 0 }
                default { ($Filters | Where-Object { $line -like \"*$_*\" }).Count -gt 0 }
            }
            if ($match) {
                $line | Out-File -Append -FilePath $filePath -Encoding Unicode
            }
        }
    }
    Write-Output $filePath
}
