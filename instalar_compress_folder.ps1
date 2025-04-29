param (
    [string]$aliasNome = "compress-folder",
    [string]$scriptNomeFinal = "Compress-FolderToTarGz.ps1"
)

# Caminhos principais
$origemScript = Join-Path $PWD $scriptNomeFinal
$destinoDir = "D:\CONFIGURACOES_PERSONALIZADAS\PowerShell\Scripts"
$destinoScript = Join-Path $destinoDir $scriptNomeFinal

# 1. Criar diretório se necessário
if (-not (Test-Path $destinoDir)) {
    New-Item -ItemType Directory -Path $destinoDir -Force | Out-Null
    Write-Host "✅ Diretório criado: $destinoDir"
}

# 2. Verificar se o script de origem existe
if (-not (Test-Path $origemScript)) {
    Write-Host "❌ Script '$scriptNomeFinal' não encontrado no diretório atual." -ForegroundColor Red
    exit 1
}

# 3. Copiar apenas se for arquivo diferente
if ($origemScript -ne $destinoScript) {
    Copy-Item -Path $origemScript -Destination $destinoScript -Force
    Write-Host "✅ Script atualizado em: $destinoScript"
} else {
    Write-Host "⚠️ Script já está no destino: $destinoScript (cópia ignorada)"
}

# 4. Garantir que a pasta esteja no PATH do usuário
$pathUser = [Environment]::GetEnvironmentVariable("PATH", "User").Split(";")
if ($pathUser -notcontains $destinoDir) {
    [Environment]::SetEnvironmentVariable(
        "PATH",
        ($pathUser + $destinoDir -join ";"),
        [EnvironmentVariableTarget]::User
    )
    Write-Host "✅ Caminho adicionado ao PATH do usuário."
} else {
    Write-Host "ℹ️ Caminho já presente no PATH."
}

# 5. Garantir que o perfil do PowerShell exista
if (-not (Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Write-Host "✅ Perfil do PowerShell criado: $PROFILE"
}

# 6. Inserir ou atualizar o alias no perfil
$aliasLinha = "Set-Alias $aliasNome `"$destinoScript`""
$perfilConteudo = Get-Content -Path $PROFILE -Raw
if ($perfilConteudo -match "Set-Alias\s+$aliasNome\s+") {
    $novoConteudo = $perfilConteudo -replace "Set-Alias\s+$aliasNome\s+`".*?`"", $aliasLinha
    Set-Content -Path $PROFILE -Value $novoConteudo
    Write-Host "🔁 Alias '$aliasNome' atualizado no perfil."
} else {
    Add-Content -Path $PROFILE -Value "`n$aliasLinha"
    Write-Host "✅ Alias '$aliasNome' adicionado ao perfil."
}

# 7. Verificar bsdtar
if (-not (Get-Command bsdtar -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "⚠️ AVISO: 'bsdtar' não foi encontrado no sistema." -ForegroundColor Yellow
    Write-Host "   O script irá usar 'tar' padrão, que pode causar perda de caracteres em nomes de arquivos longos ou especiais."
    Write-Host "💡 Para evitar isso, instale o BSDTar com:"
    Write-Host "   choco install bsdtar    (via Chocolatey)" -ForegroundColor Cyan
    Write-Host "   ou instale via Microsoft Store: Windows BSDTar"
}

# ✅ Finalização
Write-Host "`n🎉 Instalação/atualização concluída com sucesso!"
Write-Host "🔄 Execute '. $PROFILE' ou reinicie o PowerShell para ativar o alias."
Write-Host "💡 Use agora com: $aliasNome [-TargetDir <dir>] [-Exclude <itens...>]"
