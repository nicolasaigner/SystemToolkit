$logPath = "C:\logs\GitRepoWatcher"
$logFile = Join-Path $logPath "repo-watcher.log"

if (-not (Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory | Out-Null
}

function Log($msg) {
    Add-Content -Path $logFile -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $msg"
}

Log "monitor-repos.ps1 iniciado"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "E:\repositorios"
$watcher.Filter = "*"
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

Register-ObjectEvent $watcher Created -Action {
    Start-Sleep -Seconds 1
    $name = $Event.SourceEventArgs.Name
    $fullPath = Join-Path "E:\repositorios" $name

    if ((Test-Path $fullPath) -and (Get-Item $fullPath).PSIsContainer) {
        Log "Nova pasta detectada: $name"
        Set-Location $fullPath
        try {
            New-Item -Path "$fullPath\README.md" -ItemType File -Force | Out-Null
            Log "README.md criado em $fullPath"

            git init | Out-Null
            Log "Git iniciado em $fullPath"

            git add . | Out-Null
            git commit -m "Initial commit" | Out-Null
            Log "Commit inicial criado"

            $result = gh repo create $name --private --source . --remote origin --push 2>&1
            Log ("Resultado gh repo create: {0}" -f $result)
        } catch {
            Log ("Erro ao processar {0}: {1}" -f $name, $_)
        }
    }
}

while ($true) { Start-Sleep 2 }
