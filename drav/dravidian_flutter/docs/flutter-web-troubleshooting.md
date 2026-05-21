## Flutter Web Troubleshooting

Follow these steps to diagnose and stabilize Flutter web debugging in VS Code + Chrome.

- **Diagnostics**
  - Run: `flutter doctor -v` and `flutter --version`
  - Check for missing Chrome, incompatible SDKs, or outdated Flutter/Dart extensions.

- **Kill stale processes**
  - List Dart/Chrome processes:

```powershell
tasklist /FI "IMAGENAME eq dart.exe" /FO LIST
tasklist /FI "IMAGENAME eq chrome.exe" /FO LIST

Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'remote-debugging-port|dart' } | Select-Object ProcessId,Name,CommandLine | Format-List
```

  - To kill stale Dart processes (use with caution):

```powershell
Stop-Process -Name dart -Force
```

- **Safe cleaning & rebuild**
  - Recommended sequence:

```powershell
flutter clean
flutter pub cache repair   # optional, may take a long time
flutter pub get
```

- **Safer Chrome launch**
  - Use `--no-dds` to avoid DDS crashes during development:

```powershell
flutter run -d chrome --no-dds
```

- **VS Code launch config**
  - A safe launch configuration was added to `.vscode/launch.json` that includes a `Flutter Web (Chrome, no DDS)` profile.

- **If problems persist**
  - Restart VS Code after killing stale processes.
  - Start with an incognito Chrome profile or remove the temporary user-data-dir used by Flutter to ensure no corrupted profile state.
  - Collect `flutter run -v` logs and `flutter doctor -v` output and attach when asking for help.
