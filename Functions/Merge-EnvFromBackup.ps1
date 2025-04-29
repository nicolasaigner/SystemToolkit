function Merge-EnvFromBackup {
    <#
    .SYNOPSIS
        Compara um backup JSON e aplica adições/alterações seletivas nas variáveis de ambiente.
    
    .PARAMETER BackupDir
        Pasta contendo SystemEnvironment.json e UserEnvironment.json gerados pelo Export-EnvBackup.
    
    .EXAMPLE
        Merge-EnvFromBackup -BackupDir D:\Backups\EnvBackup-20250428-235812 -WhatIf
    #>
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory)]
            [string]$BackupDir
        )
    
        # ---------------------- Carrega backup ----------------------
        $bkSys = Get-Content (Join-Path $BackupDir 'SystemEnvironment.json') -Raw | ConvertFrom-Json
        $bkUsr = Get-Content (Join-Path $BackupDir 'UserEnvironment.json')   -Raw | ConvertFrom-Json
    
        # ---------------------- Snapshot rollback ------------------
        $rollback = 'EnvMergeRestore-{0:yyyyMMdd-HHmmss}' -f (Get-Date)
        New-Item -Path $rollback -ItemType Directory | Out-Null
        reg export 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' "$rollback\System_before.reg" /y
        reg export 'HKCU\Environment'                                                  "$rollback\User_before.reg"   /y
    
        # ---------------------- Função de merge --------------------
        function Invoke-MergeScope {
            param(
                [string]  $ScopeName,
                [psobject]$Backup,
                [string]  $RegPath
            )
    
            $current = Get-ItemProperty -Path $RegPath | Select-Object -ExcludeProperty PS*
    
            foreach ($prop in $Backup.PSObject.Properties) {
    
                $name     = $prop.Name
                $newValue = $prop.Value
                $id       = "[$ScopeName] $name"
    
                if ($current.PSObject.Properties.Name -notcontains $name) {
                    if ($PSCmdlet.ShouldProcess($id, 'Add')) {
                        Set-ItemProperty -Path $RegPath -Name $name -Value $newValue -Force
                    }
                }
                elseif ($current.$name -ne $newValue) {
                    Write-Host "$id difere." -ForegroundColor Yellow
                    Write-Host "  Atual : $($current.$name)" -ForegroundColor DarkGray
                    Write-Host "  Backup: $newValue"         -ForegroundColor DarkGray
    
                    $ans = Read-Host 'Sobrescrever? (S/N)'
                    if ($ans -match '^[sSyY]') {
                        if ($PSCmdlet.ShouldProcess($id, 'Replace')) {
                            Set-ItemProperty -Path $RegPath -Name $name -Value $newValue -Force
                        }
                    }
                }
            }
        }
    
        Invoke-MergeScope 'SISTEMA' $bkSys 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
        Invoke-MergeScope 'USUÁRIO' $bkUsr 'HKCU:\Environment'
    
# Broadcast WM_SETTINGCHANGE
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class NativeMethods {
    [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
        uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
"@
    [UIntPtr]$r = [UIntPtr]::Zero
    [NativeMethods]::SendMessageTimeout(
        [IntPtr]0xFFFF, 0x1A, [UIntPtr]::Zero, 'Environment',
        2, 1000, [ref]$r
    ) | Out-Null
}
