# NicolasAigner.SystemToolkit

Ferramentas PowerShell para:

* **Export-EnvBackup** — backup completo das variáveis de ambiente em `.reg` + `.json`.
* **Merge-EnvFromBackup** — merge interativo desses backups.
* **Export-RegistrySelection** — exportação filtrada de chaves do Registro.
* **Compress-FolderToTarGz** — compactação de pastas em `.tar.gz`.
* **Update-MacroKeyboard** — valida e envia configuração do teclado macro via ch57x-keyboard-tool.

## Instalação

```powershell
Install-Module NicolasAigner.SystemToolkit -Scope CurrentUser
Import-Module NicolasAigner.SystemToolkit
```

## Build & Publish

Este repositório contém workflow GitHub Actions que publica no PowerShell Gallery quando uma tag `v*` for criada.

## Uso

### Export-EnvBackup

```powershell
Export-EnvBackup -BackupDir 'EnvBackup-20250429-001846'
```

### Merge-EnvFromBackup

```powershell
Merge-EnvFromBackup -BackupDir 'EnvBackup-20250429-001846'
```

### Export-RegistrySelection

```powershell
Export-RegistrySelection -Path 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
```

### Compress-FolderToTarGz

```powershell
Compress-FolderToTarGz -Path 'C:\Temp\MyFolder' -Destination 'C:\Temp\MyFolder.tar.gz'
```

### Update-MacroKeyboard

```powershell
Update-MacroKeyboard -Path "ch57x-keyboard-tool.exe" -ConfigFile "mapping.yaml"
```