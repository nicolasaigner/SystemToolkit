
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
    param(
        [string]$TargetDir = '.',
        [string[]]$Exclude
    )

    $resolved = Resolve-Path $TargetDir
    $baseName = Split-Path $resolved -Leaf
    $parent   = Split-Path $resolved -Parent
    $timestamp= Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $tarName  = \"${baseName}_${timestamp}.tar\"
    $gzName   = \"$tarName.gz\"
    $tarFull  = Join-Path $parent $tarName
    $gzFull   = Join-Path $parent $gzName

    if ($PSCmdlet.ShouldProcess($TargetDir,\"Compress to $gzFull\")) {
        $excludeArgs = @()
        foreach ($ex in $Exclude) { $excludeArgs += \"--exclude=$ex\" }

        Push-Location $parent
        & tar @excludeArgs -cf $tarFull $baseName
        if ($LASTEXITCODE) { throw 'tar falhou.' }

        # gzip -9 se disponível, senão usa tar -czf direto
        if (Get-Command gzip -ErrorAction SilentlyContinue) {
            & gzip -9 $tarFull
        } else {
            & tar -czf $gzFull -C $parent $baseName
            Remove-Item $tarFull -Force
        }
        Pop-Location
        Write-Output $gzFull
    }
}
