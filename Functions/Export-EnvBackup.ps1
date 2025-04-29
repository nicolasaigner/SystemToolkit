
function Export-EnvBackup {
<#
.SYNOPSIS
    Faz dump completo das variáveis de ambiente (Sistema, Usuário e Perfil Default).

.DESCRIPTION
    Cria pasta timestampada, exporta três chaves do Registro para .reg e
    também gera .json para comparação.

.PARAMETER OutDir
    Diretório onde salvar o backup.  Default: EnvBackup-<timestamp> no PWD.

.EXAMPLE
    Export-EnvBackup -OutDir D:\Backups
#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$OutDir = (Join-Path $PWD ("EnvBackup-{0:yyyyMMdd-HHmmss}" -f (Get-Date)))
    )

    if ($PSCmdlet.ShouldProcess('Environment', "Export to $OutDir")) {
        New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

        reg.exe export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "$OutDir\SystemEnvironment.reg" /y
        reg.exe export "HKCU\Environment"                         "$OutDir\UserEnvironment.reg" /y
        reg.exe export "HKEY_USERS\.DEFAULT\Environment"          "$OutDir\DefaultUserEnvironment.reg" /y

        $jsonOpts = @{Depth = 3; Compress = $false}

        Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' |
            Select-Object -ExcludeProperty PS* |
            ConvertTo-Json @jsonOpts | Set-Content -Encoding UTF8 "$OutDir\SystemEnvironment.json"

        Get-ItemProperty -Path 'HKCU:\Environment' |
            Select-Object -ExcludeProperty PS* |
            ConvertTo-Json @jsonOpts | Set-Content -Encoding UTF8 "$OutDir\UserEnvironment.json"

        Get-ItemProperty -Path 'Registry::HKEY_USERS\.DEFAULT\Environment' -ErrorAction SilentlyContinue |
            Select-Object -ExcludeProperty PS* |
            ConvertTo-Json @jsonOpts | Set-Content -Encoding UTF8 "$OutDir\DefaultUserEnvironment.json"

        Write-Output $OutDir
    }
}
