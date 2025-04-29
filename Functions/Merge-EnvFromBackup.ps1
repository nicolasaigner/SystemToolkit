
function Merge-EnvFromBackup {
<#
.SYNOPSIS
    Compara um backup JSON e aplica adições/alterações seletivas nas variáveis de ambiente.

.PARAMETER BackupDir
    Pasta contendo SystemEnvironment.json e UserEnvironment.json gerados pelo Export-EnvBackup.

.EXAMPLE
    Merge-EnvFromBackup -BackupDir D:\Backups\EnvBackup-20250428-235812
#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$BackupDir
    )

    $bkSysPath = Join-Path $BackupDir 'SystemEnvironment.json'
    $bkUsrPath = Join-Path $BackupDir 'UserEnvironment.json'
    if (!(Test-Path $bkSysPath) -or !(Test-Path $bkUsrPath)) {
        throw "BackupDir não contém os arquivos JSON necessários."
    }

    $bkSys = Get-Content $bkSysPath -Raw | ConvertFrom-Json
    $bkUsr = Get-Content $bkUsrPath -Raw | ConvertFrom-Json

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $rollbackDir = "EnvMergeRestore-$stamp"
    New-Item -ItemType Directory -Path $rollbackDir | Out-Null
    reg export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "$rollbackDir\System_before.reg" /y
    reg export "HKCU\Environment" "$rollbackDir\User_before.reg" /y

    function Merge-Scope {
        param(
            [string]$ScopeName,
            [psobject]$Backup,
            [string]$RegPath
        )
        $current = Get-ItemProperty -Path $RegPath | Select-Object -ExcludeProperty PS*
        foreach ($prop in $Backup.PSObject.Properties) {
            $name  = $prop.Name
            $value = $prop.Value
            if ($current.PSObject.Properties.Name -notcontains $name) {
                Write-Host "[$ScopeName] + $name" -ForegroundColor Green
                if ($PSCmdlet.ShouldProcess($name,"Add")) {
                    Set-ItemProperty -Path $RegPath -Name $name -Value $value -Force
                }
            }
            elseif ($current.$name -ne $value) {
                Write-Host "[$ScopeName] ~ $name" -ForegroundColor Yellow
                Write-Host "  Atual:  $($current.$name)"
                Write-Host "  Backup: $value"
                $ans = Read-Host 'Sobrescrever? (S/N)'
                if ($ans -match '^[sSyY]') {
                    if ($PSCmdlet.ShouldProcess($name,"Replace")) {
                        Set-ItemProperty -Path $RegPath -Name $name -Value $value -Force
                    }
                }
            }
        }
    }

    Merge-Scope 'SISTEMA' $bkSys 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
    Merge-Scope 'USUÁRIO' $bkUsr 'HKCU:\Environment'

    # Broadcast WM_SETTINGCHANGE
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class NativeMethods{
[DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
                                              uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
"@
    [NativeMethods]::SendMessageTimeout([intptr]0xFFFF,0x1A,[UIntPtr]::Zero,'Environment',2,1000,[ref]([UIntPtr]::Zero)) | Out-Null
}
