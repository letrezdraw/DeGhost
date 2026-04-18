# DeGhost

DeGhost is a hardware-aware Windows optimizer that cleans caches across all drives, removes safe bloatware, and applies performance, startup, and latency tweaks. It auto-detects system specs, supports gaming/workstation/custom modes, backs up all changes before applying them, and runs as a portable, dependency-free Batch + PowerShell toolkit.

## Features

| Category | What it does |
|---|---|
| **Admin check** | Auto-elevates to Administrator on launch |
| **Backup & Restore** | Creates a System Restore Point, exports registry, backs up service state |
| **Hardware detection** | Detects RAM (8/16/32 GB tiers), CPU vendor, GPU brand, SSD/HDD/NVMe, Windows version |
| **Adaptive memory** | Applies light/moderate/aggressive tweaks based on detected RAM |
| **Logging** | All actions written to `logs\DeGhost.log` |
| **Multi-drive cleanup** | Scans every drive for Temp/Cache/Log folders |
| **App-aware cleaning** | Cleans Adobe, Blender, Maya, Android Studio, VSCode, Epic, FiveM, Discord, Steam, Spotify, Chrome, Edge caches — only if installed |
| **GPU cache cleaner** | Clears NVIDIA DXCache/GLCache/shader or AMD DxCache |
| **Safe debloat** | Removes Copilot, Widgets, Clipchamp, Cortana, Maps, etc. Keeps Store, Xbox, drivers |
| **Startup debloat** | Disables Teams, Edge boost, Discord, Spotify, Adobe CC from startup |
| **Gaming mode** | Disables GameDVR, network throttling, background apps; enables GPU scheduling, Ultimate Performance |
| **Input latency** | Timer resolution, power throttling off |
| **Service profiles** | Gaming / Workstation / Balanced — disables appropriate services |
| **CPU scheduler** | Win32PrioritySeparation + foreground boost |
| **Dry run mode** | Preview all changes without applying anything |
| **Restore mode** | Restore registry, restore services, open System Restore, undo gaming tweaks |
| **Benchmark** | CPU compute, disk write speed, RAM usage, drive space |
| **Scheduler** | Create Weekly Cleanup or Monthly Deep Clean Windows tasks |
| **Plugin system** | Drop `.ps1` files in `plugins/` — they appear in the Run Plugins menu |
| **Themes** | Green (default), Red, Dark, Minimal — set in `DeGhost.conf` |
| **Config file** | `DeGhost.conf` persists all settings; editable from the Settings menu |
| **Portable** | Run directly from USB, Desktop, or Downloads — no install required |

## Quick Start

1. Right-click `DeGhost.bat` → **Run as administrator** (or just double-click — it auto-elevates).
2. Review the hardware info on the menu.
3. Choose an option and follow the prompts.

> **Tip:** Use option **7 (Dry Run Preview)** for a one-time preview of what would change, or toggle option **12** to keep dry-run mode on for all subsequent operations.

## Menu

```
1.  Full Optimize       – Everything: cleanup, debloat, services, gaming, memory
2.  Cleanup             – Multi-drive temp/cache/GPU/app cache cleaner
3.  Debloat             – Remove bloatware + disable startup items
4.  Gaming Mode         – Gaming services + latency tweaks + memory
5.  Workstation Mode    – Workstation services + disk + memory
6.  Custom Mix          – Pick exactly which modules to run
7.  Dry Run Preview     – Shows what would change, no writes
8.  Restore             – Registry / services / system restore / undo tweaks
9.  Benchmark           – CPU, disk, RAM snapshot
10. Schedule Tasks      – Weekly cleanup or monthly deep clean
11. Run Plugins         – Custom .ps1 plugins from plugins/ folder
12. Toggle Dry Run      – Switch dry-run on/off
13. Settings            – Mode, theme, logging, save config
```

## Configuration (`DeGhost.conf`)

```ini
# DeGhost Configuration
cleanup=true
debloat=true
mode=balanced        # gaming | workstation | balanced
dryrun=false
theme=green          # green | red | dark | minimal
logging=true
```

Changes can be saved from **Settings → Save config**.

## Plugin System

Place `.ps1` files in the `plugins/` folder. They appear automatically in the **Run Plugins** menu. See [`plugins/README.md`](plugins/README.md) for the development guide.

## Backup Location

All backups are stored in the `backup/` folder next to `DeGhost.bat`:

| File | Contents |
|---|---|
| `backup\hklm.reg` | HKLM registry export |
| `backup\hkcu.reg` | HKCU registry export |
| `backup\services.csv` | Service startup-type snapshot |

A Windows System Restore Point is also created before every optimization run.

## Log File

All actions are logged to `logs\DeGhost.log` (configurable via `logging=true/false`).
