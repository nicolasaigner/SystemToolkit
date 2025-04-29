
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
        reg export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "$OutDir\SystemEnvironment.reg" /y
        reg export "HKCU\Environment" "$OutDir\UserEnvironment.reg" /y
        reg export "HKEY_USERS\.DEFAULT\Environment" "$OutDir\DefaultUserEnvironment.reg" /y

        $jsonOpts = @{Depth = 3; Compress = $false}
        Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' |
            Select-Object -ExcludeProperty PS* | ConvertTo-Json @jsonOpts |
            Set-Content "$OutDir\SystemEnvironment.json" -Encoding utf8
        Get-ItemProperty -Path 'HKCU:\Environment' |
            Select-Object -ExcludeProperty PS* | ConvertTo-Json @jsonOpts |
            Set-Content "$OutDir\UserEnvironment.json" -Encoding utf8
        Get-ItemProperty -Path 'Registry::HKEY_USERS\.DEFAULT\Environment' -ErrorAction SilentlyContinue |
            Select-Object -ExcludeProperty PS* | ConvertTo-Json @jsonOpts |
            Set-Content "$OutDir\DefaultUserEnvironment.json" -Encoding utf8
    }
}
