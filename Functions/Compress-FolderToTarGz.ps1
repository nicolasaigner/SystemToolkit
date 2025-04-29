
function Compress-FolderToTarGz {
<#
.SYNOPSIS
    Compacta diretório em .tar.gz usando tar + gzip.

.PARAMETER TargetDir
    Pasta a compactar (default: .).

.PARAMETER Exclude
    Itens a excluir (relativos).

.EXAMPLE
    Compress-FolderToTarGz -TargetDir C:\Projetos\App -Exclude @('.git','node_modules')
#>
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$TargetDir='.',[string[]]$Exclude)

    $resolved = Resolve-Path $TargetDir
    $baseName = Split-Path $resolved -Leaf
    $parent   = Split-Path $resolved -Parent
    $stamp    = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $tarFull  = Join-Path $parent ("${baseName}_${stamp}.tar")
    $gzFull   = "$tarFull.gz"

    if ($PSCmdlet.ShouldProcess($TargetDir, "Compress to $gzFull")) {
        Push-Location $parent
        $excludeArgs = $Exclude | ForEach-Object { "--exclude=$_" }
        tar @excludeArgs -cf $tarFull $baseName
        if (Get-Command gzip -ErrorAction SilentlyContinue) {
            gzip -9 $tarFull
        } else {
            tar -czf $gzFull -C $parent $baseName
            Remove-Item $tarFull -Force
        }
        Pop-Location
        Write-Output $gzFull
    }
}
