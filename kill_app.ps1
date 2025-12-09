# Quick script to kill all Stockify/Flutter processes
Write-Host "Killing all Stockify processes..." -ForegroundColor Yellow

Get-Process | Where-Object { 
    $_.ProcessName -like "*testproject*" -or 
    $_.ProcessName -like "*stockify*" -or
    $_.MainWindowTitle -like "*Stockify*" -or
    $_.ProcessName -like "*flutter*"
} | ForEach-Object {
    Write-Host "Killing: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Red
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

Write-Host "Done!" -ForegroundColor Green

