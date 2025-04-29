# Caminho do script original
$origemScript = Join-Path $PSScriptRoot "Export-Registry.ps1"

# Caminho destino padrão do seu repositório de scripts pessoais
$destinoPasta = "D:\CONFIGURACOES_PERSONALIZADAS\PowerShell\Scripts"
$destinoScript = Join-Path $destinoPasta "Export-Registry.ps1"

# Nome do alias permanente
$alias = "export-registry"

# Caminho do PowerShell profile
$profilePath = $PROFILE
$profileDir = Split-Path $profilePath

# Cria diretório de destino se não existir
if (!(Test-Path $destinoPasta)) {
    New-Item -ItemType Directory -Path $destinoPasta -Force | Out-Null
}

# Copia o script para o destino
if ($origemScript -ne $destinoScript) {
    Copy-Item -Path $origemScript -Destination $destinoScript -Force
    Write-Host "✅ Script instalado em: $destinoScript"
} else {
    Write-Host "🔁 Script já está no destino."
}

# Cria o diretório do profile, se necessário
if (!(Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Garante que o alias seja adicionado ou atualizado no profile
if (!(Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$aliasComando = "Set-Alias -Name $alias -Value `"$destinoScript`""
$profileContent = Get-Content -Path $profilePath -Raw

if ($profileContent -notmatch [regex]::Escape($aliasComando)) {
    Add-Content -Path $profilePath -Value "`n$aliasComando"
    Write-Host "✅ Alias '$alias' adicionado ao seu profile PowerShell."
} else {
    Write-Host "🔁 Alias '$alias' já existe no profile."
}

Write-Host "`n🎉 Instalação concluída com sucesso!"
Write-Host "💡 Use agora com: $alias [-Filters ...] [-MatchFields ...]"
Write-Host "🔄 Execute '. $profilePath' ou reinicie o PowerShell para ativar o alias."
