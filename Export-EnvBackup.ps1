<#
.SYNOPSIS
Exporta variáveis de ambiente (Sistema, Usuário atual e Perfil-Default)
para .reg (reimportação rápida) e .json (diff legível).
.Gera pasta EnvBackup-AAAAmmdd-HHmmss abaixo do diretório atual.
#>

param(
    [string]$OutDir = (Join-Path $PWD ("EnvBackup-{0:yyyyMMdd-HHmmss}" -f (Get-Date)))
)

# 1) Cria pasta de destino
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

# 2) Dumps .REG – fáceis de importar depois com "reg import"
reg.exe export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" `
              "$OutDir\SystemEnvironment.reg" /y
reg.exe export "HKCU\Environment"                         "$OutDir\UserEnvironment.reg" /y
reg.exe export "HKEY_USERS\.DEFAULT\Environment"          "$OutDir\DefaultUserEnvironment.reg" /y

# 3) Dumps .JSON – bons para diff/merge
$opts = @{Depth = 3; Compress = $false}
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' |
    Select-Object -ExcludeProperty PS* |
    ConvertTo-Json @opts | Set-Content -Encoding UTF8 "$OutDir\SystemEnvironment.json"

Get-ItemProperty -Path 'HKCU:\Environment' |
    Select-Object -ExcludeProperty PS* |
    ConvertTo-Json @opts | Set-Content -Encoding UTF8 "$OutDir\UserEnvironment.json"

Get-ItemProperty -Path 'Registry::HKEY_USERS\.DEFAULT\Environment' -ErrorAction SilentlyContinue |
    Select-Object -ExcludeProperty PS* |
    ConvertTo-Json @opts | Set-Content -Encoding UTF8 "$OutDir\DefaultUserEnvironment.json"

Write-Host "✔ Backup completo em: $OutDir"
