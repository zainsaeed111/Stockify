# Script to safely run Flutter app on Windows
# This kills any running instances before building

Write-Host "Checking for running Stockify processes..." -ForegroundColor Yellow

# Kill any running testproject or stockify processes
Get-Process | Where-Object { 
    $_.ProcessName -like "*testproject*" -or 
    $_.ProcessName -like "*stockify*" -or
    $_.MainWindowTitle -like "*Stockify*"
} | ForEach-Object {
    Write-Host "Terminating process: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Red
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

Start-Sleep -Seconds 2

# Remove locked executable if it exists
$exePath = "build\windows\x64\runner\Debug\testproject.exe"
if (Test-Path $exePath) {
    try {
        Remove-Item $exePath -Force -ErrorAction SilentlyContinue
        Write-Host "Removed locked executable" -ForegroundColor Green
    } catch {
        Write-Host "Could not remove executable (may still be locked)" -ForegroundColor Yellow
    }
}

Write-Host "Starting Flutter app..." -ForegroundColor Green
flutter run -d windows

