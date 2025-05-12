<#
.SYNOPSIS
    Compara um backup JSON gerado pelo Export-EnvBackup
    e aplica correções seletivas nas variáveis de ambiente,
    reconstruindo automaticamente Path/TEMP/TMP/OneDrive.

.DESCRIPTION
    • Cria ponto-de-retorno (reg export) antes de mexer.  
    • Deduplica entradas de Path, remove “System.String[]” e
      reinserta segmentos vitais do Windows.  
    • Mantém seus caminhos personalizados (nvm, Python 3.13,
      JetBrains, VS Code, PlatformIO, scripts pessoais).  
    • Preserva CPU-dependentes (NUMBER_OF_PROCESSORS).  
    • Para variáveis que existiam só no host (p.ex. NVM_HOME)
      nada é removido.

.PARAMETER BackupDir
    Pasta contendo SystemEnvironment.json e UserEnvironment.json.

.EXAMPLE
    .\Merge-EnvFromBackup.ps1 -BackupDir D:\Backups\EnvBackup-20250428-235812

.NOTES
    Requer PowerShell 7+.  Execute em modo Administrador para
    editar HKLM.
#>

function Merge-EnvFromBackup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$BackupDir,

        # Permite estender/ajustar seus caminhos pessoais sem editar o código
        [string[]]$UserCustomPath   = @(
            "D:\CONFIGURACOES_PERSONALIZADAS\PowerShell\Scripts",
            "D:\CONFIGURACOES_PERSONALIZADAS\nvm",
            "D:\CONFIGURACOES_PERSONALIZADAS\nvm\nodejs",
            "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Launcher\",
            "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python313\",
            "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python313\Scripts\",
            "C:\Users\$env:USERNAME\AppData\Local\Programs\Microsoft VS Code\bin",
            "C:\Users\$env:USERNAME\AppData\Local\JetBrains\Toolbox\scripts",
            "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Links"
        ),

        [string[]]$SystemCustomPath = @(
            "C:\.platformio\penv\Scripts"
        )
    )

    # ---------- 1. Carrega backup ---------- #
    $bkSys = Get-Content (Join-Path $BackupDir 'SystemEnvironment.json') -Raw | ConvertFrom-Json
    $bkUsr = Get-Content (Join-Path $BackupDir 'UserEnvironment.json')   -Raw | ConvertFrom-Json

    # ---------- 2. Snapshot rollback ---------- #
    $rollback = "EnvMergeRestore-$((Get-Date).ToString('yyyyMMdd-HHmmss'))"
    New-Item -Path $rollback -ItemType Directory | Out-Null
    reg export 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' "$rollback\System_before.reg" /y
    reg export 'HKCU\Environment'                                                  "$rollback\User_before.reg"   /y
    Write-Host "`n✓  Backups criados em '$rollback'." -ForegroundColor Green

    # ---------- 3. Definições de baseline limpo ---------- #
    $UserCorePath = @(
        "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WindowsApps"
    )
    $SystemCorePath = @(
        "C:\WINDOWS\system32",
        "C:\WINDOWS",
        "C:\WINDOWS\System32\Wbem",
        "C:\WINDOWS\System32\WindowsPowerShell\v1.0\",
        "C:\WINDOWS\System32\OpenSSH\",
        "C:\Program Files\PowerShell\7\",
        "C:\Program Files\Git\cmd"
    )
    $UserCoreVars = @{
        OneDrive = "C:\Users\$env:USERNAME\OneDrive"
        TEMP     = "C:\Users\$env:USERNAME\AppData\Local\Temp"
        TMP      = "C:\Users\$env:USERNAME\AppData\Local\Temp"
    }

    # ---------- 4. Função de Path merge ---------- #
    function Merge-Path {
        param(
            [string]  $BackupPath,
            [string[]]$Core,
            [string[]]$Custom,
            [string]  $Scope # 'User' ou 'Machine'
        )
        $live = [Environment]::GetEnvironmentVariable('Path', $Scope)
        $all  = @($Core + $Custom + ($BackupPath -split ';') + ($live -split ';')) |
                Where-Object { $_ -and $_ -ne 'System.String[]' } |
                Select-Object -Unique |
                ForEach-Object {
                    # Opcional: manter só paths existentes
                    if (Test-Path $_) { $_ }
                }
        return ($all -join ';')
    }

    # ---------- 5. Função genérica de merge ---------- #
    function Invoke-MergeScope {
        param(
            [string]   $ScopeName,   # 'SISTEMA' ou 'USUÁRIO'
            [psobject] $Backup,
            [string]   $RegPath,
            [string[]] $CorePath,
            [string[]] $CustomPath,
            [hashtable]$CoreVars,
            [string]   $ScopeShort  # 'Machine' ou 'User' (para [Environment]::Set...)
        )

        $current = Get-ItemProperty -Path $RegPath | Select-Object -ExcludeProperty PS*

        # -- Passo A: trata variáveis críticas específicas --------- #
        foreach ($kv in $CoreVars.GetEnumerator()) {
            $name = $kv.Key
            $wanted = $kv.Value
            if ($current.$name -ne $wanted) {
                $id = "[$ScopeName] $name"
                if ($PSCmdlet.ShouldProcess($id, "Set '$wanted'")) {
                    Set-ItemProperty -Path $RegPath -Name $name -Value $wanted -Force
                    Write-Host "✓  $id corrigido." -ForegroundColor Green
                }
            }
        }

        # -- Passo B: Path ----------------------------------------- #
        if ($Backup.PSObject.Properties.Name -contains 'Path') {
            $newPath = Merge-Path -BackupPath $Backup.Path -Core $CorePath -Custom $CustomPath -Scope $ScopeShort
            if ($current.Path -ne $newPath) {
                $id = "[$ScopeName] Path"
                Write-Host "$id diferiu." -ForegroundColor Yellow
                Write-Host "  Atual : $($current.Path)" -ForegroundColor DarkGray
                Write-Host "  Novo  : $newPath"         -ForegroundColor DarkGray
                $ansPath = Read-Host '>> Aplicar Path corrigido? (S/N)'
                if ($ansPath -match '^[sSyY]') {
                    if ($PSCmdlet.ShouldProcess($id, 'Replace Path')) {
                        Set-ItemProperty -Path $RegPath -Name Path -Value $newPath -Force
                        Write-Host "✓  Path atualizado." -ForegroundColor Green
                    }
                }
            }
        }

        # -- Passo C: Demais variáveis (interativo) ---------------- #
        foreach ($prop in $Backup.PSObject.Properties) {
            $name     = $prop.Name
            if ($name -eq 'Path' -or $CoreVars.ContainsKey($name)) { continue }

            $newValue = $prop.Value
            $id       = "[$ScopeName] $name"

            if ($current.PSObject.Properties.Name -notcontains $name) {
                if ($PSCmdlet.ShouldProcess($id, 'Add')) {
                    Set-ItemProperty -Path $RegPath -Name $name -Value $newValue -Force
                    Write-Host "✓  $id adicionado." -ForegroundColor Green
                }
            }
            elseif ($current.$name -ne $newValue) {
                Write-Host "$id difere."     -ForegroundColor Yellow
                Write-Host "  Atual : $($current.$name)" -ForegroundColor DarkGray
                Write-Host "  Backup: $newValue"         -ForegroundColor DarkGray
                $ans = Read-Host '>> Sobrescrever? (S/N)'
                if ($ans -match '^[sSyY]') {
                    if ($PSCmdlet.ShouldProcess($id, 'Replace')) {
                        Set-ItemProperty -Path $RegPath -Name $name -Value $newValue -Force
                        Write-Host "✓  $id substituído." -ForegroundColor Green
                    }
                }
            }
        }
    }

    # ---------- 6. Invoca merge p/ Sistema e Usuário ---------- #
    Invoke-MergeScope `
        -ScopeName   'SISTEMA' `
        -Backup      $bkSys `
        -RegPath     'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' `
        -CorePath    $SystemCorePath `
        -CustomPath  $SystemCustomPath `
        -CoreVars    @{} `
        -ScopeShort  'Machine'

    Invoke-MergeScope `
        -ScopeName   'USUÁRIO' `
        -Backup      $bkUsr `
        -RegPath     'HKCU:\Environment' `
        -CorePath    $UserCorePath `
        -CustomPath  $UserCustomPath `
        -CoreVars    $UserCoreVars `
        -ScopeShort  'User'

    # ---------- 7. Broadcast WM_SETTINGCHANGE ---------- #
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

    Write-Host "`n✔️  Mesclagem concluída! Reinicie a sessão para herdar as mudanças." `
        -ForegroundColor Cyan
}

# Exporta a função para a sessão atual se o arquivo for dot-sourced.
# Caso contrário, basta chamá-la diretamente se o script for executado.
