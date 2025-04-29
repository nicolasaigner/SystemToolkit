[CmdletBinding()]
param (
    [Parameter(Position=0)]
    [string[]] $TargetRoots = @("HKEY_LOCAL_MACHINE", "HKEY_CURRENT_USER", "HKEY_CLASSES_ROOT", "HKEY_USERS", "HKEY_CURRENT_CONFIG"),

    [Parameter(Position=1)]
    [string[]] $Filters = @(
        "Abrir pasta como projeto no ",
        "Open Folder as",
        "Open with",
        "Edit with"
    ),

    [Parameter(Position=2)]
    [ValidateSet("Key", "Value", "Data")]
    [string[]] $MatchFields = @("Key", "Value", "Data"),

    [Parameter(Position=3)]
    [string] $OutputDir = "D:\CONFIGURACOES_PERSONALIZADAS\Registros do Windows",

    [string] $Prefix,
    [string] $Suffix,

    [switch] $Help
)

function Show-Help {
@"
Export-Registry.ps1 [-TargetRoots <roots>] [-Filters <palavras>] [-MatchFields <Key|Value|Data>] [-OutputDir <caminho>] [-Prefix <str>] [-Suffix <str>] [-Help]

Parâmetros:
  -TargetRoots   Raízes do registro. Default: Todas
  -Filters       Palavras a serem buscadas. Default: palavras comuns
  -MatchFields   Onde buscar: Key, Value, Data. Default: todos
  -OutputDir     Pasta destino dos .reg
  -Prefix        Adicionado no início do nome do arquivo exportado
  -Suffix        Adicionado no final do nome do arquivo exportado
  -Help          Mostra esta ajuda

Exemplos:
  .\Export-Registry.ps1
  .\Export-Registry.ps1 -Filters "Open with","Edit with" -MatchFields Value
  .\Export-Registry.ps1 -Prefix Backup -Suffix 2025
"@ | Out-Host
exit 0
}

if ($Help) { Show-Help }

if (!(Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

function Verificar-E-Exportar {
    param (
        [string]$chave
    )

    try {
        $valores = & reg query "$chave" 2>$null
        if (!$valores) { return }

        $exportar = $false
        $valorParaNome = $null

        foreach ($linha in $valores) {
            if ($linha -match "^\s+([^\s]+)\s+REG_\w+\s+(.*)$") {
                $nome = $matches[1]
                $dado = $matches[2]

                foreach ($filtro in $Filters) {
                    if (
                        ("Value" -in $MatchFields -and $nome -like "*$filtro*") -or
                        ("Data" -in $MatchFields -and $dado -like "*$filtro*")
                    ) {
                        $exportar = $true
                        $valorParaNome = $dado
                        break
                    }
                }
            }
        }

        if ("Key" -in $MatchFields) {
            foreach ($filtro in $Filters) {
                if ($chave -like "*$filtro*") {
                    $exportar = $true
                    $valorParaNome = $chave
                    break
                }
            }
        }

        if ($exportar) {
            $nomeArquivo = $valorParaNome
            if (-not $nomeArquivo) { $nomeArquivo = $chave }

            $nomeArquivo = $nomeArquivo -replace '[\\\/:\*\?"<>\|]', ''
            if ($nomeArquivo.Length -gt 100) { $nomeArquivo = $nomeArquivo.Substring(0, 100) }

            # Aplica prefixo e sufixo
            $nomeCompleto = if ($Prefix) { "$Prefix-" } else { "" }
            $nomeCompleto += $nomeArquivo
            if ($Suffix) { $nomeCompleto += "-$Suffix" }

            $arquivoFinal = Join-Path $OutputDir "$nomeCompleto.reg"

            Start-Process -FilePath "reg.exe" -ArgumentList @("export", "`"$chave`"", "`"$arquivoFinal`"", "/y") -Wait -WindowStyle Hidden
            Write-Host "✅ Exportado: $chave -> $arquivoFinal"
        }
    } catch { }
}

function Varredura-Recursiva {
    param ([string]$raiz)

    Write-Host "🔍 Escaneando: $raiz"

    $subchaves = & reg query "$raiz" /s 2>$null
    if (!$subchaves) { return }

    foreach ($linha in $subchaves) {
        if ($linha -match "^(HKEY_.+)$") {
            Verificar-E-Exportar -chave $linha
        }
    }
}

# Execução principal
foreach ($raiz in $TargetRoots) {
    Varredura-Recursiva -raiz $raiz
}
