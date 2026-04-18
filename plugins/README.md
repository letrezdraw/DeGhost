# DeGhost Plugin System

Place `.ps1` plugin files in this folder. They will automatically appear in the **Run Plugins** menu inside DeGhost.

## Creating a Plugin

1. Create a new `.ps1` file in the `plugins/` folder (e.g., `myapp.ps1`).
2. Use the shared logging helper by dot-sourcing it at the top:
   ```powershell
   . "$PSScriptRoot\..\modules\log.ps1"
   Write-Log "My plugin is running..."
   ```
3. Respect `$env:DEGHOST_DRYRUN` if you want your plugin to support dry-run mode:
   ```powershell
   if ($env:DEGHOST_DRYRUN -eq "true") {
       Write-Log "[DRY RUN] Would do something"
   } else {
       # actual work here
   }
   ```

## Included Example

- `example.ps1` – Starter template you can copy and modify.

## Community Plugin Ideas

| File | Purpose |
|------|---------|
| `unreal.ps1` | Clear Unreal Engine derived-data cache |
| `blender.ps1` | Clear Blender temp/cache directories |
| `adobe.ps1` | Deep-clean Adobe suite cache |
| `davinci.ps1` | Clear DaVinci Resolve cache |
| `unity.ps1` | Clear Unity Library / cache folders |
