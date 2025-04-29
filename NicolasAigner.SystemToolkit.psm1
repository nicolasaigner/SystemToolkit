# Auto‑loader: importa todas as funções do subdiretório Functions
$funcPath = Join-Path $PSScriptRoot 'Functions'
foreach ($file in Get-ChildItem -Path $funcPath -Filter '*.ps1') {
    . $file.FullName
}
Export-ModuleMember -Function (Get-ChildItem -Path $funcPath -Filter '*.ps1').BaseName