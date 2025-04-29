$log = "C:\logs\GitRepoWatcher\wrapper.log"

function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $log -Value "$ts - $msg"
}

Log "Wrapper iniciado."

while ($true) {
    if (Test-Path "E:\repositorios") {
        Log "E: montado. Iniciando watcher."
        $job = Start-Job -ScriptBlock {
            powershell -ExecutionPolicy Bypass -File "C:\scripts\monitor-repos.ps1"
        }

        while (Test-Path "E:\repositorios") {
            Start-Sleep -Seconds 5
        }

        Log "E: desmontado. Encerrando watcher."
        Stop-Job $job -Force
        Remove-Job $job
    } else {
        Log "E: ainda não montado. Verificando novamente em 10s..."
        Start-Sleep -Seconds 10
    }
}
