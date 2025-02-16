@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$script = try { (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/HerrTaeubler/BackupBuddy/main/BackupBuddy.ps1' -UseBasicParsing) } catch { Write-Host 'Download error: $_' -ForegroundColor Red; pause; exit }; ^
if ($script) { try { Invoke-Expression $script } catch { Write-Host 'Execution error: $_' -ForegroundColor Red; pause } }"
pause 