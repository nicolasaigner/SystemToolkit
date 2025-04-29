param (
    [string]$TargetDir = ".",
    [string[]]$Exclude
)

# Resolve caminho absoluto
$TargetFullPath = Resolve-Path -Path $TargetDir
$BaseName = Split-Path -Path $TargetFullPath -Leaf
$ParentPath = Split-Path -Path $TargetFullPath -Parent

# Timestamp e nomes dos arquivos
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$TarFileName = "${BaseName}_$Timestamp.tar"
$GzFileName = "${TarFileName}.gz"
$TarFullPath = Join-Path -Path $ParentPath -ChildPath $TarFileName
$GzFullPath = Join-Path -Path $ParentPath -ChildPath $GzFileName

# Diretório temporário
$TempDir = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath()) -Name "tar_temp_$([guid]::NewGuid())"

# Listar e copiar itens para temp
$allItems = Get-ChildItem -Path $TargetFullPath -Recurse -Force
foreach ($item in $allItems) {
    $relative = $item.FullName.Substring($TargetFullPath.Path.Length + 1)

    $shouldExclude = $false
    if ($Exclude) {
        foreach ($pattern in $Exclude) {
            if ($item.Name -like $pattern -or $relative -like $pattern -or ($relative.Split('\')[0] -like $pattern)) {
                $shouldExclude = $true
                break
            }
        }
    }

    if (-not $shouldExclude) {
        $destPath = Join-Path -Path $TempDir.FullName -ChildPath $relative

        if ($item.PSIsContainer) {
            New-Item -ItemType Directory -Path $destPath -Force | Out-Null
        } else {
            $destDir = Split-Path -Path $destPath -Parent
            if (-not (Test-Path -Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item -Path $item.FullName -Destination $destPath -Force
        }
    }
}

# Tentar usar bsdtar, fallback para tar
$tarExe = Get-Command bsdtar -ErrorAction SilentlyContinue
if ($tarExe) {
    Write-Host "Usando BSDTar para gerar o TAR..."
    & $tarExe.Path -cf $TarFullPath -C $TempDir .
} else {
    Write-Host "BSDTar não encontrado. Usando TAR padrão..."
    tar -cf $TarFullPath -C $TempDir .
}

# Compactar .tar em .gz
Write-Host "Compactando TAR em GZ..."
$fs = [System.IO.File]::OpenRead($TarFullPath)
$gz = [System.IO.File]::Create($GzFullPath)
$gzipStream = New-Object System.IO.Compression.GzipStream($gz, [System.IO.Compression.CompressionMode]::Compress)
$fs.CopyTo($gzipStream)
$gzipStream.Close()
$fs.Close()
$gz.Close()

# Limpeza
Remove-Item -Path $TarFullPath -Force
Remove-Item -Path $TempDir.FullName -Recurse -Force

Write-Host "`n✅ Arquivo gerado com sucesso: $GzFullPath"
