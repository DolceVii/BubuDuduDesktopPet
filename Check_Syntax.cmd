@echo off
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$tokens=$null; $errors=$null; [System.Management.Automation.Language.Parser]::ParseFile((Join-Path (Get-Location) 'BubuDudu.ps1'), [ref]$tokens, [ref]$errors) > $null; if($errors.Count -eq 0) { Write-Host 'Syntax OK' -ForegroundColor Green } else { $errors | Format-List | Out-Host; exit 1 }"
pause
