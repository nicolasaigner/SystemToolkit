@{
    RootModule        = 'NicolasAigner.SystemToolkit.psm1'
    ModuleVersion     = '1.1.0'
    GUID              = '8b2042b8-550d-46b7-b4b8-7b34154bae01'
    Author            = 'Nícolas Aigner'
    CompanyName       = 'Nícolas Aigner'
    Description       = 'Ferramentas PowerShell para backup/merge de variáveis de ambiente, exportação de registro, macro keyboard e compactação tar.gz.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop','Core')
    FunctionsToExport = @(
        'Export-EnvBackup',
        'Merge-EnvFromBackup',
        'Export-RegistrySelection',
        'Compress-FolderToTarGz',
        'Update-MacroKeyboard'
    )
    CmdletsToExport   = @()
    AliasesToExport   = @()
}
