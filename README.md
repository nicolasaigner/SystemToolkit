# NicolasAigner.SystemToolkit

Ferramentas PowerShell para:

* **Export-EnvBackup** — backup completo das variáveis de ambiente em `.reg` + `.json`;
* **Merge-EnvFromBackup** — merge interativo desses backups;
* **Export-RegistrySelection** — exportação filtrada de chaves do Registro;
* **Compress-FolderToTarGz** — compactação de pastas em `.tar.gz`.

## Instalação

```powershell
Install-Module NicolasAigner.SystemToolkit -Scope CurrentUser
Import-Module NicolasAigner.SystemToolkit
```

## Build & Publish

Este repositório contém workflow GitHub Actions que publica no PowerShell Gallery quando uma tag `v*` for criada. Há também manifesto winget para instalação via `winget install NicolasAigner.SystemToolkit`.
