<#
.SYNOPSIS
Compara o backup JSON da VM com as chaves do host, mostra diferenças
e permite adicionar/atualizar variáveis seletivamente.
.Cria restore-point (.reg) automático antes de escrever.
.EXEMPLO
.\Merge-EnvFromBackup.ps1 -BackupDir .\EnvBackup-20250428-235812
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BackupDir
)

#------------------ Carrega backup -----------------------------
$bkSys = Get-Content (Join-Path $BackupDir 'SystemEnvironment.json')  -Raw | ConvertFrom-Json
$bkUsr = Get-Content (Join-Path $BackupDir 'UserEnvironment.json')    -Raw | ConvertFrom-Json

#------------------ Snapshot para rollback ---------------------
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$rollback = "EnvMergeRestore-$stamp"
mkdir $rollback
reg export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "$rollback\System_before.reg" /y
reg export "HKCU\Environment" "$rollback\User_before.reg" /y

#------------------ Função de merge ----------------------------
function Merge-Scope {
    param(
        [string]$ScopeName,
        [psobject]$Backup,
        [psobject]$Current,
        [string]$RegPath     # ex.: HKLM:\...Environment
    )

    foreach ($prop in $Backup.PSObject.Properties) {
        $name  = $prop.Name
        $value = $prop.Value

        if ($Current.PSObject.Properties.Name -notcontains $name) {
            Write-Host "[$ScopeName] ADICIONAR $name = $value" -ForegroundColor Green
            Set-ItemProperty -Path $RegPath -Name $name -Value $value -Force
        }
        elseif ($Current.$name -ne $value) {
            Write-Host "[$ScopeName] ALTERAR $name" -ForegroundColor Yellow
            Write-Host "  Valor atual : $($Current.$name)"
            Write-Host "  Valor backup: $value"
            $ans = Read-Host "    Sobrescrever? (S/N)"
            if ($ans -match '^[sSyY]') {
                Set-ItemProperty -Path $RegPath -Name $name -Value $value -Force
            }
        }
    }
}

#------------------ Carrega estado atual -----------------------
$curSys = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' |
          Select-Object -ExcludeProperty PS*
$curUsr = Get-ItemProperty -Path 'HKCU:\Environment' |
          Select-Object -ExcludeProperty PS*

#------------------ Executa merge ------------------------------
Merge-Scope 'SISTEMA' $bkSys $curSys 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
Merge-Scope 'USUÁRIO' $bkUsr $curUsr 'HKCU:\Environment'

#------------------ Broadcast WM_SETTINGCHANGE -----------------
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class NativeMethods{
  [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
  public static extern IntPtr SendMessageTimeout(
      IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
      uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
"@
$HWND_BROADCAST   = [intptr]0xffff
$WM_SETTINGCHANGE = 0x1A
[UIntPtr]$result  = [UIntPtr]::Zero
[NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero,
                                   'Environment', 0x0002, 1000, [ref]$result) | Out-Null
Write-Host "`n✔ Merge concluído; faça logoff/login ou reinicie para que shells de console herdem o novo ambiente."
