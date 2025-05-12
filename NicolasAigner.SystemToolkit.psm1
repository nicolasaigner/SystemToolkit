# SystemToolkit.psm1 - Módulo principal do SystemToolkit v1.1.0

# Carrega todas as funções do módulo
Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 -Recurse | ForEach-Object {
    . $_.FullName
}

# Exporta explicitamente as funções públicas
Export-ModuleMember -Function `
    'Export-EnvBackup', `
    'Merge-EnvFromBackup', `
    'Export-RegistrySelection', `
    'Compress-FolderToTarGz', `
    'Update-MacroKeyboard', `
    'Edit-MacroKeyboardConfig', `
    'Invoke-MacroKeyboardToolCommand'
