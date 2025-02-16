# Check for execution policy
if ((Get-ExecutionPolicy) -eq "Restricted") {
    Write-Host "ExecutionPolicy is set to 'Restricted'. Attempting to set to 'Bypass' temporarily..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
    } catch {
        Write-Host "Error setting ExecutionPolicy: $_" -ForegroundColor Red
        Exit
    }
}

# Download and execute BackupBuddy
$scriptUrl = "https://raw.githubusercontent.com/HerrTaeubler/BackupBuddy/main/BackupBuddy.ps1"

try {
    $script = (Invoke-RestMethod -Uri $scriptUrl -UseBasicParsing)
    Invoke-Expression $script
} catch {
    Write-Host "Error downloading or executing script: $_" -ForegroundColor Red
    Write-Host "Please check your internet connection and try again." -ForegroundColor Yellow
    Pause
} 