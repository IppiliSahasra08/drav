<#
PowerShell helper to diagnose and fix common Flutter web debugging issues.
Run as: Open PowerShell, change to repo root, then: .\scripts\fix_flutter_web.ps1
#>

Write-Host "Running Flutter web troubleshooting script..."

Push-Location "${PWD}"

Write-Host "1) Show Flutter/Dart environment"
flutter doctor -v
flutter --version

Write-Host "\n2) List relevant processes (dart/chrome)"
tasklist /FI "IMAGENAME eq dart.exe" /FO LIST
tasklist /FI "IMAGENAME eq chrome.exe" /FO LIST

Write-Host "\n3) Optionally kill stale Dart processes (uncomment to enable)"
# Stop-Process -Name dart -Force

Write-Host "\n4) Clean and fetch packages"
cd ${PSScriptRoot}\..\
flutter clean
flutter pub get

Write-Host "\n5) Optional: Repair pub cache (may take a while)"
# flutter pub cache repair

Write-Host "\n6) Launch app in Chrome without DDS for stability"
flutter run -d chrome --no-dds

Pop-Location

Write-Host "Script finished. If you still see issues, run flutter doctor output above and open an issue with logs."
