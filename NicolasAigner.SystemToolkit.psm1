# Auto‑loader: importa todas as funções do subdiretório Functions
Get-ChildItem -Path (Join-Path $PSScriptRoot 'Functions') -Filter '*.ps1' |
ForEach-Object {
    . $_.FullName
    Export-ModuleMember -Function $_.BaseName
}